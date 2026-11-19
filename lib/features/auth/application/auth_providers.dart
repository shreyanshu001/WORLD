import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/auth/data/supabase_auth_repository.dart';
import 'package:worlds/features/auth/domain/auth_repository.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';
import 'package:worlds/features/profile/domain/profile_rules.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider).auth),
);

/// The signed-in user over time.
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The signed-in user, or null when signed out.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.hasValue
      ? state.value
      : ref.watch(authRepositoryProvider).currentUser;
});

/// Submits the sign-in form.
final signInControllerProvider =
    AsyncNotifierProvider.autoDispose<SignInController, void>(
      SignInController.new,
    );

class SignInController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    // Signing in to an existing account: no sign-up notice applies.
    ref.read(requestedUsernameProvider.notifier).clear();
    final auth = ref.read(authRepositoryProvider);
    final result = await AsyncValue.guard(
      () => auth.signIn(email: email.trim(), password: password),
    );
    if (ref.mounted) state = result;
  }
}

/// Submits the sign-up form. Its value is the outcome once submitted.
final registerControllerProvider =
    AsyncNotifierProvider.autoDispose<RegisterController, SignUpOutcome?>(
      RegisterController.new,
    );

class RegisterController extends AsyncNotifier<SignUpOutcome?> {
  @override
  FutureOr<SignUpOutcome?> build() => null;

  Future<void> submit({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final requested = ProfileRules.normalizeUsername(username);
    // Read everything up front: a successful sign-up navigates away and
    // disposes this controller before signUp returns.
    final profiles = ref.read(profileRepositoryProvider);
    final auth = ref.read(authRepositoryProvider);
    final pendingNotice = ref.read(requestedUsernameProvider.notifier);

    final result = await AsyncValue.guard(() async {
      final available = await profiles.isUsernameAvailable(requested);
      if (!available) throw const AppFailure.usernameTaken();
      // Set before signing up, because the profile screen can appear before
      // signUp returns.
      pendingNotice.set(requested);
      return auth.signUp(
        email: email.trim(),
        password: password,
        username: requested,
      );
    });

    // Only a sign-up that ends signed in may leave a notice behind.
    if (result.value != SignUpOutcome.signedIn) pendingNotice.clear();
    if (ref.mounted) state = result;
  }
}

/// Signs the user out.
final signOutControllerProvider =
    AsyncNotifierProvider.autoDispose<SignOutController, void>(
      SignOutController.new,
    );

class SignOutController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signOut() async {
    state = const AsyncLoading();
    final auth = ref.read(authRepositoryProvider);
    final pendingNotice = ref.read(requestedUsernameProvider.notifier);
    final result = await AsyncValue.guard(auth.signOut);
    pendingNotice.clear();
    if (ref.mounted) state = result;
  }
}
