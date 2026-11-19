import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/app.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/profile/application/profile_providers.dart';

import 'fakes.dart';

/// Pumps the whole app with in-memory repositories.
Future<void> pumpWorldsApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeProfileRepository? profiles,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(
          profiles ?? FakeProfileRepository(),
        ),
      ],
      retry: noAutomaticRetry,
      child: const WorldsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps a bottom-navigation destination.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Types [text] into the form field labelled [label].
Future<void> enterField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pump();
}

/// Taps the filled button labelled [label] and waits for the result.
Future<void> tapFilledButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
