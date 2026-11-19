import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/features/auth/domain/auth_repository.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';

/// [AuthRepository] backed by Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  /// Supabase's auth stream replays its whole history to every new listener.
  /// Each event is therefore used only as a signal to re-read the current
  /// user, so a late listener never sees a stale signed-in state.
  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield currentUser;
    yield* _auth.onAuthStateChange
        .map((_) => currentUser)
        // A failed background token refresh arrives as a stream error; the
        // session state is still read from the client on the next event.
        .handleError((Object _) {});
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      return response.session == null
          ? SignUpOutcome.confirmationRequired
          : SignUpOutcome.signedIn;
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  /// Clears the local session first, then tells the server. A network
  /// failure still leaves the device signed out.
  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  static AuthUser? _toAuthUser(User? user) =>
      user == null ? null : AuthUser(id: user.id, email: user.email);
}
