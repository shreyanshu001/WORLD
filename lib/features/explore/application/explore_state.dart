import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'explore_state.freezed.dart';

/// Where the user's location stands. Nothing is read until the user asks.
enum LocationStatus {
  notRequested,
  locating,
  located,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

enum ExploreView { map, list }

@freezed
abstract class ExploreState with _$ExploreState {
  const factory ExploreState({
    /// The centre of the current search; null until the user picks an area.
    GeoPoint? searchCenter,

    /// Whether [searchCenter] is the user's own position.
    @Default(false) bool centerIsUserLocation,
    WorldCategory? category,
    @Default('') String searchText,
    @Default(<WorldPreview>[]) List<WorldPreview> worlds,
    @Default(false) bool loading,

    /// Whether a search has completed at least once for an area.
    @Default(false) bool searched,
    AppFailure? error,
    String? selectedWorldId,
    @Default(LocationStatus.notRequested) LocationStatus locationStatus,

    /// The single position sample taken when the user tapped locate.
    GeoPoint? userLocation,
    CameraRequest? cameraRequest,
    @Default(ExploreView.map) ExploreView view,
  }) = _ExploreState;

  const ExploreState._();

  WorldPreview? get selectedWorld {
    for (final world in worlds) {
      if (world.id == selectedWorldId) return world;
    }
    return null;
  }

  bool get hasFilters => category != null || searchText.trim().isNotEmpty;
}
