import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/utils/date_format.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/features/worlds/presentation/world_tile.dart';

/// The published Worlds on a profile page, with "Show more" while the
/// server has further pages. Shown on creator pages and on the own profile.
class ProfileWorldsList extends ConsumerWidget {
  const ProfileWorldsList({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profilePageProvider(username)).value;
    if (state == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    if (state.worlds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Text(
          state.page.isOwn
              ? "You haven't published a World yet."
              : 'No published Worlds yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final world in state.worlds)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _ProfileWorldTile(world: world),
          ),
        if (state.moreFailure case final failure?)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Text(
              "Couldn't load more. ${failure.userMessage}",
              style: TextStyle(color: colors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        if (state.hasMore)
          OutlinedButton(
            onPressed: state.loadingMore
                ? null
                : ref.read(profilePageProvider(username).notifier).loadMore,
            child: state.loadingMore
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Show more'),
          ),
      ],
    );
  }
}

class _ProfileWorldTile extends StatelessWidget {
  const _ProfileWorldTile({required this.world});

  final ProfileWorld world;

  @override
  Widget build(BuildContext context) {
    final published = world.publishedAt;
    return WorldTile(
      worldId: world.id,
      title: world.title,
      category: world.category,
      coverPath: world.coverPath,
      subtitle: [
        world.category.label,
        if (published != null) 'published ${formatDay(published)}',
      ].join(' · '),
      onTap: () => context.push(AppRoutes.worldPage(world.id)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

/// A number with its label, for the few real counts a profile shows.
class ProfileStat extends StatelessWidget {
  const ProfileStat({required this.value, required this.label, super.key});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Column(
        key: ValueKey('stat-$label'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: theme.textTheme.headlineSmall),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
