import 'dart:convert';

import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// A reason the build-time configuration cannot be used.
enum EnvProblem {
  missingSupabaseUrl,
  invalidSupabaseUrl,
  missingSupabaseKey,
  secretSupabaseKey,
  invalidMapStyleUrl,
  missingMapAttribution,
  invalidExploreCenter,
}

/// Build-time configuration for the app.
///
/// Values are compiled in with `--dart-define-from-file=.env`. Only public
/// client values belong here.
class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.mapStyleUrl = '',
    this.mapAttribution = '',
    this.exploreDefaultCenter = '',
  });

  /// Reads the values compiled into this build.
  factory AppEnv.fromEnvironment() => const AppEnv(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    mapStyleUrl: String.fromEnvironment('MAP_STYLE_URL'),
    mapAttribution: String.fromEnvironment('MAP_ATTRIBUTION'),
    exploreDefaultCenter: String.fromEnvironment('EXPLORE_DEFAULT_CENTER'),
  );

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Optional. Blank means OpenFreeMap.
  final String mapStyleUrl;

  /// Required with a custom [mapStyleUrl]: the attribution its terms demand.
  final String mapAttribution;

  /// Optional `latitude,longitude` where Explore opens before the user
  /// shares a location. Blank means the map opens zoomed out.
  final String exploreDefaultCenter;

  /// The map style to use.
  MapStyle get mapStyle {
    final url = mapStyleUrl.trim();
    if (url.isEmpty) return MapStyle.openFreeMap;
    return MapStyle(url: url, attribution: mapAttribution.trim());
  }

  /// [exploreDefaultCenter] parsed, or null when blank or invalid.
  GeoPoint? get exploreCenter => _parseCenter(exploreDefaultCenter);

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
    if (mapStyleUrl.trim().isNotEmpty) ...[
      if (Uri.tryParse(mapStyleUrl.trim())?.scheme != 'https')
        EnvProblem.invalidMapStyleUrl,
      if (mapAttribution.trim().isEmpty) EnvProblem.missingMapAttribution,
    ],
    if (exploreDefaultCenter.trim().isNotEmpty && exploreCenter == null)
      EnvProblem.invalidExploreCenter,
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

  static GeoPoint? _parseCenter(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final latitude = double.tryParse(parts[0].trim());
    final longitude = double.tryParse(parts[1].trim());
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return GeoPoint(latitude: latitude, longitude: longitude);
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
    EnvProblem.invalidMapStyleUrl =>
      'MAP_STYLE_URL is not a valid https:// address.',
    EnvProblem.missingMapAttribution =>
      'MAP_ATTRIBUTION must be set when MAP_STYLE_URL is set.',
    EnvProblem.invalidExploreCenter =>
      'EXPLORE_DEFAULT_CENTER must be "latitude,longitude".',
  };
}
