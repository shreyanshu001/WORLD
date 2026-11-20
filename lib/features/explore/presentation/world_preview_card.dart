import 'package:flutter/material.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/shared/components/category_style.dart';

/// Summary of the selected World. Opening the full World arrives in
/// Checkpoint 4.
class WorldPreviewCard extends StatelessWidget {
  const WorldPreviewCard({
    required this.world,
    required this.fromUserLocation,
    required this.onClose,
    super.key,
  });

  final WorldPreview world;

  /// Whether the distance is from the user rather than from the map centre.
  final bool fromUserLocation;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = formatDistance(world.distanceMeters);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(world.category.icon, color: world.category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(world.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${world.category.label} · by ${world.creatorName}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fromUserLocation
                        ? '$distance away'
                        : '$distance from the map centre',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
