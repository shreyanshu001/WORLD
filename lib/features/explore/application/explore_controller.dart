import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_providers.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/features/explore/application/explore_state.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// Where Explore opens before the user shares a location, or null to open
/// zoomed out. Set from `EXPLORE_DEFAULT_CENTER` at startup.
final exploreDefaultCenterProvider = Provider<GeoPoint?>((ref) => null);

final exploreControllerProvider =
    NotifierProvider.autoDispose<ExploreController, ExploreState>(
      ExploreController.new,
    );

class ExploreController extends Notifier<ExploreState> {
  /// Map moves smaller than this do not trigger a new search.
  static const requeryDistanceMeters = 300.0;

  /// Below this zoom a 5 km search would be meaningless, so panning the map
  /// does not search.
  static const minSearchZoom = 9.0;

  static const cameraDebounce = Duration(milliseconds: 500);
  static const searchDebounce = Duration(milliseconds: 400);
  static const locationTimeout = Duration(seconds: 15);
  static const locatedZoom = 14.0;
  static const worldZoom = 15.0;

  Timer? _cameraTimer;
  Timer? _searchTimer;
  int _querySequence = 0;
  int _cameraSequence = 0;
  bool _sentToSettings = false;

  @override
  ExploreState build() {
    ref.onDispose(() {
      _cameraTimer?.cancel();
      _searchTimer?.cancel();
    });
    final center = ref.watch(exploreDefaultCenterProvider);
    if (center != null) scheduleMicrotask(_load);
    return ExploreState(searchCenter: center);
  }

  /// Searches again with the current settings.
  Future<void> retry() => _load();

  void selectCategory(WorldCategory? category) {
    if (category == state.category) return;
    state = state.copyWith(category: category);
    unawaited(_load());
  }

  /// Updates the title search after the user pauses typing.
  void updateSearchText(String text) {
    state = state.copyWith(searchText: text);
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () => unawaited(_load()));
  }

  /// The user moved the map. Searches there once the map settles, if it
  /// moved far enough and is zoomed in enough.
  void onUserCameraIdle(MapCamera camera) {
    _cameraTimer?.cancel();
    if (camera.zoom < minSearchZoom) return;
    _cameraTimer = Timer(cameraDebounce, () {
      if (!ref.mounted) return;
      final current = state.searchCenter;
      if (current != null &&
          current.distanceMetersTo(camera.target) < requeryDistanceMeters) {
        return;
      }
      state = state.copyWith(
        searchCenter: camera.target,
        centerIsUserLocation: false,
      );
      unawaited(_load());
    });
  }

  void selectWorld(String? worldId) {
    state = state.copyWith(selectedWorldId: worldId);
  }

  /// Selects a World and shows it on the map.
  void showWorldOnMap(String worldId) {
    final world = state.worlds.where((w) => w.id == worldId).firstOrNull;
    if (world == null) return;
    state = state.copyWith(
      selectedWorldId: worldId,
      view: ExploreView.map,
      cameraRequest: CameraRequest(
        id: ++_cameraSequence,
        target: world.point,
        zoom: worldZoom,
      ),
    );
  }

  void setView(ExploreView view) => state = state.copyWith(view: view);

  void dismissLocationMessage() {
    state = state.copyWith(locationStatus: LocationStatus.notRequested);
  }

  /// Whether tapping "find Worlds near me" will show Android's permission
  /// prompt, so the app should first explain why it wants location
  /// (docs/SECURITY_AND_PRIVACY.md). Reads settings only; reads no position.
  Future<bool> shouldExplainLocation() async {
    final location = ref.read(locationServiceProvider);
    try {
      if (!await location.isServiceEnabled()) return false;
      return await location.checkPermission() ==
          LocationPermissionStatus.denied;
    } on Object {
      return false;
    }
  }

  /// Asks for permission if needed, takes one position sample, centres the
  /// map there and searches. Runs only when the user asks.
  Future<void> locate() async {
    if (state.locationStatus == LocationStatus.locating) return;
    final location = ref.read(locationServiceProvider);
    state = state.copyWith(locationStatus: LocationStatus.locating);

    try {
      if (!await location.isServiceEnabled()) {
        _setLocationStatus(LocationStatus.serviceDisabled);
        return;
      }
      if (!ref.mounted) return;

      var permission = await location.checkPermission();
      if (!ref.mounted) return;
      if (permission == LocationPermissionStatus.denied) {
        permission = await location.requestPermission();
        if (!ref.mounted) return;
      }
      switch (permission) {
        case LocationPermissionStatus.denied:
          _setLocationStatus(LocationStatus.denied);
          return;
        case LocationPermissionStatus.deniedForever:
          _setLocationStatus(LocationStatus.deniedForever);
          return;
        case LocationPermissionStatus.granted:
          break;
      }

      final point = await location.currentPosition(timeLimit: locationTimeout);
      if (!ref.mounted) return;
      state = state.copyWith(
        locationStatus: LocationStatus.located,
        userLocation: point,
        searchCenter: point,
        centerIsUserLocation: true,
        cameraRequest: CameraRequest(
          id: ++_cameraSequence,
          target: point,
          zoom: locatedZoom,
        ),
      );
      await _load();
    } on Object {
      _setLocationStatus(LocationStatus.unavailable);
    }
  }

  /// Opens the system screen that can fix the current location problem.
  Future<void> openLocationSettings() async {
    final location = ref.read(locationServiceProvider);
    _sentToSettings = true;
    if (state.locationStatus == LocationStatus.serviceDisabled) {
      await location.openLocationSettings();
    } else {
      await location.openAppSettings();
    }
  }

  /// Call when the app returns to the foreground. If the user went to the
  /// system settings from here, try again with the new settings.
  void onAppResumed() {
    if (!_sentToSettings) return;
    _sentToSettings = false;
    unawaited(locate());
  }

  void _setLocationStatus(LocationStatus status) {
    if (ref.mounted) state = state.copyWith(locationStatus: status);
  }

  Future<void> _load() async {
    if (!ref.mounted) return;
    _searchTimer?.cancel();
    final center = state.searchCenter;
    if (center == null) return;

    final sequence = ++_querySequence;
    final text = state.searchText.trim();
    final query = NearbyQuery(
      center: center,
      category: state.category,
      searchText: text.isEmpty ? null : text,
    );
    state = state.copyWith(loading: true, error: null);

    try {
      final worlds = await ref.read(worldRepositoryProvider).nearby(query);
      // A newer search has started since: drop this result.
      if (!ref.mounted || sequence != _querySequence) return;
      final selected = state.selectedWorldId;
      state = state.copyWith(
        worlds: worlds,
        loading: false,
        searched: true,
        error: null,
        selectedWorldId: worlds.any((w) => w.id == selected) ? selected : null,
      );
    } on Object catch (error) {
      if (!ref.mounted || sequence != _querySequence) return;
      state = state.copyWith(
        loading: false,
        error: error is AppFailure ? error : const AppFailure.unexpected(),
      );
    }
  }
}
