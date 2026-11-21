import 'package:flutter/material.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/components/design.dart';

/// Summary of the selected World. Tapping it opens the World's details.
class WorldPreviewCard extends StatelessWidget {
  const WorldPreviewCard({
    required this.world,
    required this.fromUserLocation,
    required this.onClose,
    required this.onOpen,
    super.key,
  });

  final WorldPreview world;

  /// Whether the distance is from the user rather than from the map centre.
  final bool fromUserLocation;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final distance = formatDistance(world.distanceMeters);

    return Material(
      color: colors.surface,
      elevation: 6,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(Radii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          // The right inset is small because the close button brings its
          // own: it is 48 dp to touch, round a 24 dp cross.
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.lg,
            Space.xs,
            Space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryBadge(
                    category: world.category,
                    size: 52,
                    named: false,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          world.category.label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: world.category.textOn(theme.brightness),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          world.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${world.creatorName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: colors.muted),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              Padding(
                padding: const EdgeInsets.only(right: Space.md),
                // The button drops under the distance when both cannot
                // share a line (large text, a narrow screen).
                child: Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InfoChip(
                      icon: fromUserLocation
                          ? Icons.near_me_outlined
                          : Icons.place_outlined,
                      label: fromUserLocation
                          ? '$distance away'
                          : '$distance from the map centre',
                      color: colors.accentText,
                      background: colors.accent.withValues(alpha: 0.12),
                    ),
                    FilledButton(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.lg,
                        ),
                      ),
                      child: const Text('View details'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
