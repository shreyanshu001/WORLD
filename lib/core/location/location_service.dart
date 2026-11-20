import 'package:worlds/shared/models/geo_point.dart';

/// Whether the app may read the device's location in the foreground.
enum LocationPermissionStatus {
  granted,

  /// Not granted yet; asking again shows the system prompt.
  denied,

  /// Blocked; only the system settings can change it.
  deniedForever,
}

/// Foreground location only. Nothing here runs in the background or keeps
/// tracking: callers ask for one position at a time, when the user acts.
abstract interface class LocationService {
  Future<bool> isServiceEnabled();

  /// Reads the current permission without prompting.
  Future<LocationPermissionStatus> checkPermission();

  /// Shows the system prompt when Android allows it.
  Future<LocationPermissionStatus> requestPermission();

  /// One fresh position. Throws `AppFailure.locationUnavailable` if none
  /// arrives within [timeLimit], or `AppFailure.permissionDenied`.
  Future<GeoPoint> currentPosition({required Duration timeLimit});

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}
