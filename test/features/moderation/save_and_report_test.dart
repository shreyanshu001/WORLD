import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/moderation/domain/report.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/community_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  late FakeAuthRepository auth;
  late FakeWorldRepository worlds;
  late FakeSavedWorldsRepository saved;
  late FakeReportRepository reports;

  WorldDetails details({bool? isSaved = false, bool isCreator = false}) =>
      testDetails(
        'w1',
        'Harbour Gate',
        WorldCategory.story,
        isCreator: isCreator,
      ).copyWith(isSaved: isSaved);

  setUp(() {
    auth = FakeAuthRepository(signedInAs: alice)
      ..addAccount('alice@example.com', 'password1', alice);
    worlds = FakeWorldRepository()..detailsById['w1'] = details();
    saved = FakeSavedWorldsRepository(currentUserId: () => auth.currentUser?.id)
      ..catalogue['w1'] = testSaved('w1', 'Harbour Gate');
    reports = FakeReportRepository();
  });

  Future<void> openDetails(WidgetTester tester) async {
    usePhoneScreen(tester);
    await pumpWorldsApp(
      tester,
      auth: auth,
      profiles: FakeProfileRepository()..add(testProfile(alice.id, 'alice')),
      worlds: worlds,
      saved: saved,
      reports: reports,
    );
    unawaited(
      GoRouter.of(
        tester.element(find.byType(NavigationBar)),
      ).push<void>(AppRoutes.worldDetails('w1')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openReport(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report this World'));
    await tester.pumpAndSettle();
  }

  bool bookmarkFilled(WidgetTester tester) =>
      find.byIcon(Icons.bookmark).evaluate().isNotEmpty;

  group('saving from details', () {
    testWidgets('saves at once, tells the server, and removes again', (
      tester,
    ) async {
      await openDetails(tester);
      expect(bookmarkFilled(tester), isFalse);

      await tester.tap(find.byTooltip('Save for later'));
      await tester.pump();
      // Shown before the server has answered.
      expect(bookmarkFilled(tester), isTrue);
      await tester.pumpAndSettle();
      expect(saved.setRequests, [(worldId: 'w1', saved: true)]);

      await tester.tap(find.byTooltip('Remove from saved'));
      await tester.pumpAndSettle();
      expect(bookmarkFilled(tester), isFalse);
      expect(saved.setRequests.last, (worldId: 'w1', saved: false));
      expect(saved.savedByUser[alice.id], isEmpty);
    });

    testWidgets('a save the server refuses is taken back and explained', (
      tester,
    ) async {
      saved.nextSetError = const AppFailure.offline();
      await openDetails(tester);

      await tester.tap(find.byTooltip('Save for later'));
      await tester.pumpAndSettle();

      expect(bookmarkFilled(tester), isFalse);
      expect(find.textContaining("Couldn't save this World."), findsOneWidget);
      expect(find.byTooltip('Save for later'), findsOneWidget);
    });

    testWidgets('a World saved earlier shows as saved', (tester) async {
      worlds.detailsById['w1'] = details(isSaved: true);
      await openDetails(tester);

      expect(bookmarkFilled(tester), isTrue);
      expect(find.byTooltip('Remove from saved'), findsOneWidget);
    });

    testWidgets('the Saved tab shows a World saved from details', (
      tester,
    ) async {
      await openDetails(tester);
      await tester.tap(find.byTooltip('Save for later'));
      await tester.pumpAndSettle();

      await tapTab(tester, 'Saved');
      expect(find.text('Story · by Alice'), findsOneWidget);
    });

    testWidgets('signed out, saving leads to sign-in and back to the World', (
      tester,
    ) async {
      auth = FakeAuthRepository()
        ..addAccount('alice@example.com', 'password1', alice);
      saved = FakeSavedWorldsRepository(
        currentUserId: () => auth.currentUser?.id,
      )..catalogue['w1'] = testSaved('w1', 'Harbour Gate');
      worlds.detailsById['w1'] = details(isSaved: null);
      await openDetails(tester);

      await tester.tap(find.byTooltip('Save for later'));
      await tester.pumpAndSettle();
      expect(saved.setRequests, isEmpty);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Password', 'password1');
      await tapFilledButton(tester, 'Sign in');

      expect(find.text('Harbour Gate'), findsOneWidget);
      expect(find.byTooltip('Save for later'), findsOneWidget);
    });
  });

  group('reporting', () {
    testWidgets('sends a reason and details, then confirms', (tester) async {
      await openDetails(tester);
      await openReport(tester);

      expect(find.text('What is wrong with "Harbour Gate"?'), findsOneWidget);
      // Nothing can be sent before a reason is chosen.
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Send report'),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Unsafe or private place'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Details (optional)'),
        '  Behind a locked gate.  ',
      );
      await tester.pump();
      await tapFilledButton(tester, 'Send report');

      expect(find.text('Report sent'), findsOneWidget);
      expect(reports.sent.single, (
        worldId: 'w1',
        reason: ReportReason.unsafeOrPrivatePlace,
        details: 'Behind a locked gate.',
      ));

      await tapFilledButton(tester, 'Done');
      expect(find.text('Harbour Gate'), findsOneWidget);
      expect(find.text('Report sent'), findsNothing);
    });

    testWidgets('a second report of the same World says it is waiting', (
      tester,
    ) async {
      await openDetails(tester);
      await openReport(tester);
      await tester.tap(find.text('Spam or misleading'));
      await tester.pump();
      await tapFilledButton(tester, 'Send report');
      await tapFilledButton(tester, 'Done');

      await openReport(tester);
      await tester.tap(find.text('Something else'));
      await tester.pump();
      await tapFilledButton(tester, 'Send report');

      expect(find.text('You already reported this World'), findsOneWidget);
      expect(reports.sent, hasLength(1));
    });

    testWidgets('the daily limit is explained and the form is kept', (
      tester,
    ) async {
      reports.nextError = const AppFailure.rateLimited();
      await openDetails(tester);
      await openReport(tester);
      await tester.tap(find.text('Harassment or hate'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Details (optional)'),
        'Names a neighbour.',
      );
      await tester.pump();
      await tapFilledButton(tester, 'Send report');

      expect(find.textContaining('Try again tomorrow'), findsOneWidget);
      // What was typed is still in the field.
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Details (optional)'),
            )
            .controller!
            .text,
        'Names a neighbour.',
      );
      expect(find.text('Report sent'), findsNothing);
    });

    testWidgets('a failed report can be sent again', (tester) async {
      reports.nextError = const AppFailure.offline();
      await openDetails(tester);
      await openReport(tester);
      await tester.tap(find.text('Dangerous challenge'));
      await tester.pump();
      await tapFilledButton(tester, 'Send report');
      expect(find.textContaining("You're offline"), findsOneWidget);

      await tapFilledButton(tester, 'Send report');
      expect(find.text('Report sent'), findsOneWidget);
    });

    testWidgets('a creator is not offered a report of their own World', (
      tester,
    ) async {
      worlds.detailsById['w1'] = details(isCreator: true);
      await openDetails(tester);

      expect(find.byTooltip('More'), findsNothing);
    });

    testWidgets('signed out, reporting leads to sign-in', (tester) async {
      auth = FakeAuthRepository();
      worlds.detailsById['w1'] = details(isSaved: null);
      await openDetails(tester);
      await openReport(tester);

      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(reports.sent, isEmpty);
    });
  });

  test('report reasons use the names the database accepts', () {
    expect(ReportReason.values.map((reason) => reason.wire), [
      'unsafe_or_private_place',
      'harassment_or_hate',
      'sexual_content',
      'dangerous_activity',
      'spam_or_misleading',
      'other',
    ]);
  });
}
