import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/play_fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const center = GeoPoint(latitude: 51.5, longitude: -0.12);
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  late FakeWorldRepository worlds;
  late FakeLocationService location;
  late FakeMapAdapter map;
  late FakeWorldMediaRepository media;
  late FakeWorldPlayRepository play;

  WorldDetails details({
    PlayStatus? playStatus,
    double? distanceMeters,
    bool isCreator = false,
    WorldStatus status = WorldStatus.published,
  }) => testDetails(
    'w1',
    'Harbor Story',
    WorldCategory.story,
    coverPath: 'owner/w1/cover.jpg',
    blockCount: 4,
    unlockRadiusMeters: 75,
    distanceMeters: distanceMeters,
    isCreator: isCreator,
    status: status,
  ).copyWith(playStatus: playStatus);

  setUp(() {
    worlds = FakeWorldRepository([
      testWorld('w1', 'Harbor Story', WorldCategory.story, distanceMeters: 89),
    ]);
    worlds.detailsById['w1'] = details();
    location = FakeLocationService();
    map = FakeMapAdapter();
    media = FakeWorldMediaRepository();
    play = FakeWorldPlayRepository()..addWorld('w1', testStoryBlocks());
  });

  Future<void> pumpExplore(WidgetTester tester, {AuthUser? user}) {
    usePhoneScreen(tester);
    return pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: user),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      worlds: worlds,
      location: location,
      map: map,
      media: media,
      play: play,
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

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
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
    expect(find.text('75 m unlock radius'), findsOneWidget);
    expect(find.text('4 parts'), findsOneWidget);
    expect(find.byTooltip('Show on map'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);

    // Not the creator, so nothing to edit; Save, Share and Report do not
    // exist yet.
    expect(find.byTooltip('Edit World'), findsNothing);
    for (final label in ['Save', 'Share', 'Report']) {
      expect(find.text(label), findsNothing);
    }
    expect(media.requested, ['owner/w1/cover.jpg']);
    expect(worlds.detailsRequests.single.from, isNull);
  });

  testWidgets('signed out, the main action asks to sign in', (tester) async {
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(find.text('Sign in to unlock'), findsOneWidget);
    expect(find.textContaining('Sign in to unlock it.'), findsOneWidget);
    await tapText(tester, 'Sign in to unlock');
    expect(find.text('Sign in'), findsWidgets);
    expect(location.totalCalls, 0);
  });

  testWidgets('after locating, the server measures from the user', (
    tester,
  ) async {
    location.permission = LocationPermissionStatus.granted;
    worlds.detailsById['w1'] = details(distanceMeters: 1400);
    await pumpExplore(tester);

    await tester.tap(find.byTooltip('Find Worlds near me'));
    await tester.pumpAndSettle();
    await openFromMarker(tester);

    expect(worlds.detailsRequests.single.from, location.position);
    expect(find.textContaining("You're 1.4 km away."), findsOneWidget);
    expect(find.text('1.4 km away'), findsOneWidget);
  });

  testWidgets('opens from the list view', (tester) async {
    await pumpExplore(tester);
    await tester.tap(find.byTooltip('Show as list'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View details of Harbor Story'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show on map'), findsOneWidget);
    expect(worlds.detailsRequests.single.worldId, 'w1');
  });

  testWidgets('a World that is no longer available says so', (tester) async {
    worlds.detailsById.clear();
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(find.text("This World isn't available"), findsOneWidget);
    expect(find.byTooltip('Show on map'), findsNothing);
  });

  testWidgets('a failed load offers a retry that works', (tester) async {
    worlds.nextDetailsError = const AppFailure.offline();
    await pumpExplore(tester);
    await openFromMarker(tester);

    expect(find.text(const AppFailure.offline().userMessage), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show on map'), findsOneWidget);
    expect(worlds.detailsRequests, hasLength(2));
  });

  testWidgets('"Show on map" returns to the map with the World selected', (
    tester,
  ) async {
    await pumpExplore(tester);
    await openFromMarker(tester);
    final queriesBefore = worlds.queries.length;

    await tester.tap(find.byTooltip('Show on map'));
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
    worlds.detailsById['w1'] = details(
      isCreator: true,
      playStatus: PlayStatus.locked,
    );
    await pumpExplore(tester, user: alice);
    await openFromMarker(tester);

    expect(find.text('Published'), findsOneWidget);
    expect(find.byTooltip('Edit World'), findsOneWidget);
    expect(find.byTooltip('Show on map'), findsOneWidget);
  });

  group('unlocking on site', () {
    setUp(
      () => worlds.detailsById['w1'] = details(playStatus: PlayStatus.locked),
    );

    testWidgets('explains first; "Not now" reads nothing', (tester) async {
      await pumpExplore(tester, user: alice);
      await openFromMarker(tester);

      await tapText(tester, 'Check my location');
      expect(find.text('Unlock with your location'), findsOneWidget);
      await tapText(tester, 'Not now');

      expect(location.permissionRequests, 0);
      expect(location.positionReads, 0);
      expect(play.unlockFixes, isEmpty);
    });

    testWidgets('too far: says how far, and checking again works', (
      tester,
    ) async {
      location.permission = LocationPermissionStatus.granted;
      await pumpExplore(tester, user: alice);
      await openFromMarker(tester);

      await tapText(tester, 'Check my location');
      expect(location.positionReads, 1);
      expect(play.unlockFixes.single.accuracyMeters, 8);
      expect(
        find.textContaining("You're 240 m away. Get within 50 m"),
        findsOneWidget,
      );

      play.nextUnlock = (_) =>
          const Unlocked(progress: PlayProgress(completed: false));
      worlds.detailsById['w1'] = details(playStatus: PlayStatus.inProgress);
      await tapText(tester, 'Check again');

      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(location.positionReads, 2);
    });

    testWidgets('a vague reading is refused without asking the server', (
      tester,
    ) async {
      location
        ..permission = LocationPermissionStatus.granted
        ..accuracyMeters = 180;
      await pumpExplore(tester, user: alice);
      await openFromMarker(tester);

      await tapText(tester, 'Check my location');

      expect(
        find.textContaining('only accurate to about 180 m'),
        findsOneWidget,
      );
      expect(play.unlockFixes, isEmpty);
    });

    testWidgets('location refused: explains, and the map stays usable', (
      tester,
    ) async {
      location.requestResult = LocationPermissionStatus.denied;
      await pumpExplore(tester, user: alice);
      await openFromMarker(tester);

      await tapText(tester, 'Check my location');
      await tapText(tester, 'Continue');

      expect(
        find.textContaining('Location permission was refused'),
        findsOneWidget,
      );
      expect(location.positionReads, 0);
      expect(find.byTooltip('Show on map'), findsOneWidget);
    });

    testWidgets('once unlocked, Continue opens the player', (tester) async {
      worlds.detailsById['w1'] = details(playStatus: PlayStatus.inProgress);
      play.addWorld('w1', testStoryBlocks(), unlocked: true);
      await pumpExplore(tester, user: alice);
      await openFromMarker(tester);

      await tapText(tester, 'Continue');

      expect(find.text('Two doors stand before you.'), findsOneWidget);
      expect(find.text('PART 1 OF 5'), findsOneWidget);
    });

    testWidgets('a finished World offers to play again', (tester) async {
      worlds.detailsById['w1'] = details(playStatus: PlayStatus.completed);
      await pumpExplore(tester, user: alice);
      await openFromMarker(tester);

      expect(find.text('You finished this World'), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
    });
  });
}
