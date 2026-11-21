import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/utils/date_format.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/presentation/sign_in_prompt.dart';
import 'package:worlds/features/world_creation/application/authoring_providers.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/features/worlds/presentation/status_pill.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:worlds/shared/models/world_category.dart';
import 'package:worlds/shared/components/motion.dart';

/// The Create tab: the creator's own Worlds and a way to start a new one.
class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;

    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create')),
        body: const SignInPrompt(
          icon: Icons.add_circle_outline,
          title: 'Create a World',
          message:
              'Sign in to place a story, puzzle, artwork or '
              'experience on the map.',
          returnTo: AppRoutes.create,
        ),
      );
    }

    // The empty state has its own start button; the floating one appears
    // once there is a list.
    final hasWorlds = ref.watch(
      myWorldsProvider.select((worlds) => worlds.value?.isNotEmpty ?? false),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      floatingActionButton: !hasWorlds
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _startNewWorld(context),
              icon: const Icon(Icons.add),
              label: const Text('New World'),
            ),
      body: const _MyWorlds(),
    );
  }
}

void _startNewWorld(BuildContext context) =>
    context.go(AppRoutes.newWorld(newUuid()));

class _MyWorlds extends ConsumerWidget {
  const _MyWorlds();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worlds = ref.watch(myWorldsProvider);
    // Loading fades into the list, or into what there is instead of one.
    return StateSwitcher(
      child: switch (worlds) {
        AsyncData(:final value) when value.isEmpty => const _FirstWorld(
          key: ValueKey('empty'),
        ),
        AsyncData(:final value) => RefreshIndicator(
          key: const ValueKey('list'),
          onRefresh: () => ref.refresh(myWorldsProvider.future),
          child: _WorldGroups(worlds: value),
        ),
        AsyncError(:final error) => ErrorView(
          key: const ValueKey('error'),
          message: messageForError(error),
          onRetry: () => ref.invalidate(myWorldsProvider),
        ),
        _ => const LoadingView(
          key: ValueKey('loading'),
          label: 'Loading your Worlds',
        ),
      },
    );
  }
}

class _FirstWorld extends StatelessWidget {
  const _FirstWorld({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, 112),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.xl),
          child: SizedBox(
            height: 168,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const AtlasPanel(
                  category: WorldCategory.experience,
                  iconSize: 0,
                  seed: 7,
                ),
                Center(
                  child: Wrap(
                    spacing: Space.md,
                    children: [
                      for (final category in WorldCategory.values)
                        Container(
                          padding: const EdgeInsets.all(Space.sm),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(Radii.md),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CategoryBadge(category: category, size: 44),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        Text('Create your first World', style: theme.textTheme.headlineMedium),
        const SizedBox(height: Space.sm),
        Text(
          'Leave a story, a puzzle or a piece of art at a real place. People '
          'exploring nearby find it on the map.',
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.muted),
        ),
        const SizedBox(height: Space.xl),
        for (final (index, (title, text)) in const [
          ('Pick a public place', 'A park, a square, a corner with a story.'),
          ('Make something there', 'Write, add photos, choices or a riddle.'),
          ('Publish', 'Explorers unlock it when they get close.'),
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primarySoft,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.sm),
        FilledButton.icon(
          onPressed: () => _startNewWorld(context),
          icon: const Icon(Icons.add),
          label: const Text('Start a World'),
        ),
      ],
    );
  }
}

class _WorldGroups extends StatelessWidget {
  const _WorldGroups({required this.worlds});

  final List<WorldSummary> worlds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final groups = <(String, List<WorldSummary>)>[
      (
        'Drafts',
        [
          for (final w in worlds)
            if (w.lifecycle == WorldLifecycle.draft ||
                w.lifecycle == WorldLifecycle.unpublished)
              w,
        ],
      ),
      (
        'Published',
        [
          for (final w in worlds)
            if (w.lifecycle == WorldLifecycle.published) w,
        ],
      ),
      (
        'Hidden by moderation',
        [
          for (final w in worlds)
            if (w.lifecycle == WorldLifecycle.hidden) w,
        ],
      ),
    ];
    final published = groups[1].$2.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.lg, 112),
      children: [
        Text(
          published == 0
              ? '${worlds.length} in progress'
              : '$published live on the map · ${worlds.length} in all',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
        ),
        for (final (title, items) in groups)
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xs,
                Space.xl,
                Space.xs,
                Space.sm,
              ),
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            for (final world in items)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _WorldTile(world: world),
              ),
          ],
      ],
    );
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({required this.world});

  final WorldSummary world;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.editWorld(world.id)),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              CategoryBadge(category: world.category, size: 52),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${world.category.label} · edited '
                      '${formatDay(world.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              StatusPill(lifecycle: world.lifecycle),
            ],
          ),
        ),
      ),
    );
  }
}
