import 'package:flutter/material.dart';
import 'package:worlds/features/worlds/presentation/stored_image.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A World's cover image, or a deliberate category panel when it has none.
class WorldCover extends StatelessWidget {
  const WorldCover({
    required this.category,
    this.coverPath,
    this.iconSize = 64,
    super.key,
  });

  final WorldCategory category;
  final String? coverPath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = CategoryPanel(category: category, iconSize: iconSize);
    final path = coverPath;
    if (path == null) return fallback;
    return StoredImage(
      storagePath: path,
      placeholder: fallback,
      semanticLabel: 'Cover image',
    );
  }
}

/// The category's colour and icon, used where a World has no image.
class CategoryPanel extends StatelessWidget {
  const CategoryPanel({required this.category, this.iconSize = 64, super.key});

  final WorldCategory category;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Color.alphaBlend(
        category.color.withValues(alpha: 0.16),
        scheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(category.icon, size: iconSize, color: category.color),
      ),
    );
  }
}
