import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/core/widgets/location_explanation_dialog.dart';
import 'package:worlds/features/world_player/application/play_providers.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';

/// Where the user stands with a World on its details screen: locked (with
/// the unlock rule and any unlock problem) or unlocked.
class PlayPanel extends ConsumerWidget {
  const PlayPanel({required this.world, super.key});

  final WorldDetails world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final unlock = ref.watch(unlockControllerProvider(world.id));
    final status = world.playStatus;
    final unlocked =
        status == PlayStatus.inProgress ||
        status == PlayStatus.completed ||
        unlock.phase == UnlockPhase.unlocked;

    if (unlocked) {
      return _Panel(
        icon: status == PlayStatus.completed
            ? Icons.emoji_events_outlined
            : Icons.lock_open,
        iconColor: colors.success,
        background: colors.successSoft,
        title: status == PlayStatus.completed
            ? 'You finished this World'
            : 'Unlocked',
        body: status == PlayStatus.completed
            ? 'Play it again any time, wherever you are.'
            : 'It stays unlocked for you. Continue where you left off, '
                  'wherever you are.',
      );
    }

    final radius = world.unlockRadiusMeters;
    final distance = world.distanceMeters;
    final (
      String body,
      String? action,
      VoidCallback? onAction,
    ) = switch (unlock.phase) {
      UnlockPhase.locating => ('Finding your location…', null, null),
      UnlockPhase.checking => ('Checking you are there…', null, null),
      UnlockPhase.tooFar => (
        "You're ${formatDistance(unlock.distanceMeters ?? 0)} away. Get within "
            '${unlock.radiusMeters ?? radius} m of its place, then check again.',
        null,
        null,
      ),
      UnlockPhase.inaccurate => (
        'Your location is only accurate to about '
            '${(unlock.accuracyMeters ?? 0).round()} m. Step into the open or '
            'wait a moment, then check again.',
        null,
        null,
      ),
      UnlockPhase.denied => (
        'Location permission was refused. WORLDS needs one reading, now, to '
            'check you are there.',
        null,
        null,
      ),
      UnlockPhase.deniedForever => (
        'Location is blocked for WORLDS. Allow it in Settings to unlock Worlds.',
        'Open Settings',
        ref.read(unlockControllerProvider(world.id).notifier).openSettings,
      ),
      UnlockPhase.serviceDisabled => (
        "Your phone's location is turned off.",
        'Turn on',
        ref.read(unlockControllerProvider(world.id).notifier).openSettings,
      ),
      UnlockPhase.unavailable => (
        "We couldn't get your location. Check again in a moment.",
        null,
        null,
      ),
      UnlockPhase.failed => (
        unlock.failure?.userMessage ?? "That didn't work. Try again.",
        null,
        null,
      ),
      UnlockPhase.idle || UnlockPhase.unlocked => (
        'Unlocks within $radius m of its place on the map. '
            '${distance == null ? 'Use "Find Worlds near me" on Explore to see how far away it is.' : "You're ${formatDistance(distance)} away."}'
            '${status == null ? ' Sign in to unlock it.' : ''}',
        null,
        null,
      ),
    };

    final problem = switch (unlock.phase) {
      UnlockPhase.tooFar ||
      UnlockPhase.inaccurate ||
      UnlockPhase.denied ||
      UnlockPhase.deniedForever ||
      UnlockPhase.serviceDisabled ||
      UnlockPhase.unavailable ||
      UnlockPhase.failed => true,
      _ => false,
    };

    return _Panel(
      icon: unlock.busy ? Icons.my_location : Icons.lock_outline,
      iconColor: problem ? colors.accent : colors.primary,
      background: problem
          ? colors.accent.withValues(alpha: 0.12)
          : colors.primarySoft,
      title: 'Locked',
      body: body,
      footnote: 'The content stays hidden until you unlock it on site.',
      action: action,
      onAction: onAction,
      busy: unlock.busy,
      liveRegion: true,
      textStyle: theme.textTheme.bodyMedium,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.body,
    this.footnote,
    this.action,
    this.onAction,
    this.busy = false,
    this.liveRegion = false,
    this.textStyle,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String body;
  final String? footnote;
  final String? action;
  final VoidCallback? onAction;
  final bool busy;
  final bool liveRegion;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Semantics(
      liveRegion: liveRegion,
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(Space.md),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, color: iconColor),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: Space.xs),
                  Text(body, style: textStyle ?? theme.textTheme.bodyMedium),
                  if (action != null && onAction != null)
                    TextButton(onPressed: onAction, child: Text(action!)),
                  if (footnote != null) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      footnote!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main action on a published World's details: sign in, check the
/// location to unlock, continue, or play again.
class PlayActionButton extends ConsumerWidget {
  const PlayActionButton({required this.world, super.key});

  final WorldDetails world;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlock = ref.watch(unlockControllerProvider(world.id));
    final controller = ref.read(unlockControllerProvider(world.id).notifier);
    final status = world.playStatus;

    if (status == null) {
      return FilledButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('Sign in to unlock'),
        onPressed: () => context.push(
          AppRoutes.signInFrom(AppRoutes.worldDetails(world.id)),
        ),
      );
    }
    if (status == PlayStatus.inProgress ||
        unlock.phase == UnlockPhase.unlocked) {
      return FilledButton.icon(
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(status == PlayStatus.inProgress ? 'Continue' : 'Start'),
        onPressed: () => context.push(AppRoutes.play(world.id)),
      );
    }
    if (status == PlayStatus.completed) {
      return FilledButton.icon(
        icon: const Icon(Icons.replay),
        label: const Text('Play again'),
        onPressed: () =>
            context.push(AppRoutes.play(world.id, startOver: true)),
      );
    }
    return FilledButton.icon(
      icon: unlock.busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(
        unlock.phase == UnlockPhase.idle ? 'Check my location' : 'Check again',
      ),
      onPressed: unlock.busy
          ? null
          : () async {
              if (await controller.shouldExplainLocation()) {
                if (!context.mounted) return;
                final agreed = await confirmLocationUse(
                  context,
                  title: 'Unlock with your location',
                  message:
                      'WORLDS takes one reading, now, to check you are at this '
                      "World's place. It is not stored, not tracked in the "
                      'background and never shown to other people.',
                );
                if (!agreed) return;
              }
              await controller.check();
            },
    );
  }
}
