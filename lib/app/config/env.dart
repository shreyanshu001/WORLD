import 'dart:convert';

/// A reason the build-time configuration cannot be used.
enum EnvProblem {
  missingSupabaseUrl,
  invalidSupabaseUrl,
  missingSupabaseKey,
  secretSupabaseKey,
}

/// Build-time configuration for the app.
///
/// Values are compiled in with `--dart-define-from-file=.env`. Only public
/// client values belong here: the Supabase project URL and its publishable key.
class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  /// Reads the values compiled into this build.
  factory AppEnv.fromEnvironment() => const AppEnv(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Everything wrong with this configuration; empty when it is usable.
  List<EnvProblem> get problems => [
    if (supabaseUrl.trim().isEmpty)
      EnvProblem.missingSupabaseUrl
    else if (!_isUsableUrl(supabaseUrl.trim()))
      EnvProblem.invalidSupabaseUrl,
    if (supabasePublishableKey.trim().isEmpty)
      EnvProblem.missingSupabaseKey
    else if (_isSecretKey(supabasePublishableKey.trim()))
      EnvProblem.secretSupabaseKey,
  ];

  static const _localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  /// HTTPS is required, except for a Supabase stack running on this machine.
  static bool _isUsableUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' && _localHosts.contains(uri.host);
  }

  /// Detects keys that bypass row-level security and must never ship.
  ///
  /// Covers the `sb_secret_` format and legacy JWT keys whose role is
  /// `service_role`.
  static bool _isSecretKey(String value) {
    if (value.startsWith('sb_secret_')) return true;

    final parts = value.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map<String, Object?> &&
          payload['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}

/// Developer-facing explanation of an [EnvProblem]. Never includes a value.
extension EnvProblemDescription on EnvProblem {
  String get description => switch (this) {
    EnvProblem.missingSupabaseUrl => 'SUPABASE_URL is not set.',
    EnvProblem.invalidSupabaseUrl =>
      'SUPABASE_URL is not a valid https:// address.',
    EnvProblem.missingSupabaseKey => 'SUPABASE_PUBLISHABLE_KEY is not set.',
    EnvProblem.secretSupabaseKey =>
      'SUPABASE_PUBLISHABLE_KEY holds a secret or service-role key. '
          'Use the publishable key instead.',
  };
}
