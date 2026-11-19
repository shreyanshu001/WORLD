import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/auth/domain/auth_repository.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/auth/presentation/register_screen.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository()..add(testProfile('alice-id', 'alice'));
  });

  Future<void> openRegister(WidgetTester tester) async {
    await pumpWorldsApp(tester, auth: auth, profiles: profiles);
    await tapTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  }

  Future<void> register(
    WidgetTester tester, {
    required String username,
    String email = 'new@example.com',
    String password = 'long-enough',
  }) async {
    await enterField(tester, 'Username', username);
    await enterField(tester, 'Email', email);
    await enterField(tester, 'Password', password);
    await tapFilledButton(tester, 'Create account');
  }

  testWidgets('invalid fields are caught before any request', (tester) async {
    await openRegister(tester);

    await register(tester, username: 'no spaces', email: 'nope', password: '1');

    expect(
      find.text('Use only letters, numbers and underscores.'),
      findsOneWidget,
    );
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(auth.signUpRequests, isEmpty);
  });

  testWidgets('a taken username is reported without signing up', (
    tester,
  ) async {
    await openRegister(tester);

    await register(tester, username: ' Alice ');

    expect(find.text('That username is taken. Try another.'), findsOneWidget);
    expect(auth.signUpRequests, isEmpty);
  });

  testWidgets('sign-up errors are shown on the form', (tester) async {
    await openRegister(tester);

    auth.nextError = const AppFailure.emailNotAllowed();
    await register(tester, username: 'carol');

    expect(
      find.textContaining("This email address can't be used to sign up"),
      findsOneWidget,
    );
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('when confirmation is needed, the user is told to check email', (
    tester,
  ) async {
    auth.signUpOutcome = SignUpOutcome.confirmationRequired;
    await openRegister(tester);

    await register(tester, username: 'carol', email: 'carol@example.com');

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('carol@example.com'), findsOneWidget);
    expect(find.textContaining('account was created'), findsNothing);
    expect(auth.currentUser, isNull);
    expect(auth.signUpRequests, ['carol']);

    await tester.tap(find.widgetWithText(FilledButton, 'Go to sign in'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets(
    'a failed sign-up followed by signing in to another account shows no '
    'username notice',
    (tester) async {
      auth.addAccount(
        'alice@example.com',
        'password-a',
        const AuthUser(id: 'alice-id', email: 'alice@example.com'),
      );
      await openRegister(tester);

      auth.nextError = const AppFailure.emailNotAllowed();
      await register(tester, username: 'carol');
      expect(find.byType(RegisterScreen), findsOneWidget);

      await tester.tap(
        find.widgetWithText(TextButton, 'Already have an account? Sign in'),
      );
      await tester.pumpAndSettle();
      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Password', 'password-a');
      await tapFilledButton(tester, 'Sign in');

      expect(find.text('@alice'), findsOneWidget);
      expect(find.textContaining('was taken'), findsNothing);
    },
  );

  testWidgets(
    'a sign-up waiting for email confirmation leaves no username notice',
    (tester) async {
      auth
        ..signUpOutcome = SignUpOutcome.confirmationRequired
        ..addAccount(
          'alice@example.com',
          'password-a',
          const AuthUser(id: 'alice-id', email: 'alice@example.com'),
        );
      await openRegister(tester);

      await register(tester, username: 'carol');
      await tester.tap(find.widgetWithText(FilledButton, 'Go to sign in'));
      await tester.pumpAndSettle();
      await enterField(tester, 'Email', 'alice@example.com');
      await enterField(tester, 'Password', 'password-a');
      await tapFilledButton(tester, 'Sign in');

      expect(find.text('@alice'), findsOneWidget);
      expect(find.textContaining('was taken'), findsNothing);
    },
  );

  testWidgets('a granted username shows no notice', (tester) async {
    auth
      ..newUserId = 'dave-id'
      ..onSignedUp = (id, username) => profiles.add(testProfile(id, username));
    await openRegister(tester);

    await register(tester, username: 'Dave');

    expect(auth.signUpRequests, ['dave']);
    expect(find.text('@dave'), findsOneWidget);
    expect(find.textContaining('was taken'), findsNothing);
  });

  testWidgets(
    'if the server assigns a different username, the user is told once',
    (tester) async {
      auth
        ..newUserId = 'erin-id'
        ..onSignedUp = (id, _) =>
            profiles.add(testProfile(id, 'user_0123456789'));
      await openRegister(tester);

      await register(tester, username: 'erin');

      expect(find.text('@user_0123456789'), findsOneWidget);
      expect(
        find.textContaining(
          '"erin" was taken, so your username is '
          '@user_0123456789.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();

      expect(find.textContaining('was taken'), findsNothing);
    },
  );
}
