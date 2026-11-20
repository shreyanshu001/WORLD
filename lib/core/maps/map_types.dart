import 'package:flutter/foundation.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// Where the map is looking.
@immutable
class MapCamera {
  const MapCamera({required this.target, required this.zoom});

  final GeoPoint target;
  final double zoom;
}

/// A request to move the map once. A new [id] means a new request.
@immutable
class CameraRequest {
  const CameraRequest({required this.id, required this.target, this.zoom});

  final int id;
  final GeoPoint target;
  final double? zoom;

  @override
  bool operator ==(Object other) =>
      other is CameraRequest &&
      other.id == id &&
      other.target == target &&
      other.zoom == zoom;

  @override
  int get hashCode => Object.hash(id, target, zoom);
}

/// A tappable point on the map.
@immutable
class MapMarker {
  const MapMarker({
    required this.id,
    required this.point,
    required this.colorHex,
  });

  final String id;
  final GeoPoint point;

  /// Fill colour as `#RRGGBB`.
  final String colorHex;

  @override
  bool operator ==(Object other) =>
      other is MapMarker &&
      other.id == id &&
      other.point == point &&
      other.colorHex == colorHex;

  @override
  int get hashCode => Object.hash(id, point, colorHex);
}

/// A circular area drawn at its true size, such as a World's unlock radius.
@immutable
class MapArea {
  const MapArea({
    required this.center,
    required this.radiusMeters,
    required this.colorHex,
  });

  final GeoPoint center;
  final double radiusMeters;

  /// Colour as `#RRGGBB`; filled translucently with a solid outline.
  final String colorHex;

  @override
  bool operator ==(Object other) =>
      other is MapArea &&
      other.center == center &&
      other.radiusMeters == radiusMeters &&
      other.colorHex == colorHex;

  @override
  int get hashCode => Object.hash(center, radiusMeters, colorHex);
}

/// A map style and the attribution its terms require.
@immutable
class MapStyle {
  const MapStyle({required this.url, required this.attribution});

  /// OpenFreeMap's public instance: free, commercial use allowed, no key, no
  /// SLA. Its tile source requires this attribution.
  static const openFreeMap = MapStyle(
    url: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: 'OpenFreeMap © OpenMapTiles Data from OpenStreetMap',
  );

  final String url;
  final String attribution;
}
