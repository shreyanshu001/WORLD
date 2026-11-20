import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
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
  late FakeWorldMediaRepository media;

  setUp(() {
    worlds = FakeWorldRepository([
      testWorld('w1', 'Harbor Story', WorldCategory.story, distanceMeters: 89),
    ]);
    worlds.detailsById['w1'] = testDetails(
      'w1',
      'Harbor Story',
      WorldCategory.story,
      coverPath: 'owner/w1/cover.jpg',
      blockCount: 4,
      unlockRadiusMeters: 75,
    );
    location = FakeLocationService();
    map = FakeMapAdapter();
    media = FakeWorldMediaRepository();
  });

  Future<void> pumpExplore(WidgetTester tester, {AuthUser? user}) {
    usePhoneScreen(tester);
    return pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: user),
      worlds: worlds,
      location: location,
      map: map,
      media: media,
      exploreDefaultCenter: center,
    );
  }

  Finder marker(String id) => find.byKey(ValueKey('marker-$id'));

  Future<void> openFromMarker(WidgetTester tester) async {
    await tester.tap(marker('w1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens from the map preview with safe details only', (
    tester,
  ) async {
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(find.text('Harbor Story'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('by Alice'), findsOneWidget);
    expect(find.text('A short walk along the harbour.'), findsOneWidget);
    expect(find.textContaining('Unlocks within 75 m'), findsOneWidget);
    expect(find.textContaining('4 parts'), findsOneWidget);
    expect(find.text('Show on map'), findsOneWidget);

    // No action that does not work yet.
    for (final label in ['Start', 'Unlock', 'Save', 'Share', 'Report']) {
      expect(find.widgetWithText(FilledButton, label), findsNothing);
      expect(find.widgetWithText(OutlinedButton, label), findsNothing);
      expect(find.widgetWithText(TextButton, label), findsNothing);
    }
    // Not the creator, so nothing to edit.
    expect(find.text('Edit World'), findsNothing);

    // The cover was requested; it failed, so the category panel shows.
    expect(media.requested, ['owner/w1/cover.jpg']);
    expect(worlds.detailsRequests.single.from, isNull);
  });

  testWidgets('without a shared location, says how to see the distance', (
    tester,
  ) async {
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(
      find.textContaining('Find Worlds near me" on Explore'),
      findsOneWidget,
    );
  });

  testWidgets('after locating, the server measures from the user', (
    tester,
  ) async {
    location.permission = LocationPermissionStatus.granted;
    worlds.detailsById['w1'] = testDetails(
      'w1',
      'Harbor Story',
      WorldCategory.story,
      distanceMeters: 1400,
    );
    await pumpExplore(tester);

    await tester.tap(find.byTooltip('Find Worlds near me'));
    await tester.pumpAndSettle();
    await openFromMarker(tester);

    expect(worlds.detailsRequests.single.from, location.position);
    expect(find.textContaining("You're 1.4 km away."), findsOneWidget);
  });

  testWidgets('opens from the list view', (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.byTooltip('Show as list'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View details of Harbor Story'));
    await tester.pumpAndSettle();

    expect(find.text('Show on map'), findsOneWidget);
    expect(worlds.detailsRequests.single.worldId, 'w1');
  });

  testWidgets('a World that is no longer available says so', (tester) async {
    worlds.detailsById.clear();
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(find.text("This World isn't available"), findsOneWidget);
    expect(find.text('Show on map'), findsNothing);
  });

  testWidgets('a failed load offers a retry that works', (tester) async {
    worlds.nextDetailsError = const AppFailure.offline();
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(find.text(const AppFailure.offline().userMessage), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Show on map'), findsOneWidget);
    expect(worlds.detailsRequests, hasLength(2));
  });

  testWidgets('"Show on map" returns to the map with the World selected', (
    tester,
  ) async {
    await pumpExplore(tester);
    await openFromMarker(tester);
    final queriesBefore = worlds.queries.length;

    await tester.tap(find.text('Show on map'));
    await tester.pumpAndSettle();

    expect(find.text('marker w1 (selected)'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(
      map.lastConfig!.cameraRequest!.target,
      const GeoPoint(latitude: 51.5, longitude: -0.12),
    );
    expect(worlds.queries.length, queriesBefore + 1);
  });

  testWidgets("the creator sees their World's status and can edit it", (
    tester,
  ) async {
    worlds.detailsById['w1'] = testDetails(
      'w1',
      'Harbor Story',
      WorldCategory.story,
      status: WorldStatus.published,
      isCreator: true,
    );
    await pumpExplore(tester, user: const AuthUser(id: 'alice-id'));
    await openFromMarker(tester);

    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Edit World'), findsOneWidget);
    expect(find.text('Show on map'), findsOneWidget);
  });
}
