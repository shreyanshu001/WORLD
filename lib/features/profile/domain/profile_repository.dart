import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';

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

  /// How many published Worlds one [page] request returns.
  static const worldsPageSize = 20;

  /// The profile page of [username]: public fields and published Worlds
  /// from [offset], newest first, plus the private counts when the signed-in
  /// user is its owner. Throws `AppFailure.notFound` for an unknown
  /// username.
  Future<ProfilePage> page(String username, {int offset = 0});
}
