import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/auth/presentation/sign_in_screen.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  const alice = AuthUser(id: 'alice-id', email: 'alice@example.com');
  const bob = AuthUser(id: 'bob-id', email: 'bob@example.com');

  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository()
      ..addAccount('alice@example.com', 'password-a', alice)
      ..addAccount('bob@example.com', 'password-b', bob);
    profiles = FakeProfileRepository()
      ..add(testProfile(alice.id, 'alice'))
      ..add(testProfile(bob.id, 'bob'));
  });

  Future<void> openSignInFromProfile(WidgetTester tester) async {
    await tapTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  }

  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await enterField(tester, 'Email', email);
    await enterField(tester, 'Password', password);
    await tapFilledButton(tester, 'Sign in');
  }

  testWidgets('Profile asks signed-out users to sign in', (tester) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await tapTab(tester, 'Profile');

    expect(find.text('Your profile'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Create account'), findsOne);
  });

  testWidgets('empty fields are caught before any request', (tester) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await openSignInFromProfile(tester);

    await tapFilledButton(tester, 'Sign in');

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('a wrong password shows a plain message and stays', (
    tester,
  ) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await openSignInFromProfile(tester);

    await signIn(tester, 'alice@example.com', 'wrong');

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('a network failure is reported without leaving the form', (
    tester,
  ) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await openSignInFromProfile(tester);

    auth.nextError = const AppFailure.offline();
    await signIn(tester, 'alice@example.com', 'password-a');

    expect(
      find.text("You're offline. Check your connection and try again."),
      findsOneWidget,
    );
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets(
    'signing in returns to Profile; signing out and in as another user '
    'shows the other profile',
    (tester) async {
      await pumpWorldsApp(tester, auth: auth, profiles: profiles);
      await openSignInFromProfile(tester);

      await signIn(tester, 'alice@example.com', 'password-a');

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.text('@alice'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNull);
      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('@alice'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      await signIn(tester, 'bob@example.com', 'password-b');

      expect(find.text('@bob'), findsOneWidget);
      expect(find.text('@alice'), findsNothing);
    },
  );

  testWidgets('signing in from Create returns to Create', (tester) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await tapTab(tester, 'Create');
    expect(find.text('Create a World'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await signIn(tester, 'alice@example.com', 'password-a');

    expect(find.text('Create your first World'), findsOneWidget);
  });

  testWidgets('an existing session is restored at launch', (tester) async {
    auth = FakeAuthRepository(signedInAs: alice);
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await tapTab(tester, 'Profile');

    expect(find.text('@alice'), findsOneWidget);
  });

  testWidgets('a failed profile load can be retried', (tester) async {
    auth = FakeAuthRepository(signedInAs: alice);
    profiles.fetchError = const AppFailure.offline();
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await tapTab(tester, 'Profile');

    expect(
      find.text("You're offline. Check your connection and try again."),
      findsOneWidget,
    );

    profiles.fetchError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('@alice'), findsOneWidget);
  });
}
