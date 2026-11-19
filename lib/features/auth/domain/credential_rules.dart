/// Client-side checks for sign-in and sign-up fields.
///
/// These are for quick feedback only. Supabase Auth enforces its own rules.
abstract final class CredentialRules {
  /// Supabase's default minimum is 6. The app asks for more.
  static const minPasswordLength = 8;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// An error message, or null when [value] looks like an email address.
  static String? validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  /// An error message, or null when [value] is long enough for a new account.
  static String? validateNewPassword(String value) {
    if (value.isEmpty) return 'Enter a password.';
    if (value.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }

  /// An error message, or null when [value] is not empty.
  static String? validateExistingPassword(String value) =>
      value.isEmpty ? 'Enter your password.' : null;
}
