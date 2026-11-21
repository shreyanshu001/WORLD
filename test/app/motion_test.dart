import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/shared/components/motion.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../support/explore_fakes.dart';
import '../support/fakes.dart';
import '../support/play_fakes.dart';
import '../support/pump_app.dart';

/// Motion (docs/UI_UX_SPECIFICATION.md): changes take a moment instead of
/// jumping, nothing loops, and a device set to remove animations gets none.
void main() {
  /// As Android reports "Remove animations".
  void removeAnimations(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  group('Motion.of', () {
    testWidgets('gives the duration, or none when animations are removed', (
      tester,
    ) async {
      late Duration normal;
      late Duration removed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              normal = Motion.of(context, Motion.standard);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: Builder(
                  builder: (context) {
                    removed = Motion.of(context, Motion.standard);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(normal, Motion.standard);
      expect(removed, Duration.zero);
    });
  });

  group('StateSwitcher', () {
    Widget host(Widget child, {bool animations = true}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !animations),
          child: Scaffold(body: StateSwitcher(child: child)),
        ),
      ),
    );

    testWidgets('fades the old child out while the new one comes in', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Text('one', key: ValueKey(1))));
      await tester.pumpWidget(host(const Text('two', key: ValueKey(2))));
      await tester.pump(const Duration(milliseconds: 50));

      // Part of the way through, both are on screen.
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);

      // It ends by itself: nothing loops.
      await tester.pumpAndSettle();
      expect(find.text('one'), findsNothing);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('the same key is the same thing, updated: no animation', (
      tester,
    ) async {
      await tester.pumpWidget(host(const Text('one', key: ValueKey(1))));
      await tester.pumpWidget(host(const Text('one, again', key: ValueKey(1))));

      expect(find.text('one'), findsNothing);
      expect(find.text('one, again'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with animations removed, the change is immediate', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const Text('one', key: ValueKey(1)), animations: false),
      );
      await tester.pumpWidget(
        host(const Text('two', key: ValueKey(2)), animations: false),
      );

      expect(find.text('one'), findsNothing);
      expect(find.text('two'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('PopIn', () {
    double scaleOf(WidgetTester tester) => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(PopIn),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .storage[0];

    Widget host({bool animations = true}) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !animations),
          child: const Center(child: PopIn(child: Icon(Icons.check))),
        ),
      ),
    );

    testWidgets('settles into place once, then stays', (tester) async {
      await tester.pumpWidget(host());
      expect(scaleOf(tester), lessThan(1));

      await tester.pumpAndSettle();
      expect(scaleOf(tester), closeTo(1, 0.001));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with animations removed, it is simply there', (tester) async {
      await tester.pumpWidget(host(animations: false));
      expect(scaleOf(tester), closeTo(1, 0.001));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('in the app', () {
    const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
    const center = GeoPoint(latitude: 51.5, longitude: -0.12);

    late FakeWorldRepository worlds;
    late FakeWorldPlayRepository play;

    setUp(() {
      worlds = FakeWorldRepository([
        testWorld(
          'w1',
          'Harbor Story',
          WorldCategory.story,
          distanceMeters: 89,
        ),
        testWorld('w2', 'Mural Walk', WorldCategory.art, distanceMeters: 300),
      ]);
      play = FakeWorldPlayRepository()
        ..addWorld('w1', testStoryBlocks(), unlocked: true);
    });

    Future<void> pump(WidgetTester tester) {
      usePhoneScreen(tester);
      return pumpWorldsApp(
        tester,
        auth: FakeAuthRepository(signedInAs: alice),
        profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
        worlds: worlds,
        play: play,
        exploreDefaultCenter: center,
      );
    }

    Future<void> openPlayer(WidgetTester tester) async {
      await pump(tester);
      unawaited(
        GoRouter.of(
          tester.element(find.byType(NavigationBar)),
        ).push<void>(AppRoutes.play('w1')),
      );
      await tester.pumpAndSettle();
    }

    /// Whether everything [finder] sits in has finished fading in.
    bool fullyShown(WidgetTester tester, Finder finder) => tester
        .widgetList<FadeTransition>(
          find.ancestor(of: finder, matching: find.byType(FadeTransition)),
        )
        .every((fade) => fade.opacity.value == 1);

    /// Pumps short frames until [finder] finds something.
    Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
      for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(finder, findsOneWidget);
    }

    testWidgets('selecting a World reveals its preview over a moment', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('marker-w1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The card is there at once (it can be read and tapped) and is still
      // arriving.
      expect(find.text('View details'), findsOneWidget);
      expect(fullyShown(tester, find.text('View details')), isFalse);

      await tester.pumpAndSettle();
      expect(find.text('View details'), findsOneWidget);
      expect(fullyShown(tester, find.text('View details')), isTrue);

      // Another World: the first card leaves as the second arrives.
      await tester.tap(find.byKey(const ValueKey('marker-w2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('View details'), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Mural Walk'), findsOneWidget);
    });

    testWidgets('with animations removed, the preview is simply there', (
      tester,
    ) async {
      removeAnimations(tester);
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('marker-w1')));
      await tester.pump();

      // In the first frame it is all there.
      expect(find.text('View details'), findsOneWidget);
      expect(fullyShown(tester, find.text('View details')), isTrue);

      // And the next World's card replaces it in one frame.
      await tester.tap(find.byKey(const ValueKey('marker-w2')));
      await tester.pump();
      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Mural Walk'), findsOneWidget);
      expect(fullyShown(tester, find.text('View details')), isTrue);
    });

    testWidgets('the next part of a World comes in as the last one leaves', (
      tester,
    ) async {
      await openPlayer(tester);
      expect(find.text('Two doors stand before you.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await pumpUntilFound(tester, find.text('Which door?'));
      await tester.pump(const Duration(milliseconds: 50));

      // Part of the way through the turn, both parts are on screen.
      expect(find.text('Two doors stand before you.'), findsOneWidget);
      expect(find.text('Which door?'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Two doors stand before you.'), findsNothing);
      expect(find.text('Which door?'), findsOneWidget);
    });

    testWidgets('with animations removed, the next part replaces the last', (
      tester,
    ) async {
      removeAnimations(tester);
      await openPlayer(tester);

      await tester.tap(find.text('Continue'));
      await pumpUntilFound(tester, find.text('Which door?'));

      // In the very frame the new part appears, the old one is gone.
      expect(find.text('Two doors stand before you.'), findsNothing);

      // And the World can still be finished.
      await tester.pumpAndSettle();
      await tester.tap(find.text('The left door'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('World complete'), findsOneWidget);
    });

    testWidgets('finishing a World is marked once, and then is still', (
      tester,
    ) async {
      await openPlayer(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The left door'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      await pumpUntilFound(tester, find.text('World complete'));
      expect(tester.hasRunningAnimations, isTrue);

      // Settling at all proves nothing on the screen loops.
      await tester.pumpAndSettle();
      expect(find.text('World complete'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
