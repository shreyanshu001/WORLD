import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';

void main() {
  const failures = <AppFailure>[
    AppFailure.unauthenticated(),
    AppFailure.permissionDenied(),
    AppFailure.locationUnavailable(),
    AppFailure.locationInaccurate(),
    AppFailure.notFound(),
    AppFailure.unpublished(),
    AppFailure.locked(),
    AppFailure.invalidContent(),
    AppFailure.uploadFailed(),
    AppFailure.rateLimited(),
    AppFailure.offline(),
    AppFailure.invalidCredentials(),
    AppFailure.accountExists(),
    AppFailure.weakPassword(),
    AppFailure.emailNotConfirmed(),
    AppFailure.emailNotAllowed(),
    AppFailure.signUpDisabled(),
    AppFailure.usernameTaken(),
    AppFailure.unexpected(),
  ];

  test('every failure has its own user message', () {
    final messages = failures.map((failure) => failure.userMessage).toList();

    expect(messages.every((message) => message.trim().isNotEmpty), isTrue);
    expect(messages.toSet(), hasLength(failures.length));
  });

  test('user messages contain no backend terms', () {
    final technical = RegExp(
      'sql|postgres|postgrest|supabase|exception|null|rpc',
      caseSensitive: false,
    );

    for (final failure in failures) {
      expect(
        technical.hasMatch(failure.userMessage),
        isFalse,
        reason: failure.userMessage,
      );
    }
  });

  test('any other error gets the generic message', () {
    expect(
      messageForError(StateError('bug')),
      'Something went wrong. Try again.',
    );
    expect(messageForError(null), 'Something went wrong. Try again.');
    expect(
      messageForError(const AppFailure.locked()),
      const AppFailure.locked().userMessage,
    );
  });

  test('failures of the same kind are equal', () {
    expect(const AppFailure.offline(), const AppFailure.offline());
    expect(const AppFailure.offline(), isNot(const AppFailure.locked()));
  });
}
