import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/features/explore/application/explore_focus.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/application/world_editor_state.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/world_creation/presentation/world_preview_screen.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/components/design.dart';

/// What is still missing, a preview, the public-place promise, and the
/// publish or unpublish action.
class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({required this.args, super.key});

  final WorldEditorArgs args;

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> {
  bool _placeConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final provider = worldEditorProvider(widget.args);
    final state = ref.watch(provider);
    final draft = state.draft;
    if (draft == null) return const SizedBox.shrink();
    final controller = ref.read(provider.notifier);
    final theme = Theme.of(context);
    final problems = {
      ...state.publishProblems,
      ...state.serverProblems,
    }.toList();
    final live = draft.lifecycle == WorldLifecycle.published;

    final colors = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.sm,
        Space.lg,
        Space.xl,
      ),
      children: [
        if (live)
          const _LiveHero()
        else ...[
          const SectionHeader(
            title: 'Review and publish',
            subtitle: 'Check everything is ready, preview it, then share it.',
          ),
          const SizedBox(height: Space.lg),
          _StatusCard(lifecycle: draft.lifecycle),
        ],
        const SizedBox(height: Space.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.lg,
              Space.sm,
              Space.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  live ? 'Before you save changes' : 'Before you publish',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Space.sm),
                if (problems.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(
                      right: Space.sm,
                      bottom: Space.sm,
                    ),
                    padding: const EdgeInsets.all(Space.md),
                    decoration: BoxDecoration(
                      color: colors.successSoft,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: colors.success),
                        const SizedBox(width: Space.md),
                        const Expanded(
                          child: Text('Everything needed is in place.'),
                        ),
                      ],
                    ),
                  )
                else
                  for (final problem in problems)
                    _ProblemTile(
                      problem: problem,
                      draft: draft,
                      onFix: () => controller.goTo(_stepFor(problem.code)),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        OutlinedButton.icon(
          onPressed: draft.blocks.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => WorldPreviewScreen(args: widget.args),
                  ),
                ),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Preview as an explorer'),
        ),
        const SizedBox(height: 24),
        if (live)
          ..._liveActions(context, draft, state)
        else ...[
          CheckboxListTile(
            value: _placeConfirmed,
            onChanged: (value) =>
                setState(() => _placeConfirmed = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('This place is public and safe to reach'),
            subtitle: const Text(
              'Visitors will not need to enter private property, a school, a '
              'restricted area or anywhere dangerous. I will move or '
              'unpublish the World if that changes.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: problems.isEmpty && _placeConfirmed && !state.busy
                ? () => _publish(context)
                : null,
            icon: state.publishing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.public),
            label: Text(
              draft.lifecycle == WorldLifecycle.unpublished
                  ? 'Publish again'
                  : 'Publish',
            ),
          ),
          if (problems.isNotEmpty || !_placeConfirmed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                problems.isNotEmpty
                    ? 'Fix the items above to publish.'
                    : 'Confirm the place is public and safe to publish.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<Widget> _liveActions(
    BuildContext context,
    WorldDraft draft,
    WorldEditorState state,
  ) {
    final point = draft.location;
    return [
      if (point != null)
        FilledButton.icon(
          onPressed: () {
            ref
                .read(exploreFocusProvider.notifier)
                .focus(worldId: draft.id, point: point);
            context.go(AppRoutes.explore);
          },
          icon: const Icon(Icons.map_outlined),
          label: const Text('View on map'),
        ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: state.busy ? null : () => _unpublish(context),
        icon: const Icon(Icons.visibility_off_outlined),
        label: const Text('Unpublish'),
      ),
      const SizedBox(height: 8),
      Text(
        'Changes to a published World go live when you save them, and must '
        'keep it complete.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }

  Future<void> _publish(BuildContext context) async {
    final published = await ref
        .read(worldEditorProvider(widget.args).notifier)
        .publish();
    if (!context.mounted || !published) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Published. Your World is on the map.')),
    );
  }

  Future<void> _unpublish(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish this World?'),
        content: const Text(
          'It disappears from the map straight away. You can publish it '
          'again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    final done = await ref
        .read(worldEditorProvider(widget.args).notifier)
        .unpublish();
    if (!context.mounted || !done) return;
    setState(() => _placeConfirmed = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unpublished. Only you can see it now.')),
    );
  }

  static EditorStep _stepFor(PublishProblemCode code) => switch (code) {
    PublishProblemCode.titleInvalid ||
    PublishProblemCode.descriptionRequired => EditorStep.details,
    PublishProblemCode.locationRequired => EditorStep.location,
    _ => EditorStep.content,
  };
}

/// The moment a World goes live: clear, calm success, no confetti
/// (docs/UI_UX_SPECIFICATION.md, Motion).
class _LiveHero extends StatelessWidget {
  const _LiveHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.successSoft, colors.primarySoft],
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.public, size: 32, color: colors.success),
          ),
          const SizedBox(height: Space.lg),
          Text('Your World is live', style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(
            'Anyone exploring nearby can now find it on the map.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.lifecycle});

  final WorldLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, text) = switch (lifecycle) {
      WorldLifecycle.draft => (Icons.edit_note, 'Only you can see this draft.'),
      WorldLifecycle.unpublished => (
        Icons.visibility_off_outlined,
        'Unpublished. Only you can see it until you publish it again.',
      ),
      WorldLifecycle.published => (
        Icons.public,
        'Anyone exploring nearby can find it on the map.',
      ),
      WorldLifecycle.hidden => (
        Icons.flag_outlined,
        'Hidden by moderation. Other people cannot see it.',
      ),
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xs,
        ),
        leading: Icon(icon, color: scheme.primary),
        title: Text(lifecycle.label),
        subtitle: Text(text),
      ),
    );
  }
}

class _ProblemTile extends StatelessWidget {
  const _ProblemTile({
    required this.problem,
    required this.draft,
    required this.onFix,
  });

  final PublishProblem problem;
  final WorldDraft draft;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = problem.blockId == null
        ? -1
        : draft.blocks.indexWhere((b) => b.id == problem.blockId);
    final part = index >= 0 ? 'Part ${index + 1}: ' : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
      title: Text('$part${problemMessage(problem.code)}'),
      trailing: TextButton(onPressed: onFix, child: const Text('Fix')),
    );
  }
}

/// Plain-language text for each publish problem.
String problemMessage(PublishProblemCode code) => switch (code) {
  PublishProblemCode.titleInvalid => 'Add a title of 3 to 80 characters.',
  PublishProblemCode.descriptionRequired => 'Add a description.',
  PublishProblemCode.locationRequired => 'Place the World on the map.',
  PublishProblemCode.contentRequired => 'Add at least one part of content.',
  PublishProblemCode.questionRequired =>
    'A puzzle needs at least one question.',
  PublishProblemCode.artworkRequired => 'An art World needs an artwork.',
  PublishProblemCode.textRequired => 'A story needs at least one text part.',
  PublishProblemCode.blockNotAllowed =>
    "This part can't be used in this type of World. Remove it.",
  PublishProblemCode.blockIncomplete => 'Fill in the empty fields.',
  PublishProblemCode.answerRequired => 'Set the accepted answer.',
  PublishProblemCode.choiceDestinationInvalid =>
    'Each option must lead to a later part.',
  PublishProblemCode.unknown => 'Something needs fixing before publishing.',
};
