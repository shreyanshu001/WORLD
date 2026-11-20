import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/config/env.dart';
import 'package:worlds/app/startup_gate.dart';
import 'package:worlds/core/widgets/loading_view.dart';

void main() {
  final key = ['sb', 'publishable', 'example'].join('_');
  final validEnv = AppEnv(
    supabaseUrl: 'https://example.supabase.co',
    supabasePublishableKey: key,
  );

  testWidgets('shows loading, then the app, when startup succeeds', (
    tester,
  ) async {
    final started = Completer<void>();

    await tester.pumpWidget(
      StartupGate(
        env: validEnv,
        initializeSupabase: ({required url, required publishableKey}) =>
            started.future,
      ),
    );
    expect(find.byType(LoadingView), findsOneWidget);

    started.complete();
    await tester.pumpAndSettle();

    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('explains missing configuration and offers no retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      StartupGate(
        env: AppEnv(supabaseUrl: '', supabasePublishableKey: key),
        initializeSupabase: ({required url, required publishableKey}) async {
          fail('Supabase must not be initialised without configuration.');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('This build is not configured.'), findsOne);
    expect(find.textContaining('SUPABASE_URL is not set.'), findsOne);
    expect(find.text('Try again'), findsNothing);
    expect(find.textContaining(key), findsNothing);
  });

  testWidgets('offers a retry when startup fails, and recovers', (
    tester,
  ) async {
    var attempts = 0;

    await tester.pumpWidget(
      StartupGate(
        env: validEnv,
        initializeSupabase: ({required url, required publishableKey}) async {
          attempts++;
          if (attempts == 1) throw StateError('boom');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("WORLDS couldn't start. Try again."), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.textContaining(key), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
