import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/creation_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// What the first run on a real phone showed (Realme RMX5110, 360 by 797 dp,
/// 2026-11-21). The other widget tests use a 411 dp screen, which hid these.
void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const place = GeoPoint(latitude: 51.5007, longitude: -0.1246);

  late FakeMapAdapter map;

  /// A 360 by 797 dp phone.
  void useNarrowPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2392);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> openEditor(WidgetTester tester, {double textScale = 1}) async {
    useNarrowPhone(tester);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    map = FakeMapAdapter();
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: alice),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      authoring: FakeWorldAuthoringRepository(),
      map: map,
    );
    await tapTab(tester, 'Create');
    // The list builds its rows as they come into view.
    await tester.scrollUntilVisible(
      find.text('Start a World'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start a World'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseStory(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Story'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Story').last);
    await tester.pumpAndSettle();
  }

  Future<void> toPlaceStep(WidgetTester tester) async {
    await chooseStory(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Pier');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('step-location')));
    await tester.pumpAndSettle();
  }

  testWidgets('a category card says its name once, not twice', (tester) async {
    await openEditor(tester);

    // The name is written on the card, so the badge beside it stays silent.
    for (final badge in tester.widgetList<CategoryBadge>(
      find.byType(CategoryBadge),
    )) {
      expect(badge.named, isFalse);
    }
    final icon = tester.widget<Icon>(
      find
          .descendant(
            of: find.byType(CategoryBadge).first,
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(icon.semanticLabel, isNull);
  });

  testWidgets("the description's hint is not cut short", (tester) async {
    await openEditor(tester);
    await chooseStory(tester);

    // On the phone it needed two lines and had one. (The test font is about
    // twice as wide as the phone's, so only the allowance is checked here.)
    final hint = tester.renderObject<RenderParagraph>(
      find.text('What will people find? Needed before publishing.'),
    );
    expect(hint.maxLines, 2);
  });

  testWidgets('nothing covers the pin that marks the place', (tester) async {
    await openEditor(tester);
    await toPlaceStep(tester);
    map.userMovesMapTo(place, zoom: 17);
    await tester.pumpAndSettle();

    final pin = tester.getRect(find.byIcon(Icons.place));
    await tester.ensureVisible(find.text('Use my location'));
    await tester.pumpAndSettle();
    final button = tester.getRect(find.text('Use my location'));
    expect(pin.overlaps(button), isFalse);
    // The button is under the map, not on it.
    expect(button.top, greaterThanOrEqualTo(pin.bottom));
  });

  testWidgets('at 200% text the map still has room to show the pin', (
    tester,
  ) async {
    // An existing draft, opened straight at its place step.
    useNarrowPhone(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: alice),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      authoring: FakeWorldAuthoringRepository()
        ..worlds['d1'] = const WorldDraft(
          id: 'd1',
          category: WorldCategory.story,
          title: 'Pier',
          location: place,
        ),
      map: FakeMapAdapter(),
    );
    await tapTab(tester, 'Create');
    await tester.scrollUntilVisible(
      find.text('Pier'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Pier'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('step-location')));
    await tester.pumpAndSettle();

    final mapArea = tester.getSize(
      find
          .ancestor(of: find.byIcon(Icons.place), matching: find.byType(Stack))
          .first,
    );
    expect(mapArea.height, greaterThanOrEqualTo(200));
    // And the controls under it are still there to scroll to.
    expect(find.text('Use my location', skipOffstage: false), findsOneWidget);
  });
}
