import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/network/backend_failure.dart';

AuthApiException authError(String code, {String status = '400'}) =>
    AuthApiException('server message', statusCode: status, code: code);

void main() {
  group('auth errors are mapped by code', () {
    const cases = <String, AppFailure>{
      'invalid_credentials': AppFailure.invalidCredentials(),
      'email_not_confirmed': AppFailure.emailNotConfirmed(),
      'user_already_exists': AppFailure.accountExists(),
      'email_exists': AppFailure.accountExists(),
      'weak_password': AppFailure.weakPassword(),
      'email_address_invalid': AppFailure.emailNotAllowed(),
      'email_address_not_authorized': AppFailure.emailNotAllowed(),
      'signup_disabled': AppFailure.signUpDisabled(),
      'email_provider_disabled': AppFailure.signUpDisabled(),
      'over_request_rate_limit': AppFailure.rateLimited(),
      'over_email_send_rate_limit': AppFailure.rateLimited(),
      'validation_failed': AppFailure.invalidContent(),
      'session_not_found': AppFailure.unauthenticated(),
      'session_expired': AppFailure.unauthenticated(),
      'bad_jwt': AppFailure.unauthenticated(),
    };

    for (final MapEntry(key: code, value: expected) in cases.entries) {
      test(code, () => expect(failureFromError(authError(code)), expected));
    }

    test('an unknown code is unexpected', () {
      expect(
        failureFromError(authError('something_new')),
        const AppFailure.unexpected(),
      );
    });

    test('an unknown code with status 429 is rate limiting', () {
      expect(
        failureFromError(authError('something_new', status: '429')),
        const AppFailure.rateLimited(),
      );
    });

    test('message text is never used to decide the failure', () {
      final error = AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'something_new',
      );
      expect(failureFromError(error), const AppFailure.unexpected());
    });
  });

  group('auth exception types', () {
    test('weak password exception', () {
      final error = AuthWeakPasswordException(
        message: 'weak',
        statusCode: '422',
        reasons: const ['length'],
      );
      expect(failureFromError(error), const AppFailure.weakPassword());
    });

    test('missing session', () {
      expect(
        failureFromError(AuthSessionMissingException()),
        const AppFailure.unauthenticated(),
      );
    });

    test('a request that never got a response is offline', () {
      expect(
        failureFromError(AuthRetryableFetchException(message: 'no route')),
        const AppFailure.offline(),
      );
    });

    test('a server error is unexpected', () {
      expect(
        failureFromError(
          AuthRetryableFetchException(message: 'boom', statusCode: '503'),
        ),
        const AppFailure.unexpected(),
      );
    });
  });

  group('database errors', () {
    const cases = <String, AppFailure>{
      '42501': AppFailure.permissionDenied(),
      '23505': AppFailure.invalidContent(),
      '23514': AppFailure.invalidContent(),
      '23502': AppFailure.invalidContent(),
      '22001': AppFailure.invalidContent(),
      '22023': AppFailure.invalidContent(),
      '22P02': AppFailure.invalidContent(),
      'PGRST116': AppFailure.notFound(),
      'P0002': AppFailure.notFound(),
      'WR429': AppFailure.rateLimited(),
      'XX000': AppFailure.unexpected(),
    };

    for (final MapEntry(key: code, value: expected) in cases.entries) {
      test(code, () {
        expect(
          failureFromError(PostgrestException(message: 'db', code: code)),
          expected,
        );
      });
    }
  });

  group('storage errors are mapped by status code', () {
    const cases = <String?, AppFailure>{
      '403': AppFailure.permissionDenied(),
      '401': AppFailure.permissionDenied(),
      '404': AppFailure.notFound(),
      '429': AppFailure.rateLimited(),
      '413': AppFailure.uploadFailed(),
      '500': AppFailure.uploadFailed(),
      null: AppFailure.uploadFailed(),
    };

    for (final MapEntry(key: status, value: expected) in cases.entries) {
      test('$status', () {
        expect(
          failureFromError(StorageException('storage', statusCode: status)),
          expected,
        );
      });
    }
  });

  group('network and other errors', () {
    test('socket, client and timeout errors are offline', () {
      for (final error in <Object>[
        const SocketException('no network'),
        http.ClientException('connection closed'),
        TimeoutException('slow'),
      ]) {
        expect(
          failureFromError(error),
          const AppFailure.offline(),
          reason: '$error',
        );
      }
    });

    test('an AppFailure passes through unchanged', () {
      expect(
        failureFromError(const AppFailure.usernameTaken()),
        const AppFailure.usernameTaken(),
      );
    });

    test('anything else is unexpected', () {
      expect(
        failureFromError(StateError('bug')),
        const AppFailure.unexpected(),
      );
    });
  });
}
