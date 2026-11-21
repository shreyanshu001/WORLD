import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';

import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/play_fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  late FakeWorldPlayRepository play;

  setUp(() {
    play = FakeWorldPlayRepository()
      ..addWorld('story', testStoryBlocks(), unlocked: true)
      ..addWorld(
        'puzzle',
        testPuzzleBlocks(),
        title: 'Keeper Riddle',
        unlocked: true,
      )
      ..answers['p-q'] = 'keeper'
      ..successMessages['p-q'] = 'Right, the keeper!';
  });

  Future<void> openPlayer(
    WidgetTester tester,
    String worldId, {
    AuthUser? user = alice,
    FakeWorldMediaRepository? media,
  }) async {
    usePhoneScreen(tester);
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: user),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      play: play,
      media: media,
    );
    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(AppRoutes.play(worldId)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('a story plays part by part, follows a choice and finishes', (
    tester,
  ) async {
    await openPlayer(tester, 'story');

    expect(find.text('Two Doors'), findsOneWidget);
    expect(find.text('PART 1 OF 5'), findsOneWidget);
    expect(find.text('Two doors stand before you.'), findsOneWidget);

    await tapText(tester, 'Continue');
    expect(find.text('Which door?'), findsOneWidget);
    // A choice has no Continue: the reader picks an option.
    expect(find.text('Continue'), findsNothing);

    await tapText(tester, 'The right door');
    expect(play.steps.last, (from: 'choice', option: 'o-right'));
    expect(find.text('A long corridor.'), findsOneWidget);

    await tapText(tester, 'Continue');
    expect(find.text('The library'), findsOneWidget);
    await tapText(tester, 'Finish');

    expect(find.text('World complete'), findsOneWidget);
    expect(find.text('You finished Two Doors.'), findsOneWidget);
    expect(play.progress['story']!.path, [
      'intro',
      'choice',
      'right',
      'right-end',
    ]);

    await tapText(tester, 'Play again');
    expect(find.text('Two doors stand before you.'), findsOneWidget);
  });

  testWidgets('picture and artwork parts show with the images they use', (
    tester,
  ) async {
    final media = FakeWorldMediaRepository();
    play
      ..addWorld(
        'gallery',
        testGalleryBlocks(),
        title: 'Harbour Walk',
        unlocked: true,
      )
      ..assetPathsByWorld['gallery'] = {
        'a-photo': 'u/gallery/a-photo.jpg',
        'a-art': 'u/gallery/a-art.jpg',
      };
    await openPlayer(tester, 'gallery', media: media);

    expect(find.text('The quay'), findsOneWidget);
    expect(media.requested, contains('u/gallery/a-photo.jpg'));

    await tapText(tester, 'Continue');
    expect(find.text('Harbour Mural'), findsOneWidget);
    expect(find.text('Painted by the fishing crews.'), findsOneWidget);
    expect(media.requested, contains('u/gallery/a-art.jpg'));

    await tapText(tester, 'Continue');
    expect(find.text('The end'), findsOneWidget);
    await tapText(tester, 'Finish');
    expect(find.text('World complete'), findsOneWidget);
  });

  testWidgets('a puzzle checks answers on the server and never reveals them', (
    tester,
  ) async {
    await openPlayer(tester, 'puzzle');
    await tapText(tester, 'Continue');

    expect(find.text('Who lived here?'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tapText(tester, 'Show hint');
    expect(find.text('One word'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Your answer'),
      'the cook',
    );
    await tester.pump();
    await tapText(tester, 'Check answer');
    expect(find.text('Not quite. 4 tries left for now.'), findsOneWidget);
    expect(find.textContaining('keeper'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Your answer'),
      ' Keeper ',
    );
    await tester.pump();
    await tapText(tester, 'Check answer');
    expect(find.text('Right, the keeper!'), findsOneWidget);
    expect(play.submitted, ['the cook', ' Keeper ']);

    await tapText(tester, 'Continue');
    expect(find.text('Solved'), findsOneWidget);
  });

  testWidgets('too many wrong answers pause the question', (tester) async {
    play.wrongAttempts['p-q'] = 5;
    await openPlayer(tester, 'puzzle');
    await tapText(tester, 'Continue');

    await tester.enterText(
      find.widgetWithText(TextField, 'Your answer'),
      'keeper',
    );
    await tester.pump();
    await tapText(tester, 'Check answer');

    expect(find.text('Too many tries. Try again in 7 min.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Check answer'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the pause after too many tries ends by itself', (tester) async {
    play.wrongAttempts['p-q'] = 5;
    await openPlayer(tester, 'puzzle');
    await tapText(tester, 'Continue');
    await tester.enterText(
      find.widgetWithText(TextField, 'Your answer'),
      'keeper',
    );
    await tester.pump();
    await tapText(tester, 'Check answer');
    expect(find.text('Too many tries. Try again in 7 min.'), findsOneWidget);

    // Seven minutes later the server accepts answers again.
    play.wrongAttempts['p-q'] = 0;
    await tester.pump(const Duration(minutes: 7));
    await tester.pumpAndSettle();

    expect(find.textContaining('Too many tries'), findsNothing);
    await tapText(tester, 'Check answer');
    expect(find.text('Right, the keeper!'), findsOneWidget);
  });

  testWidgets('a failed step can be tried again without losing the place', (
    tester,
  ) async {
    play.nextStepError = const AppFailure.offline();
    await openPlayer(tester, 'story');

    await tapText(tester, 'Continue');
    expect(find.textContaining("That didn't go through."), findsOneWidget);
    expect(find.text('Two doors stand before you.'), findsOneWidget);

    await tapText(tester, 'Continue');
    expect(find.text('Which door?'), findsOneWidget);
  });

  testWidgets('if the server had already moved on, the player catches up', (
    tester,
  ) async {
    await openPlayer(tester, 'story');
    expect(play.loads, 1);
    play.nextStepStale = true;

    await tapText(tester, 'Continue');

    expect(play.loads, 2);
    expect(find.text('Two doors stand before you.'), findsOneWidget);
  });

  testWidgets('a failed catch-up is reported and can be tried again', (
    tester,
  ) async {
    await openPlayer(tester, 'story');
    play
      ..nextStepStale = true
      ..nextLoadError = const AppFailure.offline();

    await tapText(tester, 'Continue');
    expect(find.textContaining("That didn't go through."), findsOneWidget);
    expect(find.text('Two doors stand before you.'), findsOneWidget);

    await tapText(tester, 'Continue');
    expect(find.text('Which door?'), findsOneWidget);
  });

  testWidgets('if the creator changed the World, the player loads it again', (
    tester,
  ) async {
    await openPlayer(tester, 'story');
    expect(play.loads, 1);
    // The creator adds a part after the first one.
    play.blocksByWorld['story'] = [
      testStoryBlocks().first,
      const ContentBlock.text(id: 'bridge', body: 'A bridge appears.'),
      ...testStoryBlocks().skip(1),
    ];

    await tapText(tester, 'Continue');

    expect(play.loads, 2);
    expect(find.text('A bridge appears.'), findsOneWidget);
    expect(find.text('PART 2 OF 6'), findsOneWidget);
  });

  testWidgets('a place the app cannot show offers to load again', (
    tester,
  ) async {
    play.progress['story'] = const PlayProgress(
      completed: false,
      currentBlockId: 'gone',
    );
    await openPlayer(tester, 'story');
    expect(find.textContaining('We lost your place'), findsOneWidget);

    play.progress['story'] = const PlayProgress(
      completed: false,
      currentBlockId: 'intro',
      path: ['intro'],
    );
    await tapText(tester, 'Try again');
    expect(find.text('Two doors stand before you.'), findsOneWidget);
  });

  testWidgets('a failed Play again says so and can be tried again', (
    tester,
  ) async {
    await openPlayer(tester, 'story');
    await tapText(tester, 'Continue');
    await tapText(tester, 'The left door');
    await tapText(tester, 'Finish');
    expect(find.text('World complete'), findsOneWidget);

    play.nextRestartError = const AppFailure.offline();
    await tapText(tester, 'Play again');
    expect(find.textContaining("That didn't go through."), findsOneWidget);
    expect(find.text('World complete'), findsOneWidget);

    await tapText(tester, 'Play again');
    expect(find.text('Two doors stand before you.'), findsOneWidget);
  });

  testWidgets('a World not unlocked yet says so', (tester) async {
    play.addWorld('locked', testStoryBlocks());
    await openPlayer(tester, 'locked');

    expect(find.text('Unlock this World first'), findsOneWidget);
  });

  testWidgets('an unpublished World says so', (tester) async {
    await openPlayer(tester, 'gone');

    expect(find.text("This World isn't available any more"), findsOneWidget);
  });

  testWidgets('progress is the server\'s: reopening resumes where it was', (
    tester,
  ) async {
    await openPlayer(tester, 'story');
    await tapText(tester, 'Continue');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(AppRoutes.play('story')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Which door?'), findsOneWidget);
    expect(find.text('PART 2 OF 5'), findsOneWidget);
  });
}
