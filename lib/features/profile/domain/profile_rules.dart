/// Client-side copies of the profile rules enforced by the database
/// (supabase/migrations/*_create_profiles.sql). Keep the two in step.
abstract final class ProfileRules {
  static const minUsernameLength = 3;
  static const maxUsernameLength = 20;
  static const maxDisplayNameLength = 50;
  static const maxBioLength = 280;

  static final _username = RegExp(r'^[a-z0-9_]{3,20}$');

  /// The form usernames are stored in: trimmed and lower-case.
  static String normalizeUsername(String value) => value.trim().toLowerCase();

  /// An error message, or null when [value] is a valid username once
  /// normalised.
  static String? validateUsername(String value) {
    final username = normalizeUsername(value);
    if (username.isEmpty) return 'Choose a username.';
    if (username.length < minUsernameLength ||
        username.length > maxUsernameLength) {
      return 'Use $minUsernameLength–$maxUsernameLength characters.';
    }
    if (!_username.hasMatch(username)) {
      return 'Use only letters, numbers and underscores.';
    }
    return null;
  }

  /// An error message, or null when [value] is an acceptable display name.
  /// Blank means "no display name".
  static String? validateDisplayName(String value) =>
      value.trim().length > maxDisplayNameLength
      ? 'Use at most $maxDisplayNameLength characters.'
      : null;

  /// An error message, or null when [value] is an acceptable bio.
  static String? validateBio(String value) => value.length > maxBioLength
      ? 'Use at most $maxBioLength characters.'
      : null;

  /// Trims [value] and turns blank text into null.
  static String? blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
