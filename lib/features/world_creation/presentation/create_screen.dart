import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
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
import 'package:worlds/shared/components/category_style.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      floatingActionButton: FloatingActionButton.extended(
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
    return switch (worlds) {
      AsyncData(:final value) when value.isEmpty => const _FirstWorld(),
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(myWorldsProvider.future),
        child: _WorldGroups(worlds: value),
      ),
      AsyncError(:final error) => ErrorView(
        message: messageForError(error),
        onRetry: () => ref.invalidate(myWorldsProvider),
      ),
      _ => const LoadingView(label: 'Loading your Worlds'),
    };
  }
}

class _FirstWorld extends StatelessWidget {
  const _FirstWorld();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first World',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a public place, then add a story, a puzzle, an artwork or '
              'a mix of all three. People nearby can find it on the map.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _startNewWorld(context),
              icon: const Icon(Icons.add),
              label: const Text('Start a World'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldGroups extends StatelessWidget {
  const _WorldGroups({required this.worlds});

  final List<WorldSummary> worlds;

  @override
  Widget build(BuildContext context) {
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final (title, items) in groups)
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final world in items) _WorldTile(world: world),
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
    final hidden = world.lifecycle == WorldLifecycle.hidden;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: world.category.color.withValues(alpha: 0.14),
        child: Icon(world.category.icon, color: world.category.color),
      ),
      title: Text(world.title),
      subtitle: Text(
        '${world.category.label} · ${world.lifecycle.label} · '
        'edited ${formatDay(world.updatedAt)}',
      ),
      trailing: hidden
          ? const Icon(Icons.flag_outlined)
          : const Icon(Icons.chevron_right),
      onTap: () => context.go(AppRoutes.editWorld(world.id)),
    );
  }
}
