import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/auth/domain/auth_repository.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../support/creation_fakes.dart';
import '../support/explore_fakes.dart';
import '../support/fakes.dart';
import '../support/play_fakes.dart';
import '../support/pump_app.dart';

/// The screens from Checkpoints 2 to 5 at the largest text size Android
/// offers (200%), on a common phone. A layout that overflows fails the test
/// by itself; the expectations only prove the screen was really reached.
///
/// The Checkpoint 6 screens are covered the same way in
/// `test/features/saved/large_text_test.dart`.
void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const center = GeoPoint(latitude: 51.5, longitude: -0.12);
  const place = GeoPoint(latitude: 51.5007, longitude: -0.1246);
  const longTitle = 'The Lighthouse Keeper and the Long Night';

  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeWorldRepository worlds;
  late FakeWorldAuthoringRepository authoring;
  late FakeMapAdapter map;
  late FakeLocationService location;
  late FakeWorldPlayRepository play;

  setUp(() {
    auth = FakeAuthRepository(signedInAs: alice);
    profiles = FakeProfileRepository()
      ..add(
        testProfile(
          alice.id,
          'alice',
          displayName: 'Alice of the Harbour',
          bio: 'Collects harbour stories and leaves them where they happened.',
        ),
      );
    worlds = FakeWorldRepository([
      testWorld(
        'w1',
        longTitle,
        WorldCategory.story,
        distanceMeters: 240,
        creatorDisplayName: 'Mira Chen',
      ),
      testWorld(
        'w2',
        'Riddle of the Old Mill',
        WorldCategory.puzzle,
        distanceMeters: 650,
      ),
      testWorld('w3', 'Harbour Mural', WorldCategory.art, distanceMeters: 1200),
    ]);
    worlds.detailsById['w1'] = testDetails(
      'w1',
      longTitle,
      WorldCategory.story,
      description:
          'Every night for forty years, someone kept this light burning. '
          'Follow the keeper\'s last log through the harbour and decide how '
          'their story ends.',
      distanceMeters: 240,
      blockCount: 7,
      unlockRadiusMeters: 50,
    ).copyWith(playStatus: PlayStatus.locked);
    authoring = FakeWorldAuthoringRepository();
    map = FakeMapAdapter();
    location = FakeLocationService();
    play = FakeWorldPlayRepository()
      ..addWorld('w1', testStoryBlocks(), title: longTitle, unlocked: true)
      ..addWorld(
        'w2',
        testPuzzleBlocks(),
        title: 'Riddle of the Old Mill',
        unlocked: true,
      )
      ..answers['p-q'] = 'keeper'
      ..successMessages['p-q'] = 'Right, the keeper! The light never went out.';
  });

  Future<void> pump(WidgetTester tester, {GeoPoint? defaultCenter = center}) {
    usePhoneScreen(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    return pumpWorldsApp(
      tester,
      auth: auth,
      profiles: profiles,
      worlds: worlds,
      authoring: authoring,
      map: map,
      location: location,
      play: play,
      exploreDefaultCenter: defaultCenter,
    );
  }

  /// Scrolls down the screen's list until [finder] is in view, as a reader
  /// would. A list builds its rows only as they come into view, so at this
  /// text size what is below the fold does not exist yet.
  Future<void> reach(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      // The screen's own list: the topmost thing that scrolls down the page
      // and is not the inside of a text field.
      final list = find.byElementPredicate((element) {
        final widget = element.widget;
        if (widget is! Scrollable ||
            widget.axisDirection != AxisDirection.down) {
          return false;
        }
        var insideField = false;
        element.visitAncestorElements((ancestor) {
          insideField = ancestor.widget is EditableText;
          return !insideField;
        });
        return !insideField;
      }).last;
      await tester.scrollUntilVisible(finder, 200, scrollable: list);
    }
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
  }

  /// Scrolls to [text], then taps it.
  Future<void> tapText(WidgetTester tester, String text) async {
    await reach(tester, find.text(text));
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('marker-w1')));
    await tester.pumpAndSettle();
    await tapText(tester, 'View details');
  }

  Future<void> openPlayer(WidgetTester tester, String worldId) async {
    await pump(tester);
    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(AppRoutes.play(worldId)),
    );
    await tester.pumpAndSettle();
  }

  group('Explore at 200% text', () {
    testWidgets('the map, a selected World and the list', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('marker-w1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('marker-w1')));
      await tester.pumpAndSettle();
      expect(find.text('View details'), findsOneWidget);
      expect(find.textContaining('The Lighthouse Keeper'), findsWidgets);

      await tester.tap(find.byTooltip('Show as list'));
      await tester.pumpAndSettle();
      expect(find.text('Riddle of the Old Mill'), findsOneWidget);
    });

    testWidgets('nothing found, with and without a filter', (tester) async {
      worlds.worlds = [];
      await pump(tester);
      expect(
        find.text('No Worlds within 5 km here yet. Try another area.'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Art', skipOffstage: false),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Art'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No Worlds within 5 km match. Try another category or search.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a search that failed', (tester) async {
      worlds.nextError = const AppFailure.offline();
      await pump(tester);
      expect(find.textContaining("Couldn't load Worlds"), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    });

    testWidgets('why location is asked for, and a refusal', (tester) async {
      location.requestResult = LocationPermissionStatus.denied;
      await pump(tester);

      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();
      expect(find.text('Find Worlds near you'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Not now'), findsOneWidget);

      await tapText(tester, 'Continue');
      expect(find.textContaining('Location was not allowed'), findsOneWidget);
    });

    testWidgets('location blocked', (tester) async {
      location.permission = LocationPermissionStatus.deniedForever;
      await pump(tester);
      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Location is blocked for WORLDS'), findsOne);
      expect(find.widgetWithText(TextButton, 'Settings'), findsOneWidget);
    });

    testWidgets('location services off', (tester) async {
      location.serviceEnabled = false;
      await pump(tester);
      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();
      expect(
        find.text('Location services are turned off on this device.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Turn on'), findsOneWidget);
    });

    testWidgets('no position in time', (tester) async {
      location
        ..permission = LocationPermissionStatus.granted
        ..positionError = const AppFailure.locationUnavailable();
      await pump(tester);
      await tester.tap(find.byTooltip('Find Worlds near me'));
      await tester.pumpAndSettle();
      expect(find.text("We couldn't get your location."), findsOneWidget);
    });
  });

  group('World details at 200% text', () {
    testWidgets('a locked World and every answer to checking the place', (
      tester,
    ) async {
      location.permission = LocationPermissionStatus.granted;
      await pump(tester);
      await openDetails(tester);
      expect(find.textContaining('Every night for forty years'), findsOne);

      await tapText(tester, 'Check my location');
      expect(find.text('Check again'), findsOneWidget);

      location.accuracyMeters = 250;
      await tapText(tester, 'Check again');
      expect(find.text('Check again'), findsOneWidget);

      location
        ..accuracyMeters = 8
        ..positionError = const AppFailure.locationUnavailable();
      await tapText(tester, 'Check again');
      expect(find.text('Check again'), findsOneWidget);

      location.positionError = null;
      play.nextUnlock = (fix) =>
          const Unlocked(progress: PlayProgress(completed: false));
      await tapText(tester, 'Check again');
      expect(find.text('Check again'), findsNothing);
    });

    testWidgets('location refused while unlocking', (tester) async {
      location.requestResult = LocationPermissionStatus.denied;
      await pump(tester);
      await openDetails(tester);
      await tapText(tester, 'Check my location');
      await tapText(tester, 'Continue');
      expect(find.textContaining('ocation'), findsWidgets);
    });

    testWidgets('signed out', (tester) async {
      auth = FakeAuthRepository();
      // The server reports no play status to someone who is signed out.
      worlds.detailsById['w1'] = worlds.detailsById['w1']!.copyWith(
        playStatus: null,
      );
      await pump(tester);
      await openDetails(tester);
      await reach(tester, find.text('Sign in to unlock'));
      expect(find.text('Sign in to unlock'), findsOneWidget);
    });

    testWidgets('a World that is gone', (tester) async {
      worlds.detailsById.clear();
      await pump(tester);
      await openDetails(tester);
      expect(find.text("This World isn't available"), findsOneWidget);
    });

    testWidgets('a World that failed to load', (tester) async {
      worlds.nextDetailsError = const AppFailure.offline();
      await pump(tester);
      await openDetails(tester);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets("the creator's own World", (tester) async {
      worlds.detailsById['w1'] = worlds.detailsById['w1']!.copyWith(
        isCreator: true,
      );
      await pump(tester);
      await openDetails(tester);
      expect(find.byTooltip('Edit World'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
    });
  });

  group('The player at 200% text', () {
    testWidgets('a story: text, then a choice', (tester) async {
      await openPlayer(tester, 'w1');
      await tapText(tester, 'Continue');
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('a puzzle: wrong, right, finished', (tester) async {
      await openPlayer(tester, 'w2');
      await tapText(tester, 'Continue');
      await tester.enterText(
        find.widgetWithText(TextField, 'Your answer'),
        'the cook',
      );
      await tester.pump();
      await tapText(tester, 'Check answer');

      await tester.enterText(
        find.widgetWithText(TextField, 'Your answer'),
        'keeper',
      );
      await tester.pump();
      await tapText(tester, 'Check answer');
      expect(
        find.text('Right, the keeper! The light never went out.'),
        findsOneWidget,
      );

      await tapText(tester, 'Continue');
      await tapText(tester, 'Finish');
      expect(find.text('Play again'), findsOneWidget);
    });

    testWidgets('a World that is not unlocked, and one that is gone', (
      tester,
    ) async {
      play.addWorld('locked', testStoryBlocks());
      await openPlayer(tester, 'locked');
      expect(find.text('Unlock this World first'), findsOneWidget);
    });

    testWidgets('a World that is gone', (tester) async {
      await openPlayer(tester, 'gone');
      expect(find.text("This World isn't available any more"), findsOneWidget);
    });

    testWidgets('a step that failed', (tester) async {
      await openPlayer(tester, 'w1');
      play.nextStepError = const AppFailure.offline();
      await tapText(tester, 'Continue');
      expect(find.textContaining('offline'), findsWidgets);
    });
  });

  group('Create at 200% text', () {
    testWidgets('nothing made yet', (tester) async {
      await pump(tester);
      await tapTab(tester, 'Create');
      await reach(tester, find.text('Start a World'));
      expect(find.text('Start a World'), findsOneWidget);
    });

    testWidgets('signed out', (tester) async {
      auth = FakeAuthRepository();
      await pump(tester);
      await tapTab(tester, 'Create');
      expect(find.textContaining('Sign in'), findsWidgets);
    });

    testWidgets('drafts and published Worlds', (tester) async {
      authoring.worlds['d1'] = const WorldDraft(
        id: 'd1',
        category: WorldCategory.story,
        title: 'Pier Ghost and the Missing Lantern',
      );
      authoring.worlds['p1'] = WorldDraft(
        id: 'p1',
        category: WorldCategory.art,
        title: 'Harbour Mural',
        status: WorldStatus.published,
        publishedAt: DateTime.utc(2026, 11, 18),
      );
      await pump(tester);
      await tapTab(tester, 'Create');
      await reach(tester, find.textContaining('Pier Ghost'));
      await reach(tester, find.text('Harbour Mural'));
    });

    testWidgets('every step of the editor', (tester) async {
      await pump(tester);
      await tapTab(tester, 'Create');
      await tapText(tester, 'Start a World');
      await tapText(tester, 'Story');
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        longTitle,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Follow the keeper\'s last log through the harbour.',
      );
      await tapText(tester, 'Save and continue');
      map.userMovesMapTo(place, zoom: 17);
      await tester.pumpAndSettle();
      await tapText(tester, 'Save and continue');
      await tapText(tester, 'Add a part');
      await tapText(tester, 'Text');
      await tester.enterText(
        find.widgetWithText(TextField, 'Text'),
        'The light was still warm when I found the log book.',
      );
      await tapText(tester, 'Add a part');
      await tapText(tester, 'Choice');
      await tapText(tester, '5. Publish');
      await reach(tester, find.text('Preview as an explorer'));
      expect(find.text('Preview as an explorer'), findsOneWidget);
    });

    testWidgets('a World ready to publish, and its preview', (tester) async {
      authoring.worlds['s1'] = const WorldDraft(
        id: 's1',
        category: WorldCategory.story,
        title: longTitle,
        description: 'Choose.',
        location: place,
        blocks: [
          ContentBlock.text(
            id: 'intro',
            body:
                'The light was still warm when I found the log book. The '
                'last entry was dated tonight.',
          ),
          ContentBlock.storyChoice(
            id: 'choice',
            prompt: 'Do you read the last page?',
            options: [
              StoryOption(
                id: 'o1',
                label: 'Read it now',
                destinationBlockId: 'left',
              ),
              StoryOption(
                id: 'o2',
                label: 'Climb the stairs first',
                destinationBlockId: 'right',
              ),
            ],
          ),
          ContentBlock.completion(
            id: 'left',
            title: 'The keeper\'s secret',
            message: 'L',
          ),
          ContentBlock.completion(
            id: 'right',
            title: 'Up the stairs',
            message: 'R',
          ),
        ],
      );
      await pump(tester);
      await tapTab(tester, 'Create');
      await tapText(tester, longTitle);
      await tapText(tester, '5. Publish');
      await tapText(tester, 'Preview as an explorer');
      await tapText(tester, 'Continue');
      expect(find.text('Climb the stairs first'), findsOneWidget);
    });
  });

  group('Accounts at 200% text', () {
    testWidgets('the signed-out profile and the sign-in form with errors', (
      tester,
    ) async {
      auth = FakeAuthRepository()
        ..addAccount('alice@example.com', 'password-a', alice);
      await pump(tester);
      await tapTab(tester, 'Profile');
      expect(find.text('Your profile'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await tapFilledButton(tester, 'Sign in');
      expect(find.text('Enter your email address.'), findsOneWidget);

      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Password', 'wrong-password');
      await tapFilledButton(tester, 'Sign in');
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('creating an account: errors, then "check your email"', (
      tester,
    ) async {
      auth = FakeAuthRepository()
        ..signUpOutcome = SignUpOutcome.confirmationRequired;
      await pump(tester);
      await tapTab(tester, 'Profile');
      await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
      await tester.pumpAndSettle();

      await enterField(tester, 'Username', 'no spaces');
      await enterField(tester, 'Email', 'nope');
      await enterField(tester, 'Password', '1');
      await tapFilledButton(tester, 'Create account');
      expect(
        find.text('Use only letters, numbers and underscores.'),
        findsOneWidget,
      );

      await enterField(tester, 'Username', 'carol');
      await enterField(tester, 'Email', 'carol.of.the.harbour@example.com');
      await enterField(tester, 'Password', 'long-enough');
      await tapFilledButton(tester, 'Create account');
      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('editing the profile, with an error', (tester) async {
      await pump(tester);
      await tapTab(tester, 'Profile');
      await tapText(tester, 'Edit profile');

      await enterField(tester, 'Username', 'no spaces');
      await tapFilledButton(tester, 'Save');
      expect(
        find.text('Use only letters, numbers and underscores.'),
        findsOneWidget,
      );
    });
  });
}
