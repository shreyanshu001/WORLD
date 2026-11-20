import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';

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
  }) async {
    usePhoneScreen(tester);
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: user),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      play: play,
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
