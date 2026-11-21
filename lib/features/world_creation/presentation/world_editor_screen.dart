import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/leave_guard.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/application/world_editor_state.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/world_creation/presentation/steps/category_step.dart';
import 'package:worlds/features/world_creation/presentation/steps/content_step.dart';
import 'package:worlds/features/world_creation/presentation/steps/details_step.dart';
import 'package:worlds/features/world_creation/presentation/steps/place_step.dart';
import 'package:worlds/features/world_creation/presentation/steps/review_step.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';

/// The creator: choose a type, add details, place the World, compose its
/// content, then preview and publish. Every step saves to the server before
/// moving on, so nothing is kept only on the device.
class WorldEditorScreen extends ConsumerWidget {
  const WorldEditorScreen({
    required this.worldId,
    required this.isNew,
    super.key,
  });

  final String worldId;
  final bool isNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (worldId: worldId, isNew: isNew);
    final provider = worldEditorProvider(args);
    final loading = ref.watch(provider.select((s) => s.loading));
    final loadError = ref.watch(provider.select((s) => s.loadError));
    final hidden = ref.watch(
      provider.select((s) => s.draft?.status == WorldStatus.hidden),
    );

    ref.listen(provider.select((s) => s.deleted), (_, deleted) {
      if (!deleted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('World deleted.')));
      context.go(AppRoutes.create);
    });
    ref.listen(provider.select((s) => s.uploadError), (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    });

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit World')),
        body: const LoadingView(label: 'Loading your World'),
      );
    }
    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit World')),
        body: loadError is NotFoundFailure
            ? const EmptyView(
                icon: Icons.search_off,
                title: "This World can't be edited",
                message: 'It may have been deleted.',
              )
            : ErrorView(
                message: loadError.userMessage,
                onRetry: ref.read(provider.notifier).retryLoad,
              ),
      );
    }
    if (hidden) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit World')),
        body: const EmptyView(
          icon: Icons.flag_outlined,
          title: 'Hidden by moderation',
          message:
              'This World was hidden after a review, so it cannot be edited '
              'or published. Other people cannot see it.',
        ),
      );
    }

    return _UnsavedChangesGuard(
      args: args,
      child: Scaffold(
        appBar: _EditorAppBar(args: args),
        body: Column(
          children: [
            _StepBar(args: args),
            _SaveErrorBanner(args: args),
            Expanded(child: _StepBody(args: args)),
          ],
        ),
        bottomNavigationBar: _StepNavigation(args: args),
      ),
    );
  }
}

/// Asks before leaving with changes the server has not confirmed.
/// Asks before leaving with changes the server has not confirmed: on back
/// navigation, and, through [leaveGuardProvider], when the Create tab is
/// tapped again to return to its first screen.
class _UnsavedChangesGuard extends ConsumerStatefulWidget {
  const _UnsavedChangesGuard({required this.args, required this.child});

  final WorldEditorArgs args;
  final Widget child;

