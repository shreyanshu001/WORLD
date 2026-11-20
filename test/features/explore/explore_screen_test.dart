import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const center = GeoPoint(latitude: 51.5, longitude: -0.12);

  late FakeWorldRepository worlds;
  late FakeLocationService location;
  late FakeMapAdapter map;

  setUp(() {
    worlds = FakeWorldRepository([
      testWorld('w1', 'Harbor Story', WorldCategory.story, distanceMeters: 89),
      testWorld('w2', 'Lighthouse Puzzle', WorldCategory.puzzle),
      testWorld(
        'w3',
        'Mural Walk',
        WorldCategory.art,
        distanceMeters: 4000,
        creatorDisplayName: 'Mira',
        latitude: 51.53,
      ),
    ]);
    location = FakeLocationService();
    map = FakeMapAdapter();
  });

  Future<void> pumpExplore(WidgetTester tester, {GeoPoint? defaultCenter}) =>
      pumpWorldsApp(
        tester,
        auth: FakeAuthRepository(),
        worlds: worlds,
        location: location,
        map: map,
        exploreDefaultCenter: defaultCenter,
      );

  Finder marker(String id) => find.byKey(ValueKey('marker-$id'));

  group('opening Explore', () {
    testWidgets('with no default area, nothing is searched and location is '
        'not touched', (tester) async {
      await pumpExplore(tester);

      expect(
        find.textContaining('Tap the location button to find Worlds'),
        findsOneWidget,
      );
      expect(worlds.queries, isEmpty);
      expect(location.totalCalls, 0);
    });

    testWidgets('with a default area, it is searched without touching '
        'location', (tester) async {
      await pumpExplore(tester, defaultCenter: center);

      expect(worlds.queries, hasLength(1));
      expect(worlds.queries.single.center, center);
      expect(worlds.queries.single.radiusMeters, 5000);
      expect(marker('w1'), findsOneWidget);
      expect(marker('w2'), findsOneWidget);
      expect(marker('w3'), findsOneWidget);
      expect(location.totalCalls, 0);
    });

    testWidgets('the map attribution is always visible', (tester) async {
      await pumpExplore(tester, defaultCenter: center);

      expect(find.text(MapStyle.openFreeMap.attribution), findsOneWidget);

      await tester.tap(marker('w1'));
      await tester.pumpAndSettle();

      expect(find.text(MapStyle.openFreeMap.attribution), findsOneWidget);
    });
  });

  group('results', () {
    testWidgets('tapping a marker shows its preview; closing hides it', (
      tester,
    ) async {
      await pumpExplore(tester, defaultCenter: center);

      await tester.tap(marker('w1'));
      await tester.pumpAndSettle();

      expect(find.text('Harbor Story'), findsOneWidget);
      expect(find.text('Story · by @alice'), findsOneWidget);
      expect(find.text('90 m from the map centre'), findsOneWidget);
      expect(map.lastConfig!.selectedMarkerId, 'w1');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Harbor Story'), findsNothing);
      expect(map.lastConfig!.selectedMarkerId, isNull);
    });

    testWidgets('tapping empty map clears the selection', (tester) async {
      await pumpExplore(tester, defaultCenter: center);
      await tester.tap(marker('w3'));
      await tester.pumpAndSettle();
      expect(find.text('Art · by Mira'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('map-background')));
      await tester.pumpAndSettle();

      expect(find.text('Art · by Mira'), findsNothing);
    });

    testWidgets('a category chip searches again with that category', (
      tester,
    ) async {
      await pumpExplore(tester, defaultCenter: center);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Puzzle'));
      await tester.pumpAndSettle();

      expect(worlds.queries.last.category, WorldCategory.puzzle);
      expect(marker('w2'), findsOneWidget);
      expect(marker('w1'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(worlds.queries.last.category, isNull);
      expect(marker('w1'), findsOneWidget);
    });

    testWidgets('title search waits for typing to pause', (tester) async {
      await pumpExplore(tester, defaultCenter: center);
      final before = worlds.queries.length;

      await tester.enterText(find.byType(TextField), 'mural');
      await tester.pump(const Duration(milliseconds: 300));
      expect(worlds.queries.length, before);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(worlds.queries.length, before + 1);
      expect(worlds.queries.last.searchText, 'mural');
      expect(marker('w3'), findsOneWidget);
      expect(marker('w1'), findsNothing);
    });

    testWidgets('no results explain what to try next', (tester) async {
      worlds.worlds = [];
      await pumpExplore(tester, defaultCenter: center);

      expect(
        find.text('No Worlds within 5 km here yet. Try another area.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Art'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No Worlds within 5 km match. Try another category or search.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failed search can be retried', (tester) async {
      worlds.nextError = const AppFailure.offline();
      await pumpExplore(tester, defaultCenter: center);

      expect(
        find.text(
          "Couldn't load Worlds. You're offline. Check your connection and "
          'try again.',
        ),
        findsOneWidget,
      );
      expect(marker('w1'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(marker('w1'), findsOneWidget);
      expect(find.textContaining("Couldn't load Worlds"), findsNothing);
    });

    testWidgets('a slow earlier search cannot replace a newer one', (
      tester,
    ) async {
      worlds.holdResponses = true;
      await pumpWorldsApp(
        tester,
        auth: FakeAuthRepository(),
        worlds: worlds,
        location: location,
        map: map,
        exploreDefaultCenter: center,
        settle: false,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Puzzle'));
      await tester.pump();
      expect(worlds.held, hasLength(2));

      // The newer (puzzle) search answers first, then the older one.
      worlds.held[1].complete([worlds.worlds[1]]);
      await tester.pump();
      worlds.held[0].complete(worlds.worlds);
      await tester.pumpAndSettle();

      expect(marker('w2'), findsOneWidget);
      expect(marker('w1'), findsNothing);
      expect(marker('w3'), findsNothing);
    });
  });

  group('list view', () {
    testWidgets('shows the same results; choosing one shows it on the map', (
      tester,
    ) async {
      await pumpExplore(tester, defaultCenter: center);
      final searches = worlds.queries.length;

      await tester.tap(find.byTooltip('Show as list'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Harbor Story'), findsOneWidget);
      expect(
        find.text('Art · by Mira · 4.0 km from the map centre'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ListTile, 'Mural Walk'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Show as list'), findsOneWidget);
      expect(map.lastConfig!.selectedMarkerId, 'w3');
      expect(map.lastConfig!.cameraRequest?.target, worlds.worlds[2].point);
      // Moving the camera to the World is not a new search.
      expect(worlds.queries.length, searches);
    });
  });

  group('moving the map', () {
    testWidgets('searches the new area once the map settles', (tester) async {
      await pumpExplore(tester, defaultCenter: center);
      final before = worlds.queries.length;
      const elsewhere = GeoPoint(latitude: 51.6, longitude: -0.12);

      map.userMovesMapTo(elsewhere);
      await tester.pump(const Duration(milliseconds: 400));
      expect(worlds.queries.length, before);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(worlds.queries.length, before + 1);
      expect(worlds.queries.last.center, elsewhere);
    });

    testWidgets('small moves and zoomed-out views do not search', (
      tester,
    ) async {
      await pumpExplore(tester, defaultCenter: center);
      final before = worlds.queries.length;

      map.userMovesMapTo(const GeoPoint(latitude: 51.5005, longitude: -0.12));
      await tester.pump(const Duration(seconds: 1));
      map.userMovesMapTo(const GeoPoint(latitude: 40, longitude: 10), zoom: 5);
      await tester.pump(const Duration(seconds: 1));

      expect(worlds.queries.length, before);
    });
  });

  group('finding Worlds near me', () {
    testWidgets('asks permission, takes one reading, centres and searches '
        'there', (tester) async {
      await pumpExplore(tester);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();

      expect(location.permissionRequests, 1);
      expect(location.positionReads, 1);
      expect(worlds.queries.single.center, location.position);
      expect(map.lastConfig!.cameraRequest?.target, location.position);
      expect(map.lastConfig!.userLocation, location.position);
      expect(find.text('user location shown'), findsOneWidget);

      await tester.tap(marker('w1'));
      await tester.pumpAndSettle();
      expect(find.text('90 m away'), findsOneWidget);
    });

    testWidgets('does not ask again when permission is already granted', (
      tester,
    ) async {
      location.permission = LocationPermissionStatus.granted;
      await pumpExplore(tester);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();

      expect(location.permissionRequests, 0);
      expect(location.positionReads, 1);
    });

    testWidgets('when refused, says so and the map keeps working', (
      tester,
    ) async {
      location.requestResult = LocationPermissionStatus.denied;
      await pumpExplore(tester, defaultCenter: center);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Location was not allowed. You can still explore by moving the map.',
        ),
        findsOneWidget,
      );
      expect(location.positionReads, 0);
      expect(marker('w1'), findsOneWidget);

      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Location was not allowed'), findsNothing);
    });

    testWidgets('when blocked, opens app settings and retries on return', (
      tester,
    ) async {
      location.permission = LocationPermissionStatus.deniedForever;
      await pumpExplore(tester);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Location is blocked for WORLDS'), findsOne);
      expect(location.permissionRequests, 0);

      await tester.tap(find.widgetWithText(TextButton, 'Settings'));
      await tester.pumpAndSettle();
      expect(location.appSettingsOpened, 1);

      // The user allows location in Settings and comes back.
      location.permission = LocationPermissionStatus.granted;
      leaveAndReturnToApp(tester);
      await tester.pumpAndSettle();

      expect(location.positionReads, 1);
      expect(worlds.queries.single.center, location.position);
      expect(find.textContaining('Location is blocked'), findsNothing);
    });

    testWidgets('when location services are off, offers to turn them on', (
      tester,
    ) async {
      location.serviceEnabled = false;
      await pumpExplore(tester);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();

      expect(
        find.text('Location services are turned off on this device.'),
        findsOneWidget,
      );
      expect(location.permissionChecks, 0);

      await tester.tap(find.widgetWithText(TextButton, 'Turn on'));
      await tester.pumpAndSettle();
      expect(location.locationSettingsOpened, 1);
    });

    testWidgets('when no position arrives, offers to try again', (
      tester,
    ) async {
      location
        ..permission = LocationPermissionStatus.granted
        ..positionError = const AppFailure.locationUnavailable();
      await pumpExplore(tester);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();

      expect(find.text("We couldn't get your location."), findsOneWidget);
      expect(worlds.queries, isEmpty);

      location.positionError = null;
      await tester.tap(find.widgetWithText(TextButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(location.positionReads, 2);
      expect(worlds.queries.single.center, location.position);
    });
  });
}
