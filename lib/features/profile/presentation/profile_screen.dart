import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/widgets/error_view.dart';
import 'package:worlds/core/widgets/loading_view.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/presentation/sign_in_prompt.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';
import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/presentation/profile_worlds.dart';
import 'package:worlds/shared/components/motion.dart';

/// The Profile tab: a sign-in prompt when signed out, otherwise the user's
/// own profile.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: signedIn
          ? const _OwnProfile()
          : const SignInPrompt(
              icon: Icons.person_outline,
              title: 'Your profile',
              message: 'Sign in to see your profile and the Worlds you make.',
              returnTo: AppRoutes.profile,
            ),
    );
  }
}

class _OwnProfile extends ConsumerWidget {
  const _OwnProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(ownProfileProvider);

    // Loading fades into the profile, or into what went wrong.
    return StateSwitcher(
      child: switch (profile) {
        AsyncData(value: final profile?) => _ProfileDetails(
          key: const ValueKey('profile'),
          profile: profile,
        ),
        AsyncError(:final error) => ErrorView(
          key: const ValueKey('error'),
          message: messageForError(error),
          onRetry: () => ref.invalidate(ownProfileProvider),
        ),
        _ => const LoadingView(
          key: ValueKey('loading'),
          label: 'Loading profile',
        ),
      },
    );
  }
}

class _ProfileDetails extends ConsumerWidget {
  const _ProfileDetails({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final signOut = ref.watch(signOutControllerProvider);
    final requested = ref.watch(requestedUsernameProvider);

    if (requested != null && requested == profile.username) {
      // The requested name was granted; nothing to tell the user.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(requestedUsernameProvider.notifier).clear(),
      );
    }

    final displayName = profile.displayName;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (requested != null && requested != profile.username) ...[
          _UsernameNotice(
            requested: requested,
            assigned: profile.username,
            onDismiss: () =>
                ref.read(requestedUsernameProvider.notifier).clear(),
          ),
          const SizedBox(height: 24),
        ],
        Center(
          child: CircleAvatar(
            radius: 40,
            child: Text(
              profile.username.characters.first.toUpperCase(),
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName ?? '@${profile.username}',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (displayName != null)
          Text(
            '@${profile.username}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        if (profile.bio case final bio?) ...[
          const SizedBox(height: 16),
          Text(bio, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        _OwnActivity(username: profile.username),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: () => context.go(AppRoutes.editProfile),
          child: const Text('Edit profile'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: signOut.isLoading
              ? null
              : () => ref.read(signOutControllerProvider.notifier).signOut(),
          child: const Text('Sign out'),
        ),
        if (signOut.hasError) ...[
          const SizedBox(height: 8),
          Text(
            messageForError(signOut.error),
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// What the signed-in user has made and done, counted by the server: no
/// number is shown that a query does not back.
class _OwnActivity extends ConsumerWidget {
  const _OwnActivity({required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(profilePageProvider(username));

    return switch (state) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Each count gets a third of the row, whatever the text size.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProfileStat(
                  value: value.page.publishedCount,
                  label: 'Published',
                ),
              ),
              Expanded(
                child: ProfileStat(
                  value: value.page.discoveredCount ?? 0,
                  label: 'Discovered',
                ),
              ),
              Expanded(
                child: ProfileStat(
                  value: value.page.completedCount ?? 0,
                  label: 'Completed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Your published Worlds', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ProfileWorldsList(username: username),
          if ((value.page.draftCount ?? 0) > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_note),
              title: Text(
                value.page.draftCount == 1
                    ? '1 World not published'
                    : '${value.page.draftCount} Worlds not published',
              ),
              subtitle: const Text(
                'Drafts and unpublished Worlds are in Create.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.create),
            ),
        ],
      ),
      AsyncError(:final error) => Column(
        children: [
          Text(
            "Couldn't load your Worlds. ${messageForError(error)}",
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => ref.invalidate(profilePageProvider(username)),
            child: const Text('Try again'),
          ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    };
  }
}

class _UsernameNotice extends StatelessWidget {
  const _UsernameNotice({
    required this.requested,
    required this.assigned,
    required this.onDismiss,
  });

  final String requested;
  final String assigned;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"$requested" was taken, so your username is @$assigned. '
              'You can change it with Edit profile.',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onDismiss, child: const Text('OK')),
            ),
          ],
        ),
      ),
    );
  }
}
