import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/profile/domain/profile.dart';
import 'package:worlds/features/profile/domain/profile_rules.dart';

void main() {
  group('usernames', () {
    test('are normalised to trimmed lower case', () {
      expect(ProfileRules.normalizeUsername('  Alice_01 '), 'alice_01');
    });

    test('accept 3 to 20 letters, digits and underscores', () {
      for (final value in ['abc', 'a_b', 'ABC', 'x' * 20, 'user_0123456789']) {
        expect(ProfileRules.validateUsername(value), isNull, reason: value);
      }
    });

    test('reject empty, too short and too long names', () {
      expect(ProfileRules.validateUsername('  '), 'Choose a username.');
      expect(ProfileRules.validateUsername('ab'), 'Use 3–20 characters.');
      expect(ProfileRules.validateUsername('x' * 21), 'Use 3–20 characters.');
    });

    test('reject other characters', () {
      for (final value in ['has space', 'dash-name', 'dot.name', 'émile']) {
        expect(
          ProfileRules.validateUsername(value),
          'Use only letters, numbers and underscores.',
          reason: value,
        );
      }
    });
  });

  test('display names allow blank and up to 50 characters', () {
    expect(ProfileRules.validateDisplayName(''), isNull);
    expect(ProfileRules.validateDisplayName('  ${'a' * 50}  '), isNull);
    expect(
      ProfileRules.validateDisplayName('a' * 51),
      'Use at most 50 characters.',
    );
  });

  test('bios allow up to 280 characters', () {
    expect(ProfileRules.validateBio('a' * 280), isNull);
    expect(ProfileRules.validateBio('a' * 281), 'Use at most 280 characters.');
  });

  test('blankToNull trims and turns blank into null', () {
    expect(ProfileRules.blankToNull('   '), isNull);
    expect(ProfileRules.blankToNull('  Ada  '), 'Ada');
  });

  test('profiles read the database row format', () {
    final profile = Profile.fromJson(const {
      'id': 'abc',
      'username': 'alice',
      'display_name': 'Alice',
      'bio': null,
      'avatar_path': null,
      'created_at': '2026-11-19T19:04:24.123456+00:00',
      'updated_at': '2026-11-20T08:00:00+00:00',
    });

    expect(profile.username, 'alice');
    expect(profile.displayName, 'Alice');
    expect(profile.bio, isNull);
    expect(profile.createdAt, DateTime.utc(2026, 11, 19, 19, 4, 24, 123, 456));
  });
}
