import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// [LocationService] backed by the geolocator plugin.
///
/// geolocator's background foreground-service is removed from the Android
/// manifest, and no position stream is ever opened.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      mapPermission(await Geolocator.checkPermission());

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      mapPermission(await Geolocator.requestPermission());

  @override
  Future<GeoPoint> currentPosition({required Duration timeLimit}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(timeLimit: timeLimit),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on PermissionDeniedException {
      throw const AppFailure.permissionDenied();
    } on Object {
      // Timeouts, disabled services and platform errors all mean the same
      // thing to the user: no location right now.
      throw const AppFailure.locationUnavailable();
    }
  }

  @override
  Future<LocationFix> currentFix({required Duration timeLimit}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return LocationFix(
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        accuracyMeters: position.accuracy,
      );
    } on PermissionDeniedException {
      throw const AppFailure.permissionDenied();
    } on Object {
      throw const AppFailure.locationUnavailable();
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Maps geolocator's permission to the app's. Background permission is
  /// never requested, so `always` cannot be the result of a request; it is
  /// treated as plain foreground permission if another app granted it.
  static LocationPermissionStatus mapPermission(LocationPermission value) =>
      switch (value) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationPermissionStatus.granted,
        LocationPermission.deniedForever =>
          LocationPermissionStatus.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
      };
}
