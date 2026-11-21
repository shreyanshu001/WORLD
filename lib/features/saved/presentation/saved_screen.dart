import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/presentation/sign_in_prompt.dart';
import 'package:worlds/features/saved/application/saved_providers.dart';
import 'package:worlds/features/saved/domain/saved_world.dart';
import 'package:worlds/features/worlds/presentation/world_tile.dart';
import 'package:worlds/shared/components/motion.dart';

/// The Saved tab: the Worlds the signed-in user bookmarked. The list is
/// private to the account.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: signedIn
          ? const _SavedList()
          : const SignInPrompt(
              icon: Icons.bookmark_outline,
              title: 'Save Worlds for later',
              message: 'Sign in to keep a list of Worlds you want to visit.',
              returnTo: AppRoutes.saved,
            ),
    );
  }
}

class _SavedList extends ConsumerWidget {
  const _SavedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loading fades into the list, or into what there is instead of one.
    return StateSwitcher(child: _stage(context, ref));
  }

  Widget _stage(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedListControllerProvider);
    final controller = ref.read(savedListControllerProvider.notifier);

    if (state.items.isEmpty) {
      if (state.loading) {
        return const LoadingView(
          key: ValueKey('loading'),
          label: 'Loading saved Worlds',
        );
      }
      if (state.failure case final failure?) {
        return ErrorView(
          key: const ValueKey('error'),
          message: failure.userMessage,
          onRetry: controller.load,
        );
      }
      return _NothingSaved(
        key: const ValueKey('empty'),
        unavailable: state.unavailable,
      );
    }

    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.xs,
          Space.lg,
          Space.xl,
        ),
        children: [
          if (state.removeFailure case final refused?)
            _Notice(
              text:
                  "Couldn't remove ${refused.title}. "
                  '${refused.failure.userMessage}',
              onDismiss: controller.dismissRemoveFailure,
            ),
          if (state.failure case final failure?)
            _Notice(
              text: "Couldn't refresh. ${failure.userMessage}",
              actionLabel: 'Try again',
              onAction: controller.load,
            ),
          for (final world in state.items)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: _SavedTile(world: world),
            ),
          if (state.unavailable > 0) _UnavailableNote(count: state.unavailable),
          if (state.hasMore || state.loadingMore || state.moreFailure != null)
            _MoreRow(state: state),
        ],
      ),
    );
  }
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({required this.world});

  final SavedWorld world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = world.distanceMeters;
    return WorldTile(
      worldId: world.id,
      title: world.title,
      category: world.category,
      coverPath: world.coverPath,
      subtitle: [
        world.category.label,
        'by ${world.creatorName}',
        if (distance != null) '${formatDistance(distance)} away',
      ].join(' · '),
      onTap: () => context.push(AppRoutes.worldPage(world.id)),
      trailing: IconButton(
        tooltip: 'Remove ${world.title} from saved',
        icon: const Icon(Icons.bookmark_remove_outlined),
        onPressed: () =>
            ref.read(savedListControllerProvider.notifier).remove(world),
      ),
    );
  }
}

/// The empty state: what Saved is for, and the way back to the map.
class _NothingSaved extends StatelessWidget {
  const _NothingSaved({required this.unavailable, super.key});

  final int unavailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.bookmark_outline, size: 48, color: colors.muted),
              const SizedBox(height: Space.lg),
              Text(
                'Nothing saved yet',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              Text(
                'Tap the bookmark on a World to keep it here for later. '
                'Only you can see this list.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                ),
                textAlign: TextAlign.center,
              ),
              if (unavailable > 0) ...[
                const SizedBox(height: Space.lg),
                _UnavailableNote(count: unavailable),
              ],
              const SizedBox(height: Space.xl),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.explore),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Explore the map'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableNote extends StatelessWidget {
  const _UnavailableNote({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Text(
        count == 1
            ? "1 saved World isn't available at the moment. It comes back "
                  'here if it is published again.'
            : "$count saved Worlds aren't available at the moment. They come "
                  'back here if they are published again.',
        style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A short message above the list, with one way to act on it.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.text,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.md),
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.xs,
          Space.sm,
        ),
        decoration: BoxDecoration(
          color: colors.dangerSoft,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: TextStyle(color: colors.danger)),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

/// The end of the list while more saved Worlds wait on the server.
class _MoreRow extends ConsumerWidget {
  const _MoreRow({required this.state});

  final SavedListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final controller = ref.read(savedListControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Column(
        children: [
          if (state.moreFailure case final failure?)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(
                "Couldn't load more. ${failure.userMessage}",
                style: TextStyle(color: colors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          OutlinedButton(
            onPressed: state.loadingMore ? null : controller.loadMore,
            child: state.loadingMore
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Show more'),
          ),
        ],
      ),
    );
  }
}
