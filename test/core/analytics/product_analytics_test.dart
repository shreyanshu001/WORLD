import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/analytics/analytics_providers.dart';
import 'package:worlds/core/analytics/product_analytics.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/analytics_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/play_fakes.dart';
import '../../support/pump_app.dart';

class _ThrowingSink implements ProductEventSink {
  int calls = 0;

  @override
  Future<void> send({
    required String sessionId,
    required String name,
    String? worldId,
    String? outcome,
  }) {
    calls++;
    throw StateError('no network');
  }
}

void main() {
  group('ProductAnalytics', () {
    test(
      'sends each kind of event with the launch id and nothing else',
      () async {
        final sink = FakeProductEventSink();
        ProductAnalytics(sink: sink, sessionId: 'launch-1')
          ..exploreOpened()
          ..worldSelected()
          ..detailsOpened('w1')
          ..unlockAttempted('w1', UnlockOutcome.tooFar);
        await Future<void>.delayed(Duration.zero);

        expect(sink.sent, [
          (name: 'explore_opened', worldId: null, outcome: null),
          (name: 'world_marker_selected', worldId: null, outcome: null),
          (name: 'world_details_opened', worldId: 'w1', outcome: null),
          (name: 'world_unlock_attempted', worldId: 'w1', outcome: 'too_far'),
        ]);
        expect(sink.sessionIds, {'launch-1'});
      },
    );

    test('Explore counts once per launch and details once per World', () async {
      final sink = FakeProductEventSink();
      ProductAnalytics(sink: sink, sessionId: 's')
        ..exploreOpened()
        ..exploreOpened()
        ..detailsOpened('w1')
        ..detailsOpened('w1')
        ..detailsOpened('w2')
        ..unlockAttempted('w1', UnlockOutcome.tooFar)
        ..unlockAttempted('w1', UnlockOutcome.unlocked);
      await Future<void>.delayed(Duration.zero);

      expect(sink.names, [
        'explore_opened',
        'world_details_opened',
        'world_details_opened',
        'world_unlock_attempted',
        'world_unlock_attempted',
      ]);
    });

    test('a sink that fails never reaches the caller', () async {
      final sink = _ThrowingSink();
      final analytics = ProductAnalytics(sink: sink, sessionId: 's');

      expect(analytics.exploreOpened, returnsNormally);
      expect(() => analytics.detailsOpened('w1'), returnsNormally);
      await Future<void>.delayed(Duration.zero);
      expect(sink.calls, 2);
    });

    test('a backend that was never started cannot break a screen', () async {
      // Screens read the provider while they are built. Without a client,
      // that read still succeeds and the event is quietly lost.
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith(
            (ref) => throw StateError('Supabase was not started'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final analytics = container.read(productAnalyticsProvider);
      expect(analytics.exploreOpened, returnsNormally);
      expect(
        () => analytics.unlockAttempted('w1', UnlockOutcome.failed),
        returnsNormally,
      );
      await Future<void>.delayed(Duration.zero);
    });

    test('unlock outcomes use the names the database accepts', () {
      expect(UnlockOutcome.values.map((o) => o.wire), [
        'unlocked',
        'too_far',
        'inaccurate',
        'no_location',
        'failed',
      ]);
    });
  });

  group('in the app', () {
    const center = GeoPoint(latitude: 51.5, longitude: -0.12);
    const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

    late FakeProductEventSink events;
    late FakeWorldRepository worlds;
    late FakeLocationService location;
    late FakeWorldPlayRepository play;

    WorldDetails details({bool isCreator = false}) => testDetails(
      'w1',
      'Harbor Story',
      WorldCategory.story,
      isCreator: isCreator,
    ).copyWith(playStatus: PlayStatus.locked);

    setUp(() {
      events = FakeProductEventSink();
      worlds = FakeWorldRepository([
        testWorld(
          'w1',
          'Harbor Story',
          WorldCategory.story,
          distanceMeters: 89,
        ),
        testWorld('w2', 'Mural Walk', WorldCategory.art, distanceMeters: 300),
      ])..detailsById['w1'] = details();
      location = FakeLocationService();
      play = FakeWorldPlayRepository()..addWorld('w1', testStoryBlocks());
    });

    Future<void> pump(WidgetTester tester) {
      usePhoneScreen(tester);
      return pumpWorldsApp(
        tester,
        auth: FakeAuthRepository(signedInAs: alice),
        profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
        worlds: worlds,
        location: location,
        play: play,
        events: events,
        exploreDefaultCenter: center,
      );
    }

    Future<void> openDetails(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('marker-w1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
    }

    testWidgets('opening the app, selecting a World and opening its details', (
      tester,
    ) async {
      await pump(tester);
      expect(events.names, ['explore_opened']);

      await openDetails(tester);
      expect(events.names, [
        'explore_opened',
        'world_marker_selected',
        'world_details_opened',
      ]);
      expect(events.sent.last.worldId, 'w1');

      // Tapping the same marker again, and details loading again, add nothing.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('marker-w1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(events.names, hasLength(3));
      expect(events.sessionIds, hasLength(1));
    });

    testWidgets('a creator opening their own World is not counted', (
      tester,
    ) async {
      worlds.detailsById['w1'] = details(isCreator: true);
      await pump(tester);
      await openDetails(tester);

      expect(events.names, isNot(contains('world_details_opened')));
    });

    testWidgets('unlock attempts record how they ended and nothing else', (
      tester,
    ) async {
      location.permission = LocationPermissionStatus.granted;
      await pump(tester);
      await openDetails(tester);

      await tester.tap(find.text('Check my location'));
      await tester.pumpAndSettle();
      expect(events.sent.last, (
        name: 'world_unlock_attempted',
        worldId: 'w1',
        outcome: 'too_far',
      ));

      location.accuracyMeters = 250;
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(events.sent.last.outcome, 'inaccurate');

      location
        ..accuracyMeters = 8
        ..positionError = const AppFailure.locationUnavailable();
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(events.sent.last.outcome, 'no_location');

      location.positionError = null;
      play.nextUnlock = (fix) =>
          const Unlocked(progress: PlayProgress(completed: false));
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(events.sent.last.outcome, 'unlocked');

      // Nothing sent anywhere carries a coordinate or a distance.
      for (final event in events.sent) {
        expect('${event.worldId} ${event.outcome}', isNot(contains('51.5')));
      }
    });

    testWidgets('a dead analytics server changes nothing the user sees', (
      tester,
    ) async {
      events.error = const AppFailure.offline();
      await pump(tester);
      await openDetails(tester);

      expect(find.text('Harbor Story'), findsWidgets);
      expect(find.text('Check my location'), findsOneWidget);
      expect(events.sent, isEmpty);
    });
  });
}
