import 'package:worlds/shared/models/geo_point.dart';

/// One position reading and how far off it may be.
class LocationFix {
  const LocationFix({required this.point, required this.accuracyMeters});

  final GeoPoint point;

  /// Radius, in metres, within which the true position probably lies.
  final double accuracyMeters;
}

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

  /// One fresh, high-accuracy reading with its uncertainty, for unlocking a
  /// World. Throws like [currentPosition].
  Future<LocationFix> currentFix({required Duration timeLimit});

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}
