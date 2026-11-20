import 'package:flutter/widgets.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// Everything a map view shows and reports. The map is declarative: rebuild
/// with new values and the implementation applies the difference.
@immutable
class MapViewConfig {
  const MapViewConfig({
    required this.initialCamera,
    required this.markers,
    required this.onMarkerTapped,
    required this.onUserCameraIdle,
    this.selectedMarkerId,
    this.userLocation,
    this.cameraRequest,
    this.onMapTapped,
  });

  /// Used once, when the map is created.
  final MapCamera initialCamera;

  final List<MapMarker> markers;
  final String? selectedMarkerId;

  /// A single position sample to show, or null.
  final GeoPoint? userLocation;

  /// Applied once per new request id.
  final CameraRequest? cameraRequest;

  final ValueChanged<String> onMarkerTapped;

  /// Called when the camera stops after the *user* moved it. Moves caused by
  /// [cameraRequest] are not reported.
  final ValueChanged<MapCamera> onUserCameraIdle;

  final VoidCallback? onMapTapped;
}

/// The app's only way to show a map. Implementations wrap one map SDK, so
/// no SDK type appears outside `lib/core/maps`.
abstract interface class MapAdapter {
  Widget buildMap(MapViewConfig config);
}
