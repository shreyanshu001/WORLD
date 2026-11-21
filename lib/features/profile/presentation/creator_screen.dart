import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';
import 'package:worlds/features/profile/presentation/profile_worlds.dart';

/// The public page of a creator: who they are and the Worlds they have
/// published. Nothing here is private; activity counts stay with their
/// owner.
class CreatorScreen extends ConsumerWidget {
  const CreatorScreen({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profilePageProvider(username));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.explore),
        ),
        title: Text('@$username'),
      ),
      body: switch (state) {
        AsyncData(:final value) => _CreatorPage(
          username: username,
          state: value,
        ),
        AsyncError(:final error) =>
          error is NotFoundFailure
              ? const EmptyView(
                  icon: Icons.person_off_outlined,
                  title: 'No one has this username',
                  message: 'They may have changed it.',
                )
              : ErrorView(
                  message: messageForError(error),
                  onRetry: () => ref.invalidate(profilePageProvider(username)),
                ),
        _ => const LoadingView(label: 'Loading profile'),
      },
    );
  }
}

class _CreatorPage extends StatelessWidget {
  const _CreatorPage({required this.username, required this.state});

  final String username;
  final ProfilePageState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final page = state.page;
    final count = page.publishedCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.xl,
      ),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: colors.primarySoft,
            child: Text(
              page.username.characters.first.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          page.name,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (page.displayName != null)
          Text(
            '@${page.username}',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
        if (page.bio case final bio?) ...[
          const SizedBox(height: Space.md),
          Text(
            bio,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: Space.xl),
        Text(
          count == 1 ? '1 published World' : '$count published Worlds',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: Space.sm),
        ProfileWorldsList(username: username),
      ],
    );
  }
}
