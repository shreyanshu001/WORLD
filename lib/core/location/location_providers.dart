import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/location/geolocator_location_service.dart';
import 'package:worlds/core/location/location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
