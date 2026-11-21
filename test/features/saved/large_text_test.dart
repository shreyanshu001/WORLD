import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/profile/domain/profile_page.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/community_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

/// The Checkpoint 6 screens at the largest text size Android offers (200%).
/// A layout that overflows fails the test by itself.
void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  Future<void> pumpLarge(
    WidgetTester tester, {
    required FakeSavedWorldsRepository saved,
    required FakeProfileRepository profiles,
    required FakeWorldRepository worlds,
  }) async {
    usePhoneScreen(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpWorldsApp(
      tester,
      auth: FakeAuthRepository(signedInAs: alice),
      profiles: profiles,
      worlds: worlds,
      saved: saved,
    );
  }

  testWidgets('Saved, details, the report form and profiles fit at 200% text', (
    tester,
  ) async {
    final saved = FakeSavedWorldsRepository(currentUserId: () => alice.id)
      ..seed(alice.id, [
        testSaved(
          'w1',
          'The Lighthouse Keeper and the Long Night',
          creatorDisplayName: 'Mira Chen',
          distanceMeters: 1400,
        ),
      ])
      ..unavailable = 2;
    final profiles = FakeProfileRepository()
      ..add(
        testProfile(
          alice.id,
          'alice',
          displayName: 'Alice',
          bio: 'Collects harbour stories.',
        ),
      )
      ..add(testProfile('mira-id', 'mira', displayName: 'Mira Chen'))
      ..publishedByUsername['alice'] = [
        ProfileWorld(
          id: 'w4',
          title: 'Market Walk',
          category: WorldCategory.experience,
          publishedAt: DateTime.utc(2025, 4),
        ),
      ]
      ..publishedByUsername['mira'] = [
        ProfileWorld(
          id: 'w1',
          title: 'The Lighthouse Keeper and the Long Night',
          category: WorldCategory.story,
          publishedAt: DateTime.utc(2025, 3, 9),
        ),
      ]
      ..draftCounts['alice'] = 2
      ..discoveredCounts['alice'] = 7
      ..completedCounts['alice'] = 4;
    final worlds = FakeWorldRepository()
      ..detailsById['w1'] =
          testDetails(
            'w1',
            'The Lighthouse Keeper and the Long Night',
            WorldCategory.story,
            distanceMeters: 1400,
          ).copyWith(
            creatorUsername: 'mira',
            creatorDisplayName: 'Mira Chen',
            playStatus: PlayStatus.locked,
            isSaved: true,
          );

    await pumpLarge(tester, saved: saved, profiles: profiles, worlds: worlds);

    await tapTab(tester, 'Saved');
    expect(find.textContaining('The Lighthouse Keeper'), findsOneWidget);

    await tester.tap(find.textContaining('The Lighthouse Keeper'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from saved'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this World'));
    await tester.pumpAndSettle();
    // At this size the reasons start below the fold; scroll as a reader would.
    await tester.ensureVisible(find.text('Unsafe or private place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unsafe or private place'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send report'));
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(find.text('Report sent'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('by Mira Chen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('by Mira Chen'));
    await tester.pumpAndSettle();
    expect(find.text('1 published World'), findsOneWidget);
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();

    await tapTab(tester, 'Profile');
    expect(find.text('Discovered'), findsOneWidget);
    expect(find.text('2 Worlds not published'), findsOneWidget);
  });

  testWidgets('the empty Saved tab fits at 200% text', (tester) async {
    await pumpLarge(
      tester,
      saved: FakeSavedWorldsRepository(currentUserId: () => alice.id),
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      worlds: FakeWorldRepository(),
    );
    await tapTab(tester, 'Saved');
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Explore the map'), findsOneWidget);
  });
}
