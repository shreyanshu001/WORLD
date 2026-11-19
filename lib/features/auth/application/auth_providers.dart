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
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email.trim(), password: password),
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
    final result = await AsyncValue.guard(() async {
      final available = await ref
          .read(profileRepositoryProvider)
          .isUsernameAvailable(requested);
      if (!available) throw const AppFailure.usernameTaken();
      ref.read(requestedUsernameProvider.notifier).set(requested);
      return ref
          .read(authRepositoryProvider)
          .signUp(email: email.trim(), password: password, username: requested);
    });
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
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
    if (ref.mounted) state = result;
  }
}
