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

  /// [color] for text and icons on the app's own surfaces. The category
  /// colours were chosen against light surfaces; on dark ones they are too
  /// dark to read (Story is 2.3:1), so there they are lightened. Markers,
  /// panels and anything drawn over the map keep [color].
  Color foregroundOn(Brightness brightness) => brightness == Brightness.dark
      ? Color.lerp(color, Colors.white, 0.45)!
      : color;

  /// The colour for this category's name and other small text. As
  /// [foregroundOn], except that Puzzle's amber is too light for small text
  /// on light surfaces (4.2:1 on white) and is deepened there to 6.1:1
  /// (docs/DECISIONS.md, D-041). Icons, badges, markers and panels keep
  /// the amber.
  Color textOn(Brightness brightness) =>
      brightness == Brightness.light && this == WorldCategory.puzzle
      ? const Color(0xFF8E5500)
      : foregroundOn(brightness);

  /// [color] as `#RRGGBB`, for map markers.
  String get colorHex {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