  @override
  ConsumerState<_UnsavedChangesGuard> createState() =>
      _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends ConsumerState<_UnsavedChangesGuard> {
  late final LeaveGuard _guard;
  late final LeaveCheck _check = _confirmLeave;

  @override
  void initState() {
    super.initState();
    _guard = ref.read(leaveGuardProvider.notifier);
    ref.listenManual(
      worldEditorProvider(widget.args).select((s) => s.hasUnsavedChanges),
      (_, unsaved) {
        // Providers cannot change while widgets build.
        scheduleMicrotask(() {
          if (!mounted) return;
          unsaved ? _guard.register(_check) : _guard.unregister(_check);
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    final guard = _guard;
    final check = _check;
    scheduleMicrotask(() => guard.unregister(check));
    super.dispose();
  }

  /// Resolves to true when the user may leave: after a confirmed save, or
  /// after choosing to discard.
  Future<bool> _confirmLeave() async {
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save your changes?'),
        content: const Text(
          'Some changes have not been saved yet. Unsaved changes are lost if '
          'you leave.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.stay),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    return switch (choice) {
      _LeaveChoice.save =>
        await ref.read(worldEditorProvider(widget.args).notifier).save(),
      _LeaveChoice.discard => true,
      _LeaveChoice.stay || null => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final unsaved = ref.watch(
      worldEditorProvider(widget.args).select((s) => s.hasUnsavedChanges),
    );
    return PopScope(
      canPop: !unsaved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) {
          context.go(AppRoutes.create);
        }
      },
      child: widget.child,
    );
  }
}

enum _LeaveChoice { stay, discard, save }

class _EditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _EditorAppBar({required this.args});

  final WorldEditorArgs args;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final state = ref.watch(provider);
    final theme = Theme.of(context);
    final draft = state.draft;

    final saveStatus = state.saving
        ? 'Saving…'
        : state.hasUnsavedChanges
        ? 'Unsaved changes'
        : state.existsOnServer
        ? 'Saved'
        : null;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state.existsOnServer ? 'Edit World' : 'New World'),
          if (draft != null)
            Text(
              [draft.lifecycle.label, ?saveStatus].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        if (draft != null)
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (_) => _confirmDelete(context, ref),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                enabled: !state.busy,
                child: const Text('Delete World'),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this World?'),
        content: const Text(
          'It disappears from the map and from your Worlds. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(worldEditorProvider(args).notifier).delete();
    }
  }
}

class _StepBar extends ConsumerWidget {
  const _StepBar({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final step = ref.watch(provider.select((s) => s.step));
    final hasDraft = ref.watch(provider.select((s) => s.draft != null));

    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    // A segmented progress bar: done and current steps are filled. Each
    // segment is a button, so steps can be revisited in any order.
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
      child: Row(
        children: [
          for (final (index, item) in EditorStep.values.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: item == step,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  onTap: hasDraft || item == EditorStep.category
                      ? () => ref.read(provider.notifier).goTo(item)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: Space.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 5,
                          decoration: BoxDecoration(
                            color: index <= step.index
                                ? colors.primary
                                : colors.outline,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${index + 1}. ${item.label}',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: item == step ? colors.ink : colors.muted,
                            fontWeight: item == step
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SaveErrorBanner extends ConsumerWidget {
  const _SaveErrorBanner({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final error = ref.watch(provider.select((s) => s.saveError));
    if (error == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Not saved. ${error.userMessage}',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: () => ref.read(provider.notifier).save(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(worldEditorProvider(args).select((s) => s.step));
    return switch (step) {
      EditorStep.category => CategoryStep(args: args),
      EditorStep.details => DetailsStep(args: args),
      EditorStep.location => PlaceStep(args: args),
      EditorStep.content => ContentStep(args: args),
      EditorStep.review => ReviewStep(args: args),
    };
  }
}

/// Back and Next. Next saves first and moves on only if the server
/// confirmed the save.
class _StepNavigation extends ConsumerWidget {
  const _StepNavigation({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final step = ref.watch(provider.select((s) => s.step));
    final saving = ref.watch(provider.select((s) => s.saving));
    final busy = ref.watch(provider.select((s) => s.busy));
    if (step == EditorStep.category) return const SizedBox.shrink();

    final controller = ref.read(provider.notifier);
    final previous = EditorStep.values[step.index - 1];
    final next = step == EditorStep.review
        ? null
        : EditorStep.values[step.index + 1];

    Future<void> saveAndContinue() async {
      final title = ref.read(provider).draft?.title ?? '';
      final titleError = WorldRules.titleError(title);
      if (titleError != null) {
        controller.goTo(EditorStep.details);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(titleError)));
        return;
      }
      if (await controller.save() && next != null) controller.goTo(next);
    }

    return BottomActionBar(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : () => controller.goTo(previous),
              child: const Text('Back'),
            ),
          ),
          if (next != null) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: busy ? null : saveAndContinue,
                child: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Saving',
                        ),
                      )
                    : const Text(
                        'Save and continue',
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
