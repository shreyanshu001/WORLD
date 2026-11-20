import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:worlds/core/location/geolocator_location_service.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

void main() {
  group('formatDistance', () {
    test('rounds metres to tens and switches to kilometres', () {
      expect(formatDistance(3), '10 m');
      expect(formatDistance(88.8), '90 m');
      expect(formatDistance(994), '990 m');
      expect(formatDistance(1000), '1.0 km');
      expect(formatDistance(1449), '1.4 km');
      expect(formatDistance(9949), '9.9 km');
      expect(formatDistance(12400), '12 km');
    });
  });

  test('GeoPoint distance is close to the known London–Paris distance', () {
    const london = GeoPoint(latitude: 51.5074, longitude: -0.1278);
    const paris = GeoPoint(latitude: 48.8566, longitude: 2.3522);
    expect(london.distanceMetersTo(paris), closeTo(343500, 1500));
    expect(london.distanceMetersTo(london), 0);
  });

  test('geolocator permissions map to foreground-only statuses', () {
    expect(
      GeolocatorLocationService.mapPermission(LocationPermission.whileInUse),
      LocationPermissionStatus.granted,
    );
    expect(
      GeolocatorLocationService.mapPermission(LocationPermission.always),
      LocationPermissionStatus.granted,
    );
    expect(
      GeolocatorLocationService.mapPermission(LocationPermission.denied),
      LocationPermissionStatus.denied,
    );
    expect(
      GeolocatorLocationService.mapPermission(
        LocationPermission.unableToDetermine,
      ),
      LocationPermissionStatus.denied,
    );
    expect(
      GeolocatorLocationService.mapPermission(LocationPermission.deniedForever),
      LocationPermissionStatus.deniedForever,
    );
  });

  test('WorldPreview reads a nearby-search row', () {
    final world = WorldPreview.fromJson(const {
      'id': 'abc',
      'title': 'Harbor Story',
      'category': 'story',
      'latitude': -39.9992,
      'longitude': -120,
      'distance_meters': 88,
      'creator_username': 'alice',
      'creator_display_name': null,
    });

    expect(world.category, WorldCategory.story);
    expect(world.longitude, -120.0);
    expect(world.distanceMeters, 88.0);
    expect(world.creatorName, '@alice');
    expect(world.point, const GeoPoint(latitude: -39.9992, longitude: -120));
  });

  test('every category has a distinct icon and #RRGGBB colour', () {
    final hexes = WorldCategory.values.map((c) => c.colorHex).toSet();
    final icons = WorldCategory.values.map((c) => c.icon).toSet();
    expect(hexes, hasLength(WorldCategory.values.length));
    expect(icons, hasLength(WorldCategory.values.length));
    for (final hex in hexes) {
      expect(RegExp(r'^#[0-9A-F]{6}$').hasMatch(hex), isTrue, reason: hex);
    }
    expect(WorldCategory.story.colorHex, '#6A3FB5');
  });
}
