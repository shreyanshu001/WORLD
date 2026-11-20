import 'dart:math' as math;

import 'package:worlds/shared/models/geo_point.dart';

const _earthRadiusMeters = 6371008.8;

/// Points on a circle of [radiusMeters] around [center], closed (the first
/// point is repeated at the end), for drawing an area that keeps its true
/// size at every zoom.
List<GeoPoint> circlePolygon(
  GeoPoint center,
  double radiusMeters, {
  int segments = 48,
}) {
  final lat = center.latitude * math.pi / 180;
  final lon = center.longitude * math.pi / 180;
  final angular = radiusMeters / _earthRadiusMeters;
  final points = <GeoPoint>[];
  for (var i = 0; i <= segments; i++) {
    final bearing = 2 * math.pi * (i % segments) / segments;
    final pointLat = math.asin(
      math.sin(lat) * math.cos(angular) +
          math.cos(lat) * math.sin(angular) * math.cos(bearing),
    );
    final pointLon =
        lon +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(lat),
          math.cos(angular) - math.sin(lat) * math.sin(pointLat),
        );
    points.add(
      GeoPoint(
        latitude: pointLat * 180 / math.pi,
        longitude: pointLon * 180 / math.pi,
      ),
    );
  }
  return points;
}
