import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
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
import 'package:worlds/shared/components/design.dart';
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
    final colors = AppColors.of(context);
    final description = world.description;
    final distance = world.distanceMeters;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: colors.canvas,
            leading: Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: Material(
                color: colors.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: const BackButton(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  WorldCover(
                    category: world.category,
                    coverPath: world.coverPath,
                    iconSize: 52,
                    seed: world.id.hashCode,
                  ),
                  // Keeps the back button legible on any photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0x00000000)],
                        stops: [0, 0.35],
                      ),
                    ),
                  ),
                  // The rounded top of the content sheet, drawn on the
                  // cover so it overlaps it.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: Radii.xl + 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.canvas,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(Radii.xl),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xl,
                Space.xs,
                Space.xl,
                Space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryLabel(world: world),
                  const SizedBox(height: Space.sm),
                  Text(world.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.primarySoft,
                        child: Text(
                          world.creatorName
                              .replaceFirst('@', '')
                              .characters
                              .first
                              .toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Text(
                        'by ${world.creatorName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      InfoChip(
                        icon: Icons.radar,
                        label: '${world.unlockRadiusMeters} m unlock radius',
                      ),
                      if (distance != null)
                        InfoChip(
                          icon: Icons.near_me_outlined,
                          label: '${formatDistance(distance)} away',
                          color: colors.accent,
                          background: colors.accent.withValues(alpha: 0.12),
                        ),
                      InfoChip(
                        icon: Icons.layers_outlined,
                        label:
                            '${world.blockCount} '
                            '${world.blockCount == 1 ? 'part' : 'parts'}',
                      ),
                    ],
                  ),
                  if (world.isCreator) ...[
                    const SizedBox(height: Space.xl),
                    _CreatorStatus(world: world),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: Space.xl),
                    Text('About', style: theme.textTheme.titleMedium),
                    const SizedBox(height: Space.sm),
                    Text(description, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: Space.xl),
                  _LockPanel(world: world),
                ],
              ),
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
        CategoryBadge(category: world.category, size: 28),
        const SizedBox(width: Space.sm),
        Text(
          world.category.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: world.category.color,
            fontWeight: FontWeight.w700,
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
    final colors = AppColors.of(context);
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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xs,
        ),
        leading: Icon(icon, color: colors.primary),
        title: Text(world.lifecycle.label),
        subtitle: Text(text),
      ),
    );
  }
}

/// Explains the unlock rule like a note in a field journal. Unlocking and
/// playing arrive in a later checkpoint, so this never offers a Start
/// action.
class _LockPanel extends StatelessWidget {
  const _LockPanel({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final distance = world.distanceMeters;
    final distanceText = distance == null
        ? 'Use "Find Worlds near me" on Explore to see how far away it is.'
        : "You're ${formatDistance(distance)} away.";

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Space.sm + 2),
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline, color: colors.primary),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locked', style: theme.textTheme.titleMedium),
                const SizedBox(height: Space.xs),
                Text(
                  'Unlocks within ${world.unlockRadiusMeters} m of its place '
                  'on the map. $distanceText',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'The content stays hidden until then. Unlocking and playing '
                  "Worlds isn't available in the app yet.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.muted,
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

    return BottomActionBar(
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
    );
  }
}
