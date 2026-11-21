import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/creation_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const place = GeoPoint(latitude: 51.5007, longitude: -0.1246);

  late FakeWorldAuthoringRepository authoring;
  late FakeMapAdapter map;
  late FakeLocationService location;
  late FakeWorldRepository worlds;

  setUp(() {
    authoring = FakeWorldAuthoringRepository();
    map = FakeMapAdapter();
    location = FakeLocationService();
    worlds = FakeWorldRepository();
  });

  Future<void> pumpCreator(WidgetTester tester) async {
    usePhoneScreen(tester);
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: alice),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      authoring: authoring,
      map: map,
      location: location,
      worlds: worlds,
    );
    await tapTab(tester, 'Create');
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.last);
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> typeInto(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> saveAndContinue(WidgetTester tester) async {
    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('a creator publishes a puzzle from start to finish', (
    tester,
  ) async {
    await pumpCreator(tester);
    expect(find.text('Create your first World'), findsOneWidget);

    await tapText(tester, 'Start a World');
    expect(find.text('What are you making?'), findsOneWidget);
    await tapText(tester, 'Puzzle');

    await typeInto(tester, 'Title', 'Lighthouse Riddle');
    await typeInto(tester, 'Description', 'A riddle by the old lighthouse.');
    await saveAndContinue(tester);
    expect(authoring.saves, hasLength(1));
    expect(find.textContaining('Move the map and zoom in'), findsOneWidget);
    expect(location.totalCalls, 0);

    map.userMovesMapTo(place, zoom: 17);
    await tester.pumpAndSettle();
    expect(find.text('area 50 m'), findsOneWidget);
    await saveAndContinue(tester);

    await tapText(tester, 'Add a part');
    await tapText(tester, 'Question');
    await typeInto(tester, 'Question', 'Who kept the light?');
    await typeInto(tester, 'Accepted answer', 'The keeper');
    expect(find.text('Will be stored when you save.'), findsOneWidget);
    await saveAndContinue(tester);

    // The answer went to the server once and left the screen.
    expect(authoring.storedAnswers.values, ['The keeper']);
    expect(find.text('The keeper'), findsNothing);
    expect(find.text('Everything needed is in place.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Publish'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    final publish = find.ancestor(
      of: find.text('Publish'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );
    await tester.ensureVisible(publish);
    expect(tester.widget<FilledButton>(publish).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(publish);
    await tester.pumpAndSettle();

    expect(authoring.publishes, hasLength(1));
    expect(find.text('Your World is live'), findsOneWidget);
    expect(find.text('Published. Your World is on the map.'), findsOneWidget);
    final worldId = authoring.publishes.single;
    expect(authoring.worlds[worldId]!.status, WorldStatus.published);

    await tapText(tester, 'View on map');
    expect(map.lastConfig!.cameraRequest!.target, place);
    expect(worlds.queries.last.center, place);
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await pumpCreator(tester);
    await tapText(tester, 'Start a World');
    await tapText(tester, 'Story');
    await typeInto(tester, 'Title', 'Pier Ghost');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Save your changes?'), findsOneWidget);

    await tapText(tester, 'Keep editing');
    expect(find.text('Pier Ghost'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapText(tester, 'Discard');
    expect(find.text('Create your first World'), findsOneWidget);
    expect(authoring.saves, isEmpty);
  });

  testWidgets('tapping the Create tab again asks before dropping changes', (
    tester,
  ) async {
    await pumpCreator(tester);
    await tapText(tester, 'Start a World');
    await tapText(tester, 'Story');
    await typeInto(tester, 'Title', 'Pier Ghost');

    // The active tab returns to its first screen, which would close the
    // editor without its back-navigation guard.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Create'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save your changes?'), findsOneWidget);

    await tapText(tester, 'Keep editing');
    expect(find.text('Pier Ghost'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Create'),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Save');
    expect(authoring.saves.single.draft.title, 'Pier Ghost');
    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('Pier Ghost'), findsOneWidget);
  });

  testWidgets('"Use my location" explains first, and "Not now" reads nothing', (
    tester,
  ) async {
    await pumpCreator(tester);
    await tapText(tester, 'Start a World');
    await tapText(tester, 'Art');
    await typeInto(tester, 'Title', 'Harbour Mural');
    await saveAndContinue(tester);

    await tapText(tester, 'Use my location');
    expect(find.text('Use your location'), findsOneWidget);
    await tapText(tester, 'Not now');

    expect(location.permissionRequests, 0);
    expect(location.positionReads, 0);
  });

  testWidgets('your Worlds are listed by state and open in the editor', (
    tester,
  ) async {
    authoring.worlds['d1'] = const WorldDraft(
      id: 'd1',
      category: WorldCategory.story,
      title: 'Pier Ghost',
    );
    authoring.worlds['p1'] = WorldDraft(
      id: 'p1',
      category: WorldCategory.art,
      title: 'Harbour Mural',
      status: WorldStatus.published,
      publishedAt: DateTime.utc(2026, 11, 20),
    );
    await pumpCreator(tester);

    expect(find.text('Drafts'), findsOneWidget);
    // The section header, and the status pill on the card.
    expect(find.text('Published'), findsNWidgets(2));
    expect(find.text('Pier Ghost'), findsOneWidget);

    await tapText(tester, 'Harbour Mural');
    expect(find.text('Edit World'), findsOneWidget);
    expect(find.textContaining('Published · Saved'), findsOneWidget);
    expect(find.text('Content'), findsWidgets);
  });

  testWidgets('what blocks publishing is listed, with a way to fix it', (
    tester,
  ) async {
    authoring.worlds['d1'] = const WorldDraft(
      id: 'd1',
      category: WorldCategory.story,
      title: 'Pier Ghost',
      location: place,
      blocks: [ContentBlock.text(id: 't1', body: 'Fog rolls in.')],
    );
    await pumpCreator(tester);
    await tapText(tester, 'Pier Ghost');
    await tapText(tester, '5. Publish');

    expect(find.text('Add a description.'), findsOneWidget);
    await tapText(tester, 'Fix');
    expect(find.text('Tell people what it is'), findsOneWidget);
  });

  testWidgets('the preview follows choices like an explorer would', (
    tester,
  ) async {
    authoring.worlds['s1'] = const WorldDraft(
      id: 's1',
      category: WorldCategory.story,
      title: 'Two Paths',
      description: 'Choose.',
      location: place,
      blocks: [
        ContentBlock.text(id: 'intro', body: 'You reach a fork.'),
        ContentBlock.storyChoice(
          id: 'choice',
          prompt: 'Which way?',
          options: [
            StoryOption(id: 'o1', label: 'Left', destinationBlockId: 'left'),
            StoryOption(id: 'o2', label: 'Right', destinationBlockId: 'right'),
          ],
        ),
        ContentBlock.completion(id: 'left', title: 'Left ending', message: 'L'),
        ContentBlock.completion(
          id: 'right',
          title: 'Right ending',
          message: 'R',
        ),
      ],
    );
    await pumpCreator(tester);
    await tapText(tester, 'Two Paths');
    await tapText(tester, '5. Publish');
    await tapText(tester, 'Preview as an explorer');

    expect(find.text('You reach a fork.'), findsOneWidget);
    await tapText(tester, 'Continue');
    expect(find.text('Which way?'), findsOneWidget);
    await tapText(tester, 'Right');
    expect(find.text('Right ending'), findsOneWidget);
    expect(find.text('Part 4 of 4'), findsOneWidget);

    await tapText(tester, 'Back');
    expect(find.text('Which way?'), findsOneWidget);
    await tapText(tester, 'Left');
    await tapText(tester, 'Finish');
    expect(find.text('End of the preview'), findsOneWidget);
  });
}
