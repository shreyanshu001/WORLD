import 'package:worlds/features/auth/domain/auth_user.dart';

/// What happened after a successful sign-up request.
enum SignUpOutcome {
  /// The account is ready and the user is signed in.
  signedIn,

  /// The user must confirm their email address before signing in.
  ///
  /// Supabase gives this same answer when the email already has an account,
  /// so the UI must not claim that a new account was created.
  confirmationRequired,
}

/// Email-and-password authentication.
///
/// Every method throws an `AppFailure` when it fails.
abstract interface class AuthRepository {
  /// The signed-in user, or null.
  AuthUser? get currentUser;

  /// The current user, then every change to it.
  Stream<AuthUser?> authStateChanges();

  /// Creates an account. [username] is a request: the server may assign a
  /// generated name if it is taken.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}
