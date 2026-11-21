import 'dart:async';

import 'package:flutter/material.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A published World near (51.5, -0.12) for tests.
WorldPreview testWorld(
  String id,
  String title,
  WorldCategory category, {
  double distanceMeters = 500,
  String creator = 'alice',
  String? creatorDisplayName,
  double latitude = 51.5,
  double longitude = -0.12,
}) => WorldPreview(
  id: id,
  title: title,
  category: category,
  latitude: latitude,
  longitude: longitude,
  distanceMeters: distanceMeters,
  creatorUsername: creator,
  creatorDisplayName: creatorDisplayName,
);

/// Details for a published public World, for tests.
WorldDetails testDetails(
  String id,
  String title,
  WorldCategory category, {
  String? description = 'A short walk along the harbour.',
  double? distanceMeters,
  String? coverPath,
  int blockCount = 3,
  WorldStatus status = WorldStatus.published,
  DateTime? publishedAt,
  bool isCreator = false,
  int unlockRadiusMeters = 50,
}) => WorldDetails(
  id: id,
  title: title,
  description: description,
  category: category,
  unlockRadiusMeters: unlockRadiusMeters,
  latitude: 51.5,
  longitude: -0.12,
  distanceMeters: distanceMeters,
  creatorUsername: 'alice',
  creatorDisplayName: 'Alice',
  coverPath: coverPath,
  blockCount: blockCount,
  status: status,
  publishedAt:
      publishedAt ??
      (status == WorldStatus.published ? DateTime.utc(2026, 11, 20) : null),
  isCreator: isCreator,
);

/// In-memory [WorldRepository] that filters like the server does.
class FakeWorldRepository implements WorldRepository {
  FakeWorldRepository([List<WorldPreview>? worlds]) : worlds = worlds ?? [];

  List<WorldPreview> worlds;
  final queries = <NearbyQuery>[];

  /// Details by World id; missing ids are not found.
  final detailsById = <String, WorldDetails>{};
  final detailsRequests = <({String worldId, GeoPoint? from})>[];

  /// Thrown, then cleared, by the next details request.
  Object? nextDetailsError;

  @override
  Future<WorldDetails> details(String worldId, {GeoPoint? from}) async {
    detailsRequests.add((worldId: worldId, from: from));
    await Future<void>.delayed(Duration.zero);
    final error = nextDetailsError;
    if (error != null) {
      nextDetailsError = null;
      throw error;
    }
    final found = detailsById[worldId];
    if (found == null) throw const AppFailure.notFound();
    return found;
  }

  /// Thrown, then cleared, by the next search.
  Object? nextError;

  /// When true, each search waits until the test completes it.
  bool holdResponses = false;
  final held = <Completer<List<WorldPreview>>>[];

  @override
  Future<List<WorldPreview>> nearby(NearbyQuery query) async {
    queries.add(query);
    if (holdResponses) {
      final completer = Completer<List<WorldPreview>>();
      held.add(completer);
      return completer.future;
    }
    await Future<void>.delayed(Duration.zero);
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    final text = query.searchText?.toLowerCase();
    return worlds
        .where(
          (world) =>
              (query.category == null || world.category == query.category) &&
              (text == null || world.title.toLowerCase().contains(text)),
        )
        .toList();
  }
}

/// [WorldMediaRepository] that signs nothing: every image fails to load, so
/// widgets fall back to their placeholders.
class FakeWorldMediaRepository implements WorldMediaRepository {
  final requested = <String>[];

  @override
  Future<Uri> imageUrl(String storagePath) async {
    requested.add(storagePath);
    throw const AppFailure.notFound();
  }
}

/// [LocationService] whose answers the test sets, counting every call.
class FakeLocationService implements LocationService {
  bool serviceEnabled = true;
  LocationPermissionStatus permission = LocationPermissionStatus.denied;
  LocationPermissionStatus requestResult = LocationPermissionStatus.granted;
  GeoPoint position = const GeoPoint(latitude: 51.51, longitude: -0.13);
  Object? positionError;

  int serviceChecks = 0;
  int permissionChecks = 0;
  int permissionRequests = 0;
  int positionReads = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  /// Whether the app has touched location at all.
  int get totalCalls =>
      serviceChecks + permissionChecks + permissionRequests + positionReads;

  @override
  Future<bool> isServiceEnabled() async {
    serviceChecks++;
    return serviceEnabled;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    permissionChecks++;
    return permission;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    permissionRequests++;
    permission = requestResult;
    return requestResult;
  }

  @override
  Future<GeoPoint> currentPosition({required Duration timeLimit}) async {
    positionReads++;
    if (positionError case final error?) throw error;
    return position;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}

/// [MapAdapter] that draws markers as buttons so tests can tap them.
class FakeMapAdapter implements MapAdapter {
  MapViewConfig? lastConfig;

  @override
  Widget buildMap(MapViewConfig config) {
    lastConfig = config;
    return _FakeMap(config: config);
  }

  /// Simulates the user moving the map and letting it settle.
  void userMovesMapTo(GeoPoint target, {double zoom = 13}) =>
      lastConfig!.onUserCameraIdle(MapCamera(target: target, zoom: zoom));
}

class _FakeMap extends StatelessWidget {
  const _FakeMap({required this.config});

  final MapViewConfig config;

  @override
  Widget build(BuildContext context) {
    // Below the floating search bar and filters, as on a phone screen.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 260),
      child: Column(
        children: [
          if (config.userLocation != null) const Text('user location shown'),
          for (final area in config.areas)
            Text('area ${area.radiusMeters.round()} m'),
          for (final marker in config.markers)
            TextButton(
              key: ValueKey('marker-${marker.id}'),
              onPressed: () => config.onMarkerTapped(marker.id),
              child: Text(
                'marker ${marker.id}'
                '${marker.id == config.selectedMarkerId ? ' (selected)' : ''}',
              ),
            ),
          TextButton(
            key: const ValueKey('map-background'),
            onPressed: config.onMapTapped,
            child: const Text('empty map area'),
          ),
        ],
      ),
    );
  }
}
