import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/maps/geo_circle.dart';
import 'package:worlds/core/media/picked_image.dart';
import 'package:worlds/core/utils/date_format.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/shared/models/geo_point.dart';

void main() {
  group('image format is detected from the bytes, not the name', () {
    Uint8List bytes(List<int> values) => Uint8List.fromList(values);

    test('JPEG, PNG and WebP', () {
      expect(
        ImageFormat.detect(bytes([0xFF, 0xD8, 0xFF, 0xE1])),
        ImageFormat.jpeg,
      );
      expect(
        ImageFormat.detect(
          bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]),
        ),
        ImageFormat.png,
      );
      expect(
        ImageFormat.detect(
          bytes([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]),
        ),
        ImageFormat.webp,
      );
    });

    test('anything else, including GIF, HEIC and short files, is refused', () {
      expect(ImageFormat.detect(bytes('GIF89a'.codeUnits)), isNull);
      expect(
        ImageFormat.detect(
          bytes([
            0,
            0,
            0,
            0x18,
            0x66,
            0x74,
            0x79,
            0x70,
            0x68,
            0x65,
            0x69,
            0x63,
          ]),
        ),
        isNull,
      );
      expect(ImageFormat.detect(bytes([0xFF, 0xD8])), isNull);
      expect(
        ImageFormat.detect(
          bytes([0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x41, 0x56, 0x49, 0x20]),
        ),
        isNull,
      );
    });

    test('formats map to the types and extensions storage accepts', () {
      expect(ImageFormat.values.map((f) => f.mimeType), [
        'image/jpeg',
        'image/png',
        'image/webp',
      ]);
      expect(ImageFormat.values.map((f) => f.extension), [
        'jpg',
        'png',
        'webp',
      ]);
      expect(PickedImage.maxBytes, 5242880);
    });
  });

  test('ids are random version 4 UUIDs', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) newUuid()};
    expect(ids, hasLength(200));
    expect(ids.every(pattern.hasMatch), isTrue);
  });

  test('a radius is drawn as a closed circle of the right size', () {
    const center = GeoPoint(latitude: 51.5, longitude: -0.12);
    final points = circlePolygon(center, 50);
    expect(points.first, points.last);
    for (final point in points) {
      expect(center.distanceMetersTo(point), closeTo(50, 0.5));
    }
  });

  test('days are short and local', () {
    final now = DateTime(2026, 11, 20, 15);
    expect(formatDay(DateTime(2026, 11, 20, 1), now: now), 'today');
    expect(formatDay(DateTime(2026, 11, 19, 23), now: now), 'yesterday');
    expect(formatDay(DateTime(2026, 3, 4), now: now), '4 Mar');
    expect(formatDay(DateTime(2025, 12, 31), now: now), '31 Dec 2025');
  });
}
