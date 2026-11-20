import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/bootstrap.dart';
import 'package:worlds/app/config/env.dart';

void main() {
  final validEnv = AppEnv(
    supabaseUrl: ' https://example.supabase.co ',
    supabasePublishableKey: ['sb', 'publishable', 'example'].join('_'),
  );

  test('does not initialise Supabase when configuration is missing', () async {
    var calls = 0;

    final result = await bootstrap(
      env: const AppEnv(supabaseUrl: '', supabasePublishableKey: ''),
      initializeSupabase: ({required url, required publishableKey}) async {
        calls++;
      },
    );

    expect(result, isA<StartupMisconfigured>());
    expect((result as StartupMisconfigured).problems, [
      EnvProblem.missingSupabaseUrl,
      EnvProblem.missingSupabaseKey,
    ]);
    expect(calls, 0);
  });

  test('reports a failure when initialisation throws', () async {
    final result = await bootstrap(
      env: validEnv,
      initializeSupabase: ({required url, required publishableKey}) async {
        throw StateError('boom');
      },
    );

    expect(result, isA<StartupFailed>());
  });

  test('initialises Supabase once with trimmed values', () async {
    final calls = <(String, String)>[];

    final result = await bootstrap(
      env: validEnv,
      initializeSupabase: ({required url, required publishableKey}) async {
        calls.add((url, publishableKey));
      },
    );

    expect(result, isA<StartupReady>());
    expect(calls, [
      ('https://example.supabase.co', validEnv.supabasePublishableKey),
    ]);
  });
}
