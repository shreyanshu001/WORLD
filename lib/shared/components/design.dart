import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A category's icon on a soft tile of its colour.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.category, this.size = 44, super.key});

  final WorldCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: dark ? 0.28 : 0.13),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        category.icon,
        size: size * 0.52,
        color: dark
            ? Color.lerp(category.color, Colors.white, 0.45)
            : category.color,
        semanticLabel: category.label,
      ),
    );
  }
}

/// A small rounded label with an optional icon, for quick facts.
class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.label,
    this.icon,
    this.color,
    this.background,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = color ?? colors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A category's colour with soft atlas contour lines and its icon: the
/// deliberate stand-in for a World without a cover image.
class AtlasPanel extends StatelessWidget {
  const AtlasPanel({
    required this.category,
    this.iconSize = 56,
    this.seed = 0,
    super.key,
  });

  final WorldCategory category;
  final double iconSize;

  /// Varies the contour lines between Worlds.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final base = category.color;
    final deep = Color.lerp(base, Colors.black, 0.35)!;
    final light = Color.lerp(base, Colors.white, 0.25)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, deep],
        ),
      ),
      child: CustomPaint(
        painter: _ContourPainter(seed: seed),
        child: Center(
          child: Container(
            width: iconSize * 1.7,
            height: iconSize * 1.7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(category.icon, size: iconSize, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.18);
    final center = Offset(
      size.width * (0.25 + random.nextDouble() * 0.5),
      size.height * (0.3 + random.nextDouble() * 0.4),
    );
    final phase = random.nextDouble() * math.pi * 2;
    final maxRadius = size.longestSide * 0.9;
    for (var ring = 1; ring <= 12; ring++) {
      final radius = maxRadius * ring / 12;
      final path = Path();
      for (var step = 0; step <= 72; step++) {
        final angle = step / 72 * math.pi * 2;
        final wobble =
            1 +
            0.08 * math.sin(angle * 3 + phase + ring * 0.4) +
            0.05 * math.cos(angle * 5 - phase);
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius * wobble;
        step == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(_ContourPainter oldDelegate) => oldDelegate.seed != seed;
}

/// A section title with optional supporting text, used across screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: Space.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.of(context).muted,
            ),
          ),
        ],
      ],
    );
  }
}

/// A bar of actions pinned to the bottom of a screen, above the navigation.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.md,
            Space.lg,
            Space.md,
          ),
          child: child,
        ),
      ),
    );
  }
}
