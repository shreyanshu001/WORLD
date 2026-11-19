import 'dart:async';

import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_repository.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/domain/profile_repository.dart';

/// A profile with fixed timestamps, for tests.
Profile testProfile(
  String id,
  String username, {
  String? displayName,
  String? bio,
}) => Profile(
  id: id,
  username: username,
  displayName: displayName,
  bio: bio,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// In-memory [AuthRepository].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? signedInAs}) : _user = signedInAs;

  AuthUser? _user;
  final _changes = StreamController<AuthUser?>.broadcast();
  final _accounts = <String, ({String password, AuthUser user})>{};

  /// Thrown, then cleared, by the next call.
  Object? nextError;

  /// What [signUp] reports.
  SignUpOutcome signUpOutcome = SignUpOutcome.signedIn;

  /// The id given to the next account created by [signUp].
  String newUserId = 'new-user';

  /// Called when [signUp] creates an account, like the database trigger that
  /// creates the profile. Receives the new user id and requested username.
  void Function(String userId, String username)? onSignedUp;

  /// Usernames passed to [signUp], in order.
  final signUpRequests = <String>[];

  void addAccount(String email, String password, AuthUser user) =>
      _accounts[email] = (password: password, user: user);

  void _set(AuthUser? user) {
    _user = user;
    _changes.add(user);
  }

  void _throwPending() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(Duration.zero);
    _throwPending();
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const AppFailure.invalidCredentials();
    }
    _set(account.user);
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await Future<void>.delayed(Duration.zero);
    _throwPending();
    signUpRequests.add(username);
    onSignedUp?.call(newUserId, username);
    if (signUpOutcome == SignUpOutcome.signedIn) {
      _set(AuthUser(id: newUserId, email: email));
    }
    return signUpOutcome;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(Duration.zero);
    _throwPending();
    _set(null);
  }
}

/// In-memory [ProfileRepository] that enforces unique usernames.
class FakeProfileRepository implements ProfileRepository {
  final profiles = <String, Profile>{};

  /// Thrown by every [fetchProfile] call while set.
  Object? fetchError;

  /// Thrown, then cleared, by the next [updateProfile] call.
  Object? nextUpdateError;

  int updateCount = 0;

  void add(Profile profile) => profiles[profile.id] = profile;

  @override
  Future<Profile> fetchProfile(String userId) async {
    await Future<void>.delayed(Duration.zero);
    if (fetchError case final error?) throw error;
    final profile = profiles[userId];
    if (profile == null) throw const AppFailure.notFound();
    return profile;
  }

  @override
  Future<Profile> updateProfile({
    required String userId,
    required String username,
    String? displayName,
    String? bio,
  }) async {
    await Future<void>.delayed(Duration.zero);
    updateCount++;
    final error = nextUpdateError;
    if (error != null) {
      nextUpdateError = null;
      throw error;
    }
    final takenByOther = profiles.values.any(
      (profile) => profile.username == username && profile.id != userId,
    );
    if (takenByOther) throw const AppFailure.usernameTaken();
    final current = profiles[userId];
    if (current == null) throw const AppFailure.notFound();
    final updated = current.copyWith(
      username: username,
      displayName: displayName,
      bio: bio,
    );
    profiles[userId] = updated;
    return updated;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    await Future<void>.delayed(Duration.zero);
    return !profiles.values.any((profile) => profile.username == username);
  }
}
