import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/config/env.dart';

/// Builds an unsigned JWT-shaped string at runtime, so that no token-like
/// literal is stored in the repository.
String fakeJwt(Map<String, Object?> payload) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return [
    part({'alg': 'HS256', 'typ': 'JWT'}),
    part(payload),
    'signature',
  ].join('.');
}

void main() {
  const url = 'https://example.supabase.co';
  final publishableKey = ['sb', 'publishable', 'example'].join('_');
  final secretKey = ['sb', 'secret', 'example'].join('_');

  AppEnv env({String? supabaseUrl, String? key}) => AppEnv(
    supabaseUrl: supabaseUrl ?? url,
    supabasePublishableKey: key ?? publishableKey,
  );

  group('AppEnv.problems', () {
    test('is empty for an https URL and a publishable key', () {
      expect(env().problems, isEmpty);
    });

    test('accepts a legacy JWT key whose role is anon', () {
      expect(env(key: fakeJwt({'role': 'anon'})).problems, isEmpty);
    });

    test('accepts plain http only for a local Supabase stack', () {
      expect(env(supabaseUrl: 'http://10.0.2.2:54321').problems, isEmpty);
      expect(env(supabaseUrl: 'http://example.com').problems, [
        EnvProblem.invalidSupabaseUrl,
      ]);
    });

    test('reports a missing URL', () {
      expect(env(supabaseUrl: '').problems, [EnvProblem.missingSupabaseUrl]);
      expect(env(supabaseUrl: '   ').problems, [EnvProblem.missingSupabaseUrl]);
    });

    test('reports an unusable URL', () {
      for (final value in ['not a url', 'example.supabase.co', 'ftp://x.y']) {
        expect(env(supabaseUrl: value).problems, [
          EnvProblem.invalidSupabaseUrl,
        ], reason: value);
      }
    });

    test('reports a missing key', () {
      expect(env(key: '').problems, [EnvProblem.missingSupabaseKey]);
    });

    test('rejects a secret key', () {
      expect(env(key: secretKey).problems, [EnvProblem.secretSupabaseKey]);
    });

    test('rejects a legacy JWT key whose role is service_role', () {
      expect(env(key: fakeJwt({'role': 'service_role'})).problems, [
        EnvProblem.secretSupabaseKey,
      ]);
    });

    test('does not throw on a malformed three-part key', () {
      expect(env(key: 'a.%%%.c').problems, isEmpty);
      expect(env(key: 'a.bm90IGpzb24.c').problems, isEmpty);
    });

    test('reports every problem at once', () {
      expect(env(supabaseUrl: '', key: '').problems, [
        EnvProblem.missingSupabaseUrl,
        EnvProblem.missingSupabaseKey,
      ]);
    });
  });

  test('every problem has a description', () {
    for (final problem in EnvProblem.values) {
      expect(problem.description, isNotEmpty, reason: problem.name);
    }
  });
}
