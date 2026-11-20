import 'package:worlds/features/profile/domain/profile.dart';

/// Reads and updates profiles.
///
/// Every method throws an `AppFailure` when it fails.
abstract interface class ProfileRepository {
  Future<Profile> fetchProfile(String userId);

  /// Saves the editable fields of the profile owned by [userId].
  ///
  /// Throws `AppFailure.usernameTaken` when [username] belongs to someone
  /// else.
  Future<Profile> updateProfile({
    required String userId,
    required String username,
    String? displayName,
    String? bio,
  });

  /// Whether nobody has [username] yet. A true answer can still lose a race.
  Future<bool> isUsernameAvailable(String username);
}
