import 'package:flutter/material.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/features/worlds/presentation/world_cover.dart';
import 'package:worlds/shared/models/world_category.dart';

/// One World in a list: its cover (or category panel), title and a line of
/// supporting text, with room for one action at the end.
class WorldTile extends StatelessWidget {
  const WorldTile({
    required this.worldId,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.onTap,
    this.coverPath,
    this.trailing,
    super.key,
  });

  final String worldId;
  final String title;
  final WorldCategory category;
  final String subtitle;
  final String? coverPath;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox.square(
                  dimension: 56,
                  child: WorldCover(
                    category: category,
                    coverPath: coverPath,
                    iconSize: 26,
                    seed: worldId.hashCode,
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing case final trailing?) ...[
                const SizedBox(width: Space.xs),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
