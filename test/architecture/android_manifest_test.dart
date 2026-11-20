import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Foreground location only (AGENTS.md, docs/SECURITY_AND_PRIVACY.md).
///
/// This checks the app's own manifest. Plugins can add permissions during
/// the build, so each checkpoint also inspects the built APK with
/// `aapt2 dump permissions`.
void main() {
  // XML comments are removed first: they may name forbidden permissions as
  // warnings without declaring them.
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  test('never requests background location', () {
    expect(manifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
    expect(manifest, isNot(contains('FOREGROUND_SERVICE_LOCATION')));
  });

  test('declares foreground location and internet explicitly', () {
    for (final permission in [
      'android.permission.INTERNET',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
    ]) {
      expect(manifest, contains('android:name="$permission"'));
    }
  });

  test('the Gradle wrapper stays on the version this toolchain supports', () {
    // Android Gradle Plugin 8.11.1 (Flutter 3.38.3's template) does not run
    // on Gradle 9.6 or later. Editor tooling once upgraded the wrapper to
    // 9.7.1 silently and broke the build.
    final wrapper = File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync();
    expect(wrapper, contains('gradle-8.14-all.zip'));
  });

  test("removes geolocator's location foreground service", () {
    expect(
      RegExp(
        r'<service\s+android:name="com\.baseflow\.geolocator\.GeolocatorLocationService"\s+tools:node="remove"',
      ).hasMatch(manifest),
      isTrue,
    );
  });
}
