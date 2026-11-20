import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// [MapAdapter] backed by MapLibre Native.
///
/// MapLibre's own location layer is never enabled: it would start continuous
/// location updates. The user's position is drawn from the single sample in
/// [MapViewConfig.userLocation].
class MapLibreMapAdapter implements MapAdapter {
  const MapLibreMapAdapter({required this.style});

  final MapStyle style;

  @override
  Widget buildMap(MapViewConfig config) =>
      _MapLibreMapView(styleUrl: style.url, config: config);
}

class _MapLibreMapView extends StatefulWidget {
  const _MapLibreMapView({required this.styleUrl, required this.config});

  final String styleUrl;
  final MapViewConfig config;

  @override
  State<_MapLibreMapView> createState() => _MapLibreMapViewState();
}

class _MapLibreMapViewState extends State<_MapLibreMapView> {
  static const _userColor = '#1A73E8';
  static const _strokeColor = '#FFFFFF';

  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  bool _disposed = false;
  bool _suppressNextIdle = false;
  Future<void> _pending = Future<void>.value();

  int? _appliedCameraRequestId;
  List<MapMarker>? _appliedMarkers;
  String? _appliedSelectedId;
  GeoPoint? _appliedUserLocation;

  @override
  void didUpdateWidget(_MapLibreMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSync();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    controller.onCircleTapped.add(_onCircleTapped);
  }

  void _onStyleLoaded() {
    // Annotations can only be added once the style has loaded, and a style
    // reload removes them, so apply everything again.
    _styleLoaded = true;
    _appliedMarkers = null;
    _scheduleSync();
  }

  void _onCircleTapped(Circle circle) {
    final id = circle.data?['markerId'];
    if (id is String) widget.config.onMarkerTapped(id);
  }

  void _onCameraIdle() {
    if (_suppressNextIdle) {
      _suppressNextIdle = false;
      return;
    }
    final position = _controller?.cameraPosition;
    if (position == null) return;
    widget.config.onUserCameraIdle(
      MapCamera(
        target: GeoPoint(
          latitude: position.target.latitude,
          longitude: position.target.longitude,
        ),
        zoom: position.zoom,
      ),
    );
  }

  /// Runs syncs one after another so overlapping rebuilds cannot interleave.
  void _scheduleSync() {
    _pending = _pending.then((_) => _sync()).catchError((Object error) {
      debugPrint('Map sync failed: ${error.runtimeType}');
    });
  }

  Future<void> _sync() async {
    final controller = _controller;
    if (controller == null || !_styleLoaded || _disposed) return;
    final config = widget.config;

    final request = config.cameraRequest;
    if (request != null && request.id != _appliedCameraRequestId) {
      _appliedCameraRequestId = request.id;
      _suppressNextIdle = true;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          _latLng(request.target),
          request.zoom ?? controller.cameraPosition?.zoom ?? 14,
        ),
      );
      if (_disposed) return;
    }

    final unchanged =
        _appliedMarkers != null &&
        listEquals(_appliedMarkers, config.markers) &&
        _appliedSelectedId == config.selectedMarkerId &&
        _appliedUserLocation == config.userLocation;
    if (unchanged) return;

    await controller.clearCircles();
    if (_disposed) return;

    final options = <CircleOptions>[];
    final data = <Map<String, dynamic>>[];
    if (config.userLocation case final point?) {
      options.add(
        CircleOptions(
          geometry: _latLng(point),
          circleRadius: 7,
          circleColor: _userColor,
          circleStrokeColor: _strokeColor,
          circleStrokeWidth: 3,
        ),
      );
      data.add(const {'kind': 'user'});
    }
    for (final marker in config.markers) {
      final selected = marker.id == config.selectedMarkerId;
      options.add(
        CircleOptions(
          geometry: _latLng(marker.point),
          circleRadius: selected ? 12 : 8,
          circleColor: marker.colorHex,
          circleStrokeColor: _strokeColor,
          circleStrokeWidth: selected ? 3 : 2,
        ),
      );
      data.add({'markerId': marker.id});
    }
    if (options.isNotEmpty) await controller.addCircles(options, data);
    if (_disposed) return;

    _appliedMarkers = config.markers;
    _appliedSelectedId = config.selectedMarkerId;
    _appliedUserLocation = config.userLocation;
  }

  static LatLng _latLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  @override
  Widget build(BuildContext context) {
    final camera = widget.config.initialCamera;
    return MapLibreMap(
      styleString: widget.styleUrl,
      initialCameraPosition: CameraPosition(
        target: _latLng(camera.target),
        zoom: camera.zoom,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onCameraIdle: _onCameraIdle,
      onMapClick: (_, _) => widget.config.onMapTapped?.call(),
      trackCameraPosition: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
    );
  }
}
