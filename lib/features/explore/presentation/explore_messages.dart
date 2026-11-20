import 'package:flutter/material.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/explore/application/explore_controller.dart';
import 'package:worlds/features/explore/application/explore_state.dart';

/// Short messages under the search bar: location problems, search errors,
/// and what to do when there is nothing to show.
class ExploreMessages extends StatelessWidget {
  const ExploreMessages({
    required this.state,
    required this.controller,
    super.key,
  });

  final ExploreState state;
  final ExploreController controller;

  @override
  Widget build(BuildContext context) {
    final messages = <Widget>[?_locationMessage(), ?_resultsMessage()];
    if (messages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: messages),
    );
  }

  Widget? _locationMessage() => switch (state.locationStatus) {
    LocationStatus.denied => _MessageBanner(
      icon: Icons.location_disabled,
      text:
          'Location was not allowed. You can still explore by moving the map.',
      onDismiss: controller.dismissLocationMessage,
    ),
    LocationStatus.deniedForever => _MessageBanner(
      icon: Icons.location_disabled,
      text:
          'Location is blocked for WORLDS. Allow it in Settings to find '
          'Worlds near you, or keep exploring by moving the map.',
      actionLabel: 'Settings',
      onAction: controller.openLocationSettings,
      onDismiss: controller.dismissLocationMessage,
    ),
    LocationStatus.serviceDisabled => _MessageBanner(
      icon: Icons.location_off,
      text: 'Location services are turned off on this device.',
      actionLabel: 'Turn on',
      onAction: controller.openLocationSettings,
      onDismiss: controller.dismissLocationMessage,
    ),
    LocationStatus.unavailable => _MessageBanner(
      icon: Icons.location_searching,
      text: "We couldn't get your location.",
      actionLabel: 'Try again',
      onAction: controller.locate,
      onDismiss: controller.dismissLocationMessage,
    ),
    LocationStatus.notRequested ||
    LocationStatus.locating ||
    LocationStatus.located => null,
  };

  Widget? _resultsMessage() {
    final error = state.error;
    if (error != null) {
      return _MessageBanner(
        icon: Icons.error_outline,
        text: "Couldn't load Worlds. ${error.userMessage}",
        actionLabel: 'Try again',
        onAction: controller.retry,
        isError: true,
      );
    }
    if (state.searchCenter == null) {
      return const _MessageBanner(
        icon: Icons.travel_explore,
        text:
            'Tap the location button to find Worlds near you, or zoom the map '
            'in on a place.',
      );
    }
    if (state.searched && !state.loading && state.worlds.isEmpty) {
      return _MessageBanner(
        icon: Icons.search_off,
        text: state.hasFilters
            ? 'No Worlds within 5 km match. Try another category or search.'
            : 'No Worlds within 5 km here yet. Try another area.',
      );
    }
    return null;
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Semantics(
      liveRegion: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 4),
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: TextStyle(color: foreground)),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Dismiss',
                  icon: Icon(Icons.close, color: foreground),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
