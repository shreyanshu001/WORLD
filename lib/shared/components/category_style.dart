import 'package:flutter/material.dart';
import 'package:worlds/shared/models/world_category.dart';

/// How each category looks. Colours are distinct in hue and paired with an
/// icon and a label, so colour is never the only cue.
extension WorldCategoryStyle on WorldCategory {
  IconData get icon => switch (this) {
    WorldCategory.story => Icons.auto_stories_outlined,
    WorldCategory.puzzle => Icons.extension_outlined,
    WorldCategory.art => Icons.palette_outlined,
    WorldCategory.experience => Icons.explore_outlined,
  };

  Color get color => switch (this) {
    WorldCategory.story => const Color(0xFF6A3FB5),
    WorldCategory.puzzle => const Color(0xFFB26A00),
    WorldCategory.art => const Color(0xFFC2185B),
    WorldCategory.experience => const Color(0xFF00796B),
  };

  /// [color] as `#RRGGBB`, for map markers.
  String get colorHex {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
