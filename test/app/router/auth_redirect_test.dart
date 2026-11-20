import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/app/router/app_routes.dart';

void main() {
  Uri uri(String location) => Uri.parse(location);

  group('authRedirect', () {
    test('signed-in users leave sign-in and sign-up for their destination', () {
      expect(
        authRedirect(signedIn: true, uri: uri('/sign-in?from=/create')),
        '/create',
      );
      expect(
        authRedirect(signedIn: true, uri: uri('/register?from=/saved')),
        '/saved',
      );
      expect(authRedirect(signedIn: true, uri: uri('/sign-in')), '/profile');
    });

    test('signed-out users are sent to sign in before editing a profile', () {
      expect(
        authRedirect(signedIn: false, uri: uri('/profile/edit')),
        AppRoutes.signInFrom('/profile/edit'),
      );
    });

    test("signed-out users are sent to sign in before the creator's pages", () {
      for (final location in ['/create/new?id=abc', '/create/worlds/abc']) {
        expect(
          authRedirect(signedIn: false, uri: uri(location)),
          AppRoutes.signInFrom('/create'),
          reason: location,
        );
        expect(authRedirect(signedIn: true, uri: uri(location)), isNull);
      }
    });

    test('signed-out players are sent to sign in, then back to the World', () {
      expect(
        authRedirect(signedIn: false, uri: uri('/play/abc')),
        AppRoutes.signInFrom('/explore/worlds/abc'),
      );
      expect(authRedirect(signedIn: true, uri: uri('/play/abc')), isNull);
    });

    test('World details stay open to everyone', () {
      expect(
        authRedirect(signedIn: false, uri: uri('/explore/worlds/abc')),
        isNull,
      );
    });

    test('other pages are left alone', () {
      for (final location in ['/explore', '/profile', '/saved', '/create']) {
        expect(authRedirect(signedIn: false, uri: uri(location)), isNull);
        expect(authRedirect(signedIn: true, uri: uri(location)), isNull);
      }
      expect(authRedirect(signedIn: false, uri: uri('/sign-in')), isNull);
      expect(authRedirect(signedIn: true, uri: uri('/profile/edit')), isNull);
    });
  });

  group('safeReturnPath', () {
    test('keeps in-app paths', () {
      expect(AppRoutes.safeReturnPath('/create'), '/create');
      expect(AppRoutes.safeReturnPath('/profile/edit'), '/profile/edit');
    });

    test('falls back to the profile for anything else', () {
      for (final from in [
        null,
        '',
        'create',
        '//evil.example',
        'https://evil.example',
        '/sign-in',
        '/register?from=/create',
      ]) {
        expect(AppRoutes.safeReturnPath(from), '/profile', reason: '$from');
      }
    });
  });
}
