import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/auth/domain/credential_rules.dart';

void main() {
  group('validateEmail', () {
    test('accepts ordinary addresses, ignoring surrounding spaces', () {
      expect(CredentialRules.validateEmail('a@b.co'), isNull);
      expect(
        CredentialRules.validateEmail('  first.last@mail.example  '),
        isNull,
      );
    });

    test('rejects empty and malformed addresses', () {
      expect(CredentialRules.validateEmail(''), 'Enter your email address.');
      for (final value in ['plain', 'a@b', '@b.co', 'a b@c.co']) {
        expect(
          CredentialRules.validateEmail(value),
          'Enter a valid email address.',
          reason: value,
        );
      }
    });
  });

  group('validateNewPassword', () {
    test('needs at least the minimum length', () {
      expect(CredentialRules.validateNewPassword(''), 'Enter a password.');
      expect(
        CredentialRules.validateNewPassword('1234567'),
        'Use at least 8 characters.',
      );
      expect(CredentialRules.validateNewPassword('12345678'), isNull);
    });
  });

  test('validateExistingPassword only requires a value', () {
    expect(
      CredentialRules.validateExistingPassword(''),
      'Enter your password.',
    );
    expect(CredentialRules.validateExistingPassword('x'), isNull);
  });
}
