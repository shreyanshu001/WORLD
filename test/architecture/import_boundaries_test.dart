import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces docs/TECHNICAL_ARCHITECTURE.md: map and location SDKs stay
/// behind their adapters, Supabase stays in the data layer, and domain code
/// stays free of Flutter and SDKs.
void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'))
      .map(
        (file) => (
          path: file.path.replaceAll(r'\', '/'),
          text: file.readAsStringSync(),
        ),
      )
      .toList();

  final importPattern = RegExp(
    r'''^import\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  List<String> importsOf(String text) =>
      importPattern.allMatches(text).map((match) => match.group(1)!).toList();

  List<String> violations({
    required String package,
    required bool Function(String path) allowedIn,
  }) => [
    for (final source in sources)
      if (!allowedIn(source.path) &&
          importsOf(source.text).any((import) => import.startsWith(package)))
        source.path,
  ];

  test('sources were found', () {
    expect(sources.length, greaterThan(20));
  });

  test('maplibre_gl is imported only in lib/core/maps', () {
    expect(
      violations(
        package: 'package:maplibre_gl/',
        allowedIn: (path) => path.startsWith('lib/core/maps/'),
      ),
      isEmpty,
    );
  });

  test('geolocator is imported only in lib/core/location', () {
    expect(
      violations(
        package: 'package:geolocator/',
        allowedIn: (path) => path.startsWith('lib/core/location/'),
      ),
      isEmpty,
    );
  });

  test('image_picker is imported only in lib/core/media', () {
    expect(
      violations(
        package: 'package:image_picker/',
        allowedIn: (path) => path.startsWith('lib/core/media/'),
      ),
      isEmpty,
    );
  });

  test(
    'supabase_flutter is imported only by startup, network and data code',
    () {
      expect(
        violations(
          package: 'package:supabase_flutter/',
          allowedIn: (path) =>
              path == 'lib/app/bootstrap.dart' ||
              path.startsWith('lib/core/network/') ||
              RegExp(r'^lib/features/[^/]+/data/').hasMatch(path),
        ),
        isEmpty,
      );
    },
  );

  test('analytics code imports nothing that holds a position', () {
    const forbidden = [
      'package:worlds/core/location/',
      'package:worlds/core/maps/',
      'package:worlds/shared/models/geo_point.dart',
      'package:geolocator/',
      'package:maplibre_gl/',
    ];
    final offenders = [
      for (final source in sources)
        if (source.path.startsWith('lib/core/analytics/') ||
            source.path == 'lib/core/network/supabase_product_event_sink.dart')
          for (final import in importsOf(source.text))
            if (forbidden.any(import.startsWith)) '${source.path}: $import',
    ];
    expect(offenders, isEmpty);
    expect(
      sources.where((s) => s.path.startsWith('lib/core/analytics/')),
      isNotEmpty,
    );
  });

  test('domain code and shared models import no Flutter or SDK packages', () {
    const forbidden = [
      'package:flutter/',
      'package:flutter_riverpod/',
      'package:supabase_flutter/',
      'package:maplibre_gl/',
      'package:geolocator/',
      'package:http/',
      'package:image_picker/',
    ];
    final offenders = [
      for (final source in sources)
        if (source.path.contains('/domain/') ||
            source.path.startsWith('lib/shared/models/'))
          for (final import in importsOf(source.text))
            if (forbidden.any(import.startsWith)) '${source.path}: $import',
    ];
    expect(offenders, isEmpty);
  });
}
