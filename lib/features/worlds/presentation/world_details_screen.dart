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
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/explore/application/explore_focus.dart';
import 'package:worlds/features/saved/application/saved_providers.dart';
import 'package:worlds/features/world_player/presentation/play_panel.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/features/worlds/presentation/world_cover.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/components/motion.dart';

/// Everything a visitor may know about a World before playing it.
///
/// Content blocks are not shown here: they stay hidden until the World is
/// unlocked on site. [from] is the user's own position, when they have shared one,
/// so the server can say how far away the World is.
class WorldDetailsScreen extends ConsumerWidget {
  const WorldDetailsScreen({required this.worldId, this.from, super.key});

  final String worldId;
  final GeoPoint? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (worldId: worldId, from: from);
    final details = ref.watch(worldDetailsProvider(request));

    // Loading fades into the World, or into what went wrong.
    return StateSwitcher(
      child: switch (details) {
        AsyncData(:final value) => _DetailsView(
          key: const ValueKey('details'),
          world: value,
        ),
        AsyncError(:final error) => Scaffold(
          key: const ValueKey('unavailable'),
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
          key: const ValueKey('loading'),
          appBar: AppBar(),
          body: const LoadingView(label: 'Loading World'),
        ),
      },
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.world, super.key});

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
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.explore),
                ),
              ),
            ),
            actions: [
              if (world.lifecycle == WorldLifecycle.published &&
                  !world.isCreator)
                Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Material(
                    color: colors.surface.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: _MoreMenu(world: world),
                  ),
                ),
            ],
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
                  const SizedBox(height: Space.xs),
                  // Opens the public page of the creator.
                  Semantics(
                    button: true,
                    label: 'By ${world.creatorName}. View their Worlds',
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      onTap: () => context.push(
                        AppRoutes.creatorPage(world.creatorUsername),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Flexible(
                              child: Text(
                                'by ${world.creatorName}',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: colors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
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
                  PlayPanel(world: world),
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

class _Actions extends ConsumerWidget {
  const _Actions({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = world.point;
    final published = world.lifecycle == WorldLifecycle.published;
    final onMap = point != null && published;
    final canEdit = world.isCreator && world.lifecycle != WorldLifecycle.hidden;
    if (!onMap && !canEdit) return const SizedBox.shrink();

    return BottomActionBar(
      child: Row(
        children: [
          if (onMap) ...[
            IconButton.outlined(
              tooltip: 'Show on map',
              iconSize: 24,
              padding: const EdgeInsets.all(Space.md),
              icon: const Icon(Icons.map_outlined),
              onPressed: () {
                ref
                    .read(exploreFocusProvider.notifier)
                    .focus(worldId: world.id, point: point);
                context.go(AppRoutes.explore);
              },
            ),
            const SizedBox(width: Space.sm),
          ],
          if (published) ...[
            _SaveButton(world: world),
            const SizedBox(width: Space.sm),
          ],
          if (canEdit && published) ...[
            IconButton.outlined(
              tooltip: 'Edit World',
              iconSize: 24,
              padding: const EdgeInsets.all(Space.md),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go(AppRoutes.editWorld(world.id)),
            ),
            const SizedBox(width: Space.sm),
          ],
          Expanded(
            child: published
                ? PlayActionButton(world: world)
                : FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit World'),
                    onPressed: () => context.go(AppRoutes.editWorld(world.id)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Saves the World for later, or removes it again. The bookmark changes at
/// once and goes back if the server refuses. Signed out, it leads to
/// sign-in and back to this World.
class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;
    final saved =
        signedIn &&
        (ref.watch(savedFlagsProvider)[world.id] ?? world.isSaved ?? false);

    Future<void> toggle() async {
      if (!signedIn) {
        await context.push(
          AppRoutes.signInFrom(AppRoutes.worldDetails(world.id)),
        );
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      final failure = await ref
          .read(savedFlagsProvider.notifier)
          .setSaved(world.id, saved: !saved, previous: saved);
      if (failure == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? "Couldn't remove it from saved. ${failure.userMessage}"
                  : "Couldn't save this World. ${failure.userMessage}",
            ),
          ),
        );
    }

    // Saved shows as a soft filled button, not saved as an outline: two
    // shapes as well as two icons, so the state does not rest on colour.
    // One fades into the other.
    return StateSwitcher(
      fill: false,
      alignment: Alignment.center,
      child: saved
          ? IconButton.filledTonal(
              key: const ValueKey('saved'),
              tooltip: 'Remove from saved',
              iconSize: 24,
              padding: const EdgeInsets.all(Space.md),
              icon: const Icon(Icons.bookmark),
              onPressed: toggle,
            )
          : IconButton.outlined(
              key: const ValueKey('not-saved'),
              tooltip: 'Save for later',
              iconSize: 24,
              padding: const EdgeInsets.all(Space.md),
              icon: const Icon(Icons.bookmark_outline),
              onPressed: toggle,
            ),
    );
  }
}

/// The lesser actions on a published World made by someone else.
class _MoreMenu extends ConsumerWidget {
  const _MoreMenu({required this.world});

  final WorldDetails world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<void>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: () {
            final signedIn = ref.read(currentUserProvider) != null;
            context.push(
              signedIn
                  ? AppRoutes.reportWorld(world.id)
                  : AppRoutes.signInFrom(AppRoutes.worldDetails(world.id)),
              extra: signedIn ? world.title : null,
            );
          },
          child: const Row(
            children: [
              Icon(Icons.flag_outlined),
              SizedBox(width: Space.md),
              Flexible(child: Text('Report this World')),
            ],
          ),
        ),
      ],
    );
  }
}
