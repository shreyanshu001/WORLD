import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeWorldRepository worlds;

  ProfileWorld world(String id, String title) => ProfileWorld(
    id: id,
    title: title,
    category: WorldCategory.art,
    publishedAt: DateTime.utc(2025, 3, 9),
  );

  setUp(() {
    auth = FakeAuthRepository(signedInAs: alice);
    profiles = FakeProfileRepository()
      ..add(testProfile(alice.id, 'alice', displayName: 'Alice'))
      ..add(
        testProfile(
          'cara-id',
          'cara',
          displayName: 'Cara',
          bio: 'Makes harbour walks.',
        ),
      )
      ..publishedByUsername['cara'] = [
        world('w1', 'Harbour Mural'),
        world('w2', 'Tide Clock'),
      ]
      ..discoveredCounts['cara'] = 9
      ..completedCounts['cara'] = 4;
    worlds = FakeWorldRepository()
      ..detailsById['w1'] = testDetails(
        'w1',
        'Harbour Mural',
        WorldCategory.art,
      ).copyWith(creatorUsername: 'cara', creatorDisplayName: 'Cara');
  });

  /// The number shown above [label] on the own profile.
  Finder stat(String label, String value) => find.descendant(
    of: find.byKey(ValueKey('stat-$label')),
    matching: find.text(value),
  );

  Future<void> pump(WidgetTester tester) {
    usePhoneScreen(tester);
    return pumpWorldsApp(
      tester,
      auth: auth,
      profiles: profiles,
      worlds: worlds,
    );
  }

  Future<void> push(WidgetTester tester, String location) async {
    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(location),
    );
    await tester.pumpAndSettle();
  }

  group('a creator page', () {
    testWidgets('shows public fields and published Worlds, no private counts', (
      tester,
    ) async {
      await pump(tester);
      await push(tester, AppRoutes.creatorPage('cara'));

      expect(find.text('Cara'), findsOneWidget);
      expect(find.text('@cara'), findsWidgets);
      expect(find.text('Makes harbour walks.'), findsOneWidget);
      expect(find.text('2 published Worlds'), findsOneWidget);
      expect(find.text('Harbour Mural'), findsOneWidget);
      expect(find.text('Art · published 9 Mar 2025'), findsNWidgets(2));
      // Activity belongs to its owner.
      expect(find.text('Discovered'), findsNothing);
      expect(find.text('Completed'), findsNothing);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('opens from the creator line on a World, and back again', (
      tester,
    ) async {
      await pump(tester);
      await push(tester, AppRoutes.worldDetails('w1'));

      await tester.tap(find.text('by Cara'));
      await tester.pumpAndSettle();
      expect(find.text('2 published Worlds'), findsOneWidget);

      // One of their Worlds opens on top, and Back returns to the page.
      await tester.tap(find.text('Harbour Mural'));
      await tester.pumpAndSettle();
      expect(find.text('A short walk along the harbour.'), findsOneWidget);
      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();
      expect(find.text('2 published Worlds'), findsOneWidget);
    });

    testWidgets('loads further Worlds a page at a time', (tester) async {
      profiles.worldsPageSize = 1;
      await pump(tester);
      await push(tester, AppRoutes.creatorPage('cara'));

      expect(find.text('Tide Clock'), findsNothing);
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.text('Tide Clock'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
      expect(profiles.pageRequests.map((r) => r.offset), [0, 1]);
    });

    testWidgets('an unknown username says so', (tester) async {
      await pump(tester);
      await push(tester, AppRoutes.creatorPage('nobody'));

      expect(find.text('No one has this username'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry that works', (tester) async {
      profiles.nextPageError = const AppFailure.offline();
      await pump(tester);
      await push(tester, AppRoutes.creatorPage('cara'));

      expect(find.textContaining("You're offline"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Harbour Mural'), findsOneWidget);
    });

    testWidgets('a creator without Worlds says so', (tester) async {
      profiles.publishedByUsername['cara'] = [];
      await pump(tester);
      await push(tester, AppRoutes.creatorPage('cara'));

      expect(find.text('0 published Worlds'), findsOneWidget);
      expect(find.text('No published Worlds yet.'), findsOneWidget);
    });
  });

  group('the own profile', () {
    testWidgets('shows the counts the server gives and published Worlds', (
      tester,
    ) async {
      profiles
        ..publishedByUsername['alice'] = [world('w9', 'Lamp Room')]
        ..draftCounts['alice'] = 2
        ..discoveredCounts['alice'] = 5
        ..completedCounts['alice'] = 3;
      await pump(tester);
      await tapTab(tester, 'Profile');

      expect(stat('Published', '1'), findsOneWidget);
      expect(stat('Discovered', '5'), findsOneWidget);
      expect(stat('Completed', '3'), findsOneWidget);
      expect(find.text('Lamp Room'), findsOneWidget);

      await tester.ensureVisible(find.text('2 Worlds not published'));
      await tester.tap(find.text('2 Worlds not published'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    });

    testWidgets('with nothing made yet it shows zeros, not invented numbers', (
      tester,
    ) async {
      await pump(tester);
      await tapTab(tester, 'Profile');

      expect(stat('Published', '0'), findsOneWidget);
      expect(stat('Discovered', '0'), findsOneWidget);
      expect(find.text("You haven't published a World yet."), findsOneWidget);
      expect(find.textContaining('not published'), findsNothing);
    });

    testWidgets('a failed load of the counts keeps the rest and retries', (
      tester,
    ) async {
      profiles.nextPageError = const AppFailure.offline();
      await pump(tester);
      await tapTab(tester, 'Profile');

      expect(find.text('Alice'), findsOneWidget);
      expect(find.textContaining("Couldn't load your Worlds."), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign out'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Try again'));
      await tester.pumpAndSettle();
      expect(stat('Published', '0'), findsOneWidget);
    });
  });

  test('a profile page reads the server fields', () {
    final page = ProfilePage.fromJson({
      'username': 'cara',
      'display_name': null,
      'bio': null,
      'is_own': true,
      'published_count': 1,
      'draft_count': 2,
      'discovered_count': 3,
      'completed_count': 0,
      'worlds': [
        {
          'id': 'w1',
          'title': 'Harbour Mural',
          'category': 'art',
          'cover_path': null,
          'published_at': '2026-11-21T06:00:00+00:00',
        },
      ],
      'has_more': false,
    });

    expect(page.name, '@cara');
    expect(page.isOwn, isTrue);
    expect(page.draftCount, 2);
    expect(page.discoveredCount, 3);
    expect(page.worlds.single.category, WorldCategory.art);
  });
}
