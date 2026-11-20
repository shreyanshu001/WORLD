import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/core/maps/maplibre_map_adapter.dart';

/// The map style in use. Overridden at startup when a custom style is
/// configured.
final mapStyleProvider = Provider<MapStyle>((ref) => MapStyle.openFreeMap);

final mapAdapterProvider = Provider<MapAdapter>(
  (ref) => MapLibreMapAdapter(style: ref.watch(mapStyleProvider)),
);
