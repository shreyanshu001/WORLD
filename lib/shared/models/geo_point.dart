import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_point.freezed.dart';

/// A position on Earth in WGS 84 degrees.
@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({
    required double latitude,
    required double longitude,
  }) = _GeoPoint;

  const GeoPoint._();

  static const _earthRadiusMeters = 6371008.8;

  /// Approximate great-circle distance. For moving the map only: distances
  /// shown to users and proximity checks come from the server.
  double distanceMetersTo(GeoPoint other) {
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(other.latitude - latitude);
    final dLon = radians(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(latitude)) *
            math.cos(radians(other.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(a));
  }
}
