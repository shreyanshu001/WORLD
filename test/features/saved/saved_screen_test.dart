import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/explore/presentation/explore_screen.dart';
import 'package:worlds/features/saved/domain/saved_world.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/community_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const bob = AuthUser(id: 'bob-id', email: 'bob@example.com');

  late FakeAuthRepository auth;
  late FakeSavedWorldsRepository saved;
  late FakeWorldRepository worlds;

  final harbour = testSaved('w1', 'Harbour Gate', distanceMeters: 1400);
  final mill = testSaved(
    'w2',
    'Old Mill',
    category: WorldCategory.puzzle,
    creator: 'cara',
    creatorDisplayName: null,
  );

  setUp(() {
    auth = FakeAuthRepository(signedInAs: alice)
      ..addAccount('bob@example.com', 'password1', bob);
    saved = FakeSavedWorldsRepository(
      currentUserId: () => auth.currentUser?.id,
    );
    worlds = FakeWorldRepository();
  });

  Future<void> openSaved(WidgetTester tester) async {
    usePhoneScreen(tester);
    await pumpWorldsApp(
      tester,
      auth: auth,
      profiles: FakeProfileRepository()
        ..add(testProfile(alice.id, 'alice'))
        ..add(testProfile(bob.id, 'bob')),
      worlds: worlds,
      saved: saved,
    );
    await tapTab(tester, 'Saved');
  }

  testWidgets('signed out, Saved offers sign-in and asks the server nothing', (
    tester,
  ) async {
    auth = FakeAuthRepository();
    saved = FakeSavedWorldsRepository(currentUserId: () => null);
    await openSaved(tester);

    expect(find.text('Save Worlds for later'), findsOneWidget);
    expect(saved.listRequests, isEmpty);
  });

  testWidgets('with nothing saved, it explains and leads back to the map', (
    tester,
  ) async {
    await openSaved(tester);

    expect(find.text('Nothing saved yet'), findsOneWidget);
    await tester.tap(find.text('Explore the map'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  testWidgets('lists saved Worlds with creator, category and distance', (
    tester,
  ) async {
    saved.seed(alice.id, [harbour, mill]);
    await openSaved(tester);

    expect(find.text('Harbour Gate'), findsOneWidget);
    expect(find.text('Story · by Alice · 1.4 km away'), findsOneWidget);
    expect(find.text('Old Mill'), findsOneWidget);
    expect(find.text('Puzzle · by @cara'), findsOneWidget);
    // No location was read for this: only one the user already shared.
    expect(saved.listRequests.single.from, isNull);
  });

  testWidgets('a saved World opens its details and comes back', (tester) async {
    saved.seed(alice.id, [harbour]);
    worlds.detailsById['w1'] = testDetails(
      'w1',
      'Harbour Gate',
      WorldCategory.story,
    ).copyWith(isSaved: true);
    await openSaved(tester);

    await tester.tap(find.text('Harbour Gate'));
    await tester.pumpAndSettle();
    expect(find.text('A short walk along the harbour.'), findsOneWidget);
    expect(find.byTooltip('Remove from saved'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Story · by Alice · 1.4 km away'), findsOneWidget);
  });

  testWidgets('removing takes the World out at once and tells the server', (
    tester,
  ) async {
    saved.seed(alice.id, [harbour, mill]);
    await openSaved(tester);

    await tester.tap(find.byTooltip('Remove Harbour Gate from saved'));
    await tester.pump();
    // Gone before the server has answered.
    expect(find.text('Harbour Gate'), findsNothing);
    await tester.pumpAndSettle();

    expect(saved.setRequests, [(worldId: 'w1', saved: false)]);
    expect(saved.savedByUser[alice.id]!.map((w) => w.id), ['w2']);
    expect(find.text('Old Mill'), findsOneWidget);
  });

  testWidgets('a removal the server refuses puts the World back and says so', (
    tester,
  ) async {
    saved.seed(alice.id, [harbour, mill]);
    await openSaved(tester);
    saved.nextSetError = const AppFailure.offline();

    await tester.tap(find.byTooltip('Remove Harbour Gate from saved'));
    await tester.pumpAndSettle();

    expect(find.text('Harbour Gate'), findsOneWidget);
    expect(
      find.textContaining("Couldn't remove Harbour Gate."),
      findsOneWidget,
    );
    // Still first in the list, where it was.
    expect(
      tester.getTopLeft(find.text('Harbour Gate')).dy,
      lessThan(tester.getTopLeft(find.text('Old Mill')).dy),
    );

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't remove"), findsNothing);
  });

  testWidgets('more saved Worlds load a page at a time', (tester) async {
    saved
      ..pageSize = 2
      ..seed(alice.id, [harbour, mill, testSaved('w3', 'Tide Clock')]);
    await openSaved(tester);

    expect(find.text('Tide Clock'), findsNothing);
    await tester.ensureVisible(find.text('Show more'));
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Tide Clock'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
    expect(saved.listRequests.map((r) => r.offset), [0, 2]);
  });

  testWidgets('a failed load offers a retry that works', (tester) async {
    saved
      ..seed(alice.id, [harbour])
      ..nextListError = const AppFailure.offline();
    await openSaved(tester);

    expect(find.textContaining("You're offline"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Harbour Gate'), findsOneWidget);
  });

  testWidgets('saved Worlds that are not published now are counted', (
    tester,
  ) async {
    saved
      ..seed(alice.id, [harbour])
      ..unavailable = 2;
    await openSaved(tester);

    expect(
      find.textContaining("2 saved Worlds aren't available at the moment"),
      findsOneWidget,
    );
  });

  testWidgets('one account never sees the saved list of another', (
    tester,
  ) async {
    saved.seed(alice.id, [harbour]);
    await openSaved(tester);
    expect(find.text('Harbour Gate'), findsOneWidget);

    await tapTab(tester, 'Profile');
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Sign out'));
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
    // Not awaited: the fake answers on the test clock, which only pumps move.
    unawaited(auth.signIn(email: 'bob@example.com', password: 'password1'));
    await tester.pumpAndSettle();

    await tapTab(tester, 'Saved');
    expect(find.text('Harbour Gate'), findsNothing);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(saved.savedByUser[bob.id], isEmpty);
  });

  test('a page of saved Worlds reads the server fields', () {
    final page = SavedPage.fromJson({
      'items': [
        {
          'id': 'w1',
          'title': 'Harbour Gate',
          'category': 'art',
          'creator_username': 'cara',
          'creator_display_name': null,
          'cover_path': 'u/w1/c.jpg',
          'distance_meters': 12,
          'saved_at': '2026-11-21T06:00:00+00:00',
        },
      ],
      'has_more': true,
      'unavailable': 3,
    });

    expect(page.items.single.category, WorldCategory.art);
    expect(page.items.single.creatorName, '@cara');
    expect(page.items.single.distanceMeters, 12.0);
    expect(page.items.single.coverPath, 'u/w1/c.jpg');
    expect(page.hasMore, isTrue);
    expect(page.unavailable, 3);
  });
}
