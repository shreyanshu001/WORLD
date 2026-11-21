import 'package:flutter/material.dart';
import 'package:worlds/features/worlds/presentation/stored_image.dart';
import 'package:worlds/shared/components/design.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A World's cover image, or its category's atlas panel when it has none.
class WorldCover extends StatelessWidget {
  const WorldCover({
    required this.category,
    this.coverPath,
    this.iconSize = 56,
    this.seed = 0,
    super.key,
  });

  final WorldCategory category;
  final String? coverPath;
  final double iconSize;

  /// Varies the fallback pattern, for example by World id.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final fallback = CategoryPanel(
      category: category,
      iconSize: iconSize,
      seed: seed,
    );
    final path = coverPath;
    if (path == null) return fallback;
    return StoredImage(
      storagePath: path,
      placeholder: fallback,
      semanticLabel: 'Cover image',
    );
  }
}

/// The category's atlas panel, used where a World has no image.
class CategoryPanel extends StatelessWidget {
  const CategoryPanel({
    required this.category,
    this.iconSize = 56,
    this.seed = 0,
    super.key,
  });

  final WorldCategory category;
  final double iconSize;
  final int seed;

  @override
  Widget build(BuildContext context) =>
      AtlasPanel(category: category, iconSize: iconSize, seed: seed);
}
