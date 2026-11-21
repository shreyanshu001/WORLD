import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/profile/data/supabase_profile_repository.dart';
import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/features/profile/domain/profile_repository.dart';
import 'package:worlds/features/profile/domain/profile_rules.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

/// The signed-in user's profile, or null when signed out.
///
/// Keyed on the user id, so it reloads when a different user signs in.
final ownProfileProvider = FutureProvider.autoDispose<Profile?>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

/// A profile page with the published Worlds loaded so far.
@immutable
class ProfilePageState {
  const ProfilePageState({
    required this.page,
    required this.worlds,
    required this.hasMore,
    this.loadingMore = false,
    this.moreFailure,
  });

  final ProfilePage page;
  final List<ProfileWorld> worlds;
  final bool hasMore;
  final bool loadingMore;
  final AppFailure? moreFailure;
}

/// The profile page of a username: public for everyone, with private counts
/// added by the server when the signed-in user owns it. Loaded again when
/// the user signs in or out, since that changes what they may see.
final profilePageProvider = AsyncNotifierProvider.autoDispose
    .family<ProfilePageController, ProfilePageState, String>(
      ProfilePageController.new,
    );

class ProfilePageController extends AsyncNotifier<ProfilePageState> {
  ProfilePageController(this.username);

  final String username;

  @override
  Future<ProfilePageState> build() async {
    ref.watch(currentUserProvider.select((user) => user?.id));
    final page = await ref.watch(profileRepositoryProvider).page(username);
    return ProfilePageState(
      page: page,
      worlds: page.worlds,
      hasMore: page.hasMore,
    );
  }

  /// Adds the next page of published Worlds.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      ProfilePageState(
        page: current.page,
        worlds: current.worlds,
        hasMore: true,
        loadingMore: true,
      ),
    );
    try {
      final next = await ref
          .read(profileRepositoryProvider)
          .page(username, offset: current.worlds.length);
      if (!ref.mounted) return;
      final known = {for (final world in current.worlds) world.id};
      state = AsyncData(
        ProfilePageState(
          page: current.page,
          worlds: [
            ...current.worlds,
            for (final world in next.worlds)
              if (!known.contains(world.id)) world,
          ],
          hasMore: next.hasMore,
        ),
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        ProfilePageState(
          page: current.page,
          worlds: current.worlds,
          hasMore: true,
          moreFailure: error is AppFailure
              ? error
              : const AppFailure.unexpected(),
        ),
      );
    }
  }
}

/// The username asked for at sign-up, kept until the profile screen has
/// checked whether the server assigned a different one.
final requestedUsernameProvider = NotifierProvider<RequestedUsername, String?>(
  RequestedUsername.new,
);

class RequestedUsername extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String username) => state = username;

  void clear() => state = null;
}

/// Saves the profile form.
final editProfileControllerProvider =
    AsyncNotifierProvider.autoDispose<EditProfileController, void>(
      EditProfileController.new,
    );

class EditProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns whether the profile was saved.
  Future<bool> save({
    required String username,
    required String displayName,
    required String bio,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        const AppFailure.unauthenticated(),
        StackTrace.current,
      );
      return false;
    }

    // Stay alive until the save finishes, even if the screen closes, so the
    // profile is always refreshed after a successful save.
    final keepAlive = ref.keepAlive();
    try {
      state = const AsyncLoading();
      final result = await AsyncValue.guard(
        () => ref
            .read(profileRepositoryProvider)
            .updateProfile(
              userId: user.id,
              username: ProfileRules.normalizeUsername(username),
              displayName: ProfileRules.blankToNull(displayName),
              bio: ProfileRules.blankToNull(bio),
            ),
      );
      if (!result.hasError) {
        // The username has been changed deliberately; any sign-up notice is
        // no longer relevant.
        ref.read(requestedUsernameProvider.notifier).clear();
        ref.invalidate(ownProfileProvider);
      }
      state = result.hasError
          ? AsyncError(result.error!, result.stackTrace!)
          : const AsyncData(null);
      return !result.hasError;
    } finally {
      keepAlive.close();
    }
  }
}
