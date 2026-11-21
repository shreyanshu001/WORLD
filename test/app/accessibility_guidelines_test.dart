import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../support/community_fakes.dart';
import '../support/creation_fakes.dart';
import '../support/explore_fakes.dart';
import '../support/fakes.dart';
import '../support/play_fakes.dart';
import '../support/pump_app.dart';

/// What can be checked of TalkBack and contrast without a phone: Flutter's
/// Android accessibility guidelines on each main screen, in both themes.
///
/// - every control is at least 48 by 48 dp;
/// - every control has a name a screen reader can say;
/// - text stands out from what is behind it (WCAG 2 AA).
///
/// It does not replace listening to TalkBack on a device: it cannot tell
/// whether the names make sense or the reading order is right.
void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const center = GeoPoint(latitude: 51.5, longitude: -0.12);
  const place = GeoPoint(latitude: 51.5007, longitude: -0.1246);

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      late FakeAuthRepository auth;
      late FakeProfileRepository profiles;
      late FakeWorldRepository worlds;
      late FakeWorldAuthoringRepository authoring;
      late FakeMapAdapter map;
      late FakeLocationService location;
      late FakeWorldPlayRepository play;
      late FakeSavedWorldsRepository saved;

      setUp(() {
        auth = FakeAuthRepository(signedInAs: alice);
        profiles = FakeProfileRepository()
          ..add(
            testProfile(
              alice.id,
              'alice',
              displayName: 'Alice',
              bio: 'Collects harbour stories.',
            ),
          )
          ..add(testProfile('mira-id', 'mira', displayName: 'Mira Chen'))
          ..publishedByUsername['mira'] = [
            ProfileWorld(
              id: 'w1',
              title: 'The Lighthouse Keeper',
              category: WorldCategory.story,
              publishedAt: DateTime.utc(2025, 3, 9),
            ),
          ]
          ..publishedByUsername['alice'] = [
            ProfileWorld(
              id: 'w4',
              title: 'Market Walk',
              category: WorldCategory.experience,
              publishedAt: DateTime.utc(2025, 4),
            ),
          ]
          ..draftCounts['alice'] = 2
          ..discoveredCounts['alice'] = 7
          ..completedCounts['alice'] = 4;
        worlds = FakeWorldRepository([
          testWorld(
            'w1',
            'The Lighthouse Keeper',
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
          testWorld(
            'w3',
            'Harbour Mural',
            WorldCategory.art,
            distanceMeters: 1200,
          ),
          testWorld(
            'w4',
            'Market Walk',
            WorldCategory.experience,
            distanceMeters: 2100,
          ),
        ]);
        worlds.detailsById['w1'] =
            testDetails(
              'w1',
              'The Lighthouse Keeper',
              WorldCategory.story,
              description:
                  'Every night for forty years, someone kept this light '
                  'burning.',
              distanceMeters: 240,
              blockCount: 7,
              unlockRadiusMeters: 50,
            ).copyWith(
              creatorUsername: 'mira',
              creatorDisplayName: 'Mira Chen',
              playStatus: PlayStatus.locked,
            );
        authoring = FakeWorldAuthoringRepository();
        map = FakeMapAdapter();
        location = FakeLocationService()
          ..permission = LocationPermissionStatus.granted;
        play = FakeWorldPlayRepository()
          ..addWorld('w1', testStoryBlocks(), unlocked: true)
          ..addWorld('w2', testPuzzleBlocks(), unlocked: true)
          ..answers['p-q'] = 'keeper';
        saved = FakeSavedWorldsRepository(currentUserId: () => alice.id)
          ..seed(alice.id, [
            testSaved(
              'w1',
              'The Lighthouse Keeper',
              creator: 'mira',
              creatorDisplayName: 'Mira Chen',
              distanceMeters: 240,
            ),
            testSaved(
              'w2',
              'Riddle of the Old Mill',
              category: WorldCategory.puzzle,
              creator: 'jonas',
              creatorDisplayName: null,
              distanceMeters: 650,
            ),
          ]);
      });

      Future<SemanticsHandle> pump(WidgetTester tester) async {
        usePhoneScreen(tester);
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final handle = tester.ensureSemantics();
        await pumpWorldsApp(
          tester,
          auth: auth,
          profiles: profiles,
          worlds: worlds,
          authoring: authoring,
          map: map,
          location: location,
          play: play,
          saved: saved,
          exploreDefaultCenter: center,
        );
        expect(
          Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
          brightness,
        );
        return handle;
      }

      /// The three guidelines, on whatever is on screen now.
      Future<void> check(WidgetTester tester, String where) async {
        await tester.pumpAndSettle();
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: '$where: a control is smaller than 48 dp',
        );
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: '$where: a control has no name',
        );
        await expectLater(
          tester,
          meetsGuideline(textContrastGuideline),
          reason: '$where: text does not stand out',
        );
      }

      Future<void> tapText(WidgetTester tester, String text) async {
        await tester.ensureVisible(find.text(text).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(text).last);
        await tester.pumpAndSettle();
      }

      Future<void> push(WidgetTester tester, String route) async {
        unawaited(
          GoRouter.of(
            tester.element(find.byType(Scaffold).last),
          ).push<void>(route),
        );
        await tester.pumpAndSettle();
      }

      testWidgets('Explore: the map, a selected World and the list', (
        tester,
      ) async {
        final handle = await pump(tester);
        await check(tester, 'Explore');

        await tester.tap(find.byKey(const ValueKey('marker-w2')));
        await check(tester, 'Explore with a World selected');

        await tester.tap(find.byTooltip('Show as list'));
        await check(tester, 'Explore as a list');
        handle.dispose();
      });

      testWidgets('World details, locked and after checking the place', (
        tester,
      ) async {
        final handle = await pump(tester);
        await tester.tap(find.byKey(const ValueKey('marker-w1')));
        await tester.pumpAndSettle();
        await tapText(tester, 'View details');
        await check(tester, 'World details');

        await tapText(tester, 'Check my location');
        await check(tester, 'World details, too far away');
        handle.dispose();
      });

      testWidgets('the player: text, a choice, a question, the end', (
        tester,
      ) async {
        final handle = await pump(tester);
        await push(tester, AppRoutes.play('w1'));
        await check(tester, 'Player, text');
        await tapText(tester, 'Continue');
        await check(tester, 'Player, a choice');
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();

        await push(tester, AppRoutes.play('w2'));
        await tapText(tester, 'Continue');
        await check(tester, 'Player, a question');
        await tester.enterText(
          find.widgetWithText(TextField, 'Your answer'),
          'the cook',
        );
        await tester.pump();
        await tapText(tester, 'Check answer');
        await check(tester, 'Player, a wrong answer');
        await tester.enterText(
          find.widgetWithText(TextField, 'Your answer'),
          'keeper',
        );
        await tester.pump();
        await tapText(tester, 'Check answer');
        await check(tester, 'Player, a right answer');
        await tapText(tester, 'Continue');
        await tapText(tester, 'Finish');
        await check(tester, 'Player, finished');
        handle.dispose();
      });

      testWidgets('Create: the list and every step of the editor', (
        tester,
      ) async {
        authoring.worlds['d1'] = const WorldDraft(
          id: 'd1',
          category: WorldCategory.puzzle,
          title: 'Pier Ghost',
        );
        authoring.worlds['p1'] = WorldDraft(
          id: 'p1',
          category: WorldCategory.art,
          title: 'Harbour Mural',
          status: WorldStatus.published,
          publishedAt: DateTime.utc(2026, 11, 18),
        );
        final handle = await pump(tester);
        await tapTab(tester, 'Create');
        await check(tester, 'Create');

        await tester.tap(find.text('New World'));
        await tester.pumpAndSettle();
        await check(tester, 'Editor, type');
        await tapText(tester, 'Puzzle');
        await check(tester, 'Editor, type chosen');
        await tester.enterText(
          find.widgetWithText(TextField, 'Title'),
          'Riddle of the Old Mill',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Description'),
          'One question at the mill.',
        );
        await check(tester, 'Editor, details');
        await tapText(tester, 'Save and continue');
        map.userMovesMapTo(place, zoom: 17);
        await check(tester, 'Editor, place');
        await tapText(tester, 'Save and continue');
        await tapText(tester, 'Add a part');
        await check(tester, 'Editor, choosing a part');
        await tapText(tester, 'Question');
        await check(tester, 'Editor, content');
        await tapText(tester, '5. Publish');
        await check(tester, 'Editor, publish');
        handle.dispose();
      });

      testWidgets('Saved, reporting, a creator page and the profile', (
        tester,
      ) async {
        final handle = await pump(tester);
        await tapTab(tester, 'Saved');
        await check(tester, 'Saved');

        await tapText(tester, 'The Lighthouse Keeper');
        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
        await check(tester, 'World details, menu');
        await tapText(tester, 'Report this World');
        await check(tester, 'Report form');
        await tapText(tester, 'Unsafe or private place');
        await check(tester, 'Report form, a reason chosen');
        await tapText(tester, 'Send report');
        await check(tester, 'Report sent');
        await tapText(tester, 'Done');

        await push(tester, AppRoutes.creatorPage('mira'));
        await check(tester, 'Creator page');
        await tester.tap(find.byTooltip('Back').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back').last);
        await tester.pumpAndSettle();

        await tapTab(tester, 'Profile');
        await check(tester, 'Profile');
        await tapText(tester, 'Edit profile');
        await check(tester, 'Edit profile');
        handle.dispose();
      });

      testWidgets('signed out: the prompts, sign-in and registration', (
        tester,
      ) async {
        auth = FakeAuthRepository();
        final handle = await pump(tester);
        await tapTab(tester, 'Saved');
        await check(tester, 'Saved, signed out');
        await tapTab(tester, 'Create');
        await check(tester, 'Create, signed out');
        await tapTab(tester, 'Profile');
        await check(tester, 'Profile, signed out');

        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pumpAndSettle();
        await tapFilledButton(tester, 'Sign in');
        await check(tester, 'Sign in, with errors');
        await tester.tap(find.byTooltip('Back').last);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
        await tester.pumpAndSettle();
        await tapFilledButton(tester, 'Create account');
        await check(tester, 'Create account, with errors');
        handle.dispose();
      });
    });
  }
}
