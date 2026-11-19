import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';

/// Converts any error from Supabase, the network or the platform into an
/// [AppFailure].
///
/// Auth errors are mapped by their `code`, never by message text. Codes are
/// from https://supabase.com/docs/guides/auth/debugging/error-codes.
AppFailure failureFromError(Object error) => switch (error) {
  final AppFailure failure => failure,
  final AuthException exception => _fromAuth(exception),
  final PostgrestException exception => _fromPostgrest(exception),
  SocketException() ||
  http.ClientException() ||
  TimeoutException() => const AppFailure.offline(),
  _ => const AppFailure.unexpected(),
};

AppFailure _fromAuth(AuthException exception) {
  if (exception is AuthWeakPasswordException) {
    return const AppFailure.weakPassword();
  }
  if (exception is AuthSessionMissingException) {
    return const AppFailure.unauthenticated();
  }
  if (exception is AuthRetryableFetchException) {
    // No status code means the request never got a response.
    return exception.statusCode == null
        ? const AppFailure.offline()
        : const AppFailure.unexpected();
  }

  return switch (exception.code) {
    'invalid_credentials' => const AppFailure.invalidCredentials(),
    'email_not_confirmed' => const AppFailure.emailNotConfirmed(),
    'user_already_exists' || 'email_exists' => const AppFailure.accountExists(),
    'weak_password' => const AppFailure.weakPassword(),
    'email_address_invalid' ||
    'email_address_not_authorized' => const AppFailure.emailNotAllowed(),
    'signup_disabled' ||
    'email_provider_disabled' => const AppFailure.signUpDisabled(),
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' => const AppFailure.rateLimited(),
    'validation_failed' => const AppFailure.invalidContent(),
    'session_not_found' ||
    'session_expired' ||
    'bad_jwt' => const AppFailure.unauthenticated(),
    _ when exception.statusCode == '429' => const AppFailure.rateLimited(),
    _ => const AppFailure.unexpected(),
  };
}

/// PostgreSQL error codes: https://www.postgresql.org/docs/current/errcodes-appendix.html
AppFailure _fromPostgrest(PostgrestException exception) =>
    switch (exception.code) {
      '42501' => const AppFailure.permissionDenied(),
      '23505' ||
      '23514' ||
      '23502' ||
      '22001' => const AppFailure.invalidContent(),
      // PostgREST: a single row was requested but none matched.
      'PGRST116' => const AppFailure.notFound(),
      _ => const AppFailure.unexpected(),
    };
