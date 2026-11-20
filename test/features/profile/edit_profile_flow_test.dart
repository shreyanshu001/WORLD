import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/auth/presentation/sign_in_screen.dart';
import 'package:worlds/features/profile/presentation/edit_profile_screen.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');

  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository(signedInAs: alice);
    profiles = FakeProfileRepository()
      ..add(testProfile(alice.id, 'alice', bio: 'Old bio'))
      ..add(testProfile('bob-id', 'bob'));
  });

  Future<void> openEditProfile(WidgetTester tester) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await tapTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(FilledButton, 'Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  }

  testWidgets('the form starts with the current values', (tester) async {
    await openEditProfile(tester);

    expect(find.widgetWithText(TextFormField, 'alice'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Old bio'), findsOneWidget);
  });

  testWidgets('saving updates the profile and returns to it', (tester) async {
    await openEditProfile(tester);

    await enterField(tester, 'Display name (optional)', '  Alice A  ');
    await enterField(tester, 'Bio (optional)', '   ');
    await tapFilledButton(tester, 'Save');

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Profile saved'), findsOneWidget);
    expect(find.text('Alice A'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(profiles.profiles[alice.id]!.displayName, 'Alice A');
    expect(profiles.profiles[alice.id]!.bio, isNull);
  });

  testWidgets('a new username is saved in lower case', (tester) async {
    await openEditProfile(tester);

    await enterField(tester, 'Username', 'Alice_2');
    await tapFilledButton(tester, 'Save');

    expect(profiles.profiles[alice.id]!.username, 'alice_2');
    expect(find.text('@alice_2'), findsOneWidget);
  });

  testWidgets('an invalid username is caught before saving', (tester) async {
    await openEditProfile(tester);

    await enterField(tester, 'Username', 'Bad Name');
    await tapFilledButton(tester, 'Save');

    expect(
      find.text('Use only letters, numbers and underscores.'),
      findsOneWidget,
    );
    expect(profiles.updateCount, 0);
  });

  testWidgets('a taken username is reported and the form stays', (
    tester,
  ) async {
    await openEditProfile(tester);

    await enterField(tester, 'Username', 'bob');
    await tapFilledButton(tester, 'Save');

    expect(find.text('That username is taken. Try another.'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(profiles.profiles[alice.id]!.username, 'alice');
  });

  testWidgets('a failed save can be tried again', (tester) async {
    await openEditProfile(tester);

    profiles.nextUpdateError = const AppFailure.offline();
    await enterField(tester, 'Display name (optional)', 'Alice');
    await tapFilledButton(tester, 'Save');

    expect(
      find.text("You're offline. Check your connection and try again."),
      findsOneWidget,
    );

    await tapFilledButton(tester, 'Save');

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(profiles.profiles[alice.id]!.displayName, 'Alice');
  });

  testWidgets('signing out while editing goes to sign-in', (tester) async {
    await openEditProfile(tester);

    // Not awaited: the fake's delay only completes while the test pumps.
    unawaited(auth.signOut());
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
