import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/explore/application/explore_focus.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/features/worlds/presentation/world_cover.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// Everything a visitor may know about a World before playing it.
///
/// Content blocks are not shown here: they stay hidden until the World is
/// unlocked. [from] is the user's own position, when they have shared one,
/// so the server can say how far away the World is.
class WorldDetailsScreen extends ConsumerWidget {
  const WorldDetailsScreen({required this.worldId, this.from, super.key});

  final String worldId;
  final GeoPoint? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (worldId: worldId, from: from);
    final details = ref.watch(worldDetailsProvider(request));

    return switch (details) {
      AsyncData(:final value) => _DetailsView(world: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: error is NotFoundFailure
            ? const EmptyView(
                icon: Icons.travel_explore,
                title: "This World isn't available",
                message:
                    'It may have been unpublished or removed by its creator.',
              )
            : ErrorView(
                message: messageForError(error),
                onRetry: () => ref.invalidate(worldDetailsProvider(request)),
              ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const LoadingView(label: 'Loading World'),
      ),
    };
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = world.description;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: WorldCover(
                category: world.category,
                coverPath: world.coverPath,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: [
                _CategoryLabel(world: world),
                const SizedBox(height: 8),
                Text(world.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'by ${world.creatorName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (world.isCreator) ...[
                  const SizedBox(height: 16),
                  _CreatorStatus(world: world),
                ],
                const SizedBox(height: 16),
                _LockPanel(world: world),
                if (description != null) ...[
                  const SizedBox(height: 24),
                  Text('About', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: 24),
                Text("What's inside", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${world.blockCount} '
                  '${world.blockCount == 1 ? 'part' : 'parts'}. '
                  'The content stays hidden until the World is unlocked.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      // Actions stay in reach however long the description is.
      bottomNavigationBar: _Actions(world: world),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(world.category.icon, size: 18, color: world.category.color),
        const SizedBox(width: 6),
        Text(
          world.category.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: world.category.color,
          ),
        ),
      ],
    );
  }
}

/// Tells the creator where their World stands.
class _CreatorStatus extends StatelessWidget {
  const _CreatorStatus({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, text) = switch (world.lifecycle) {
      WorldLifecycle.draft => (
        Icons.edit_note,
        'Draft. Only you can see this World.',
      ),
      WorldLifecycle.unpublished => (
        Icons.visibility_off_outlined,
        'Unpublished. Only you can see this World until you publish it again.',
      ),
      WorldLifecycle.hidden => (
        Icons.flag_outlined,
        'Hidden by moderation. Other people cannot see this World.',
      ),
      WorldLifecycle.published => (
        Icons.public,
        'Published. Anyone can find this World on the map.',
      ),
    };
    return Card.filled(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(world.lifecycle.label),
        subtitle: Text(text),
      ),
    );
  }
}

/// Explains the unlock rule. Unlocking and playing arrive in a later
/// checkpoint, so this never offers a Start action.
class _LockPanel extends StatelessWidget {
  const _LockPanel({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = world.distanceMeters;
    final distanceText = distance == null
        ? 'Use "Find Worlds near me" on Explore to see how far away it is.'
        : "You're ${formatDistance(distance)} away.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locked', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Unlocks within ${world.unlockRadiusMeters} m of its place '
                  'on the map. $distanceText',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  "Unlocking and playing Worlds isn't available in the app "
                  'yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = world.point;
    final onMap = point != null && world.lifecycle == WorldLifecycle.published;
    final canEdit = world.isCreator && world.lifecycle != WorldLifecycle.hidden;
    if (!onMap && !canEdit) return const SizedBox.shrink();

    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (canEdit)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit World'),
                    onPressed: () => context.go(AppRoutes.editWorld(world.id)),
                  ),
                ),
              if (canEdit && onMap) const SizedBox(width: 12),
              if (onMap)
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Show on map'),
                    onPressed: () {
                      ref
                          .read(exploreFocusProvider.notifier)
                          .focus(worldId: world.id, point: point);
                      context.go(AppRoutes.explore);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
