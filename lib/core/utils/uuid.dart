import 'dart:math';

final _random = Random.secure();

/// A random (version 4) UUID, such as `3f2b8c1e-9a4d-4c6e-8b1f-2d7a9e0c5b13`.
///
/// The app chooses World, block and image ids itself, so retrying a save
/// after a timeout updates the same rows instead of creating new ones.
String newUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
