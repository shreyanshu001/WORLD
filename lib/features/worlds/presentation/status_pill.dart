import 'package:flutter/material.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/components/design.dart';

/// Where a creator's World stands, as a coloured pill.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.lifecycle, super.key});

  final WorldLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (fg, bg, icon) = switch (lifecycle) {
      WorldLifecycle.published => (c.success, c.successSoft, Icons.public),
      WorldLifecycle.draft => (c.muted, c.surfaceSubtle, Icons.edit_outlined),
      WorldLifecycle.unpublished => (
        c.accent,
        c.accent.withValues(alpha: 0.14),
        Icons.visibility_off_outlined,
      ),
      WorldLifecycle.hidden => (c.danger, c.dangerSoft, Icons.flag_outlined),
    };
    return InfoChip(
      label: lifecycle.label,
      icon: icon,
      color: fg,
      background: bg,
    );
  }
}
