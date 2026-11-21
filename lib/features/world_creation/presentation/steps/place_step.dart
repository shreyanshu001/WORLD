import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/core/maps/map_providers.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/core/widgets/location_explanation_dialog.dart';
import 'package:worlds/features/explore/application/explore_controller.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/application/world_editor_state.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// Places the World: the pin is always at the centre of the map, so moving
/// the map moves the place. The device location is read only when the
/// creator taps "Use my location".
class PlaceStep extends ConsumerStatefulWidget {
  const PlaceStep({required this.args, super.key});

  final WorldEditorArgs args;

  @override
  ConsumerState<PlaceStep> createState() => _PlaceStepState();
}

class _PlaceStepState extends ConsumerState<PlaceStep> {
  static const _worldView = MapCamera(
    target: GeoPoint(latitude: 20, longitude: 0),
    zoom: 1.5,
  );

  late final MapCamera _initialCamera;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(worldEditorProvider(widget.args)).draft?.location;
    final fallback = ref.read(exploreDefaultCenterProvider);
    _initialCamera = saved != null
        ? MapCamera(target: saved, zoom: WorldEditorController.placementZoom)
        : fallback != null
        ? MapCamera(target: fallback, zoom: 14)
        : _worldView;
  }

  @override
  Widget build(BuildContext context) {
    final provider = worldEditorProvider(widget.args);
    final draft = ref.watch(provider.select((s) => s.draft));
    final cameraRequest = ref.watch(provider.select((s) => s.cameraRequest));
    final mapAdapter = ref.watch(mapAdapterProvider);
    final attribution = ref.watch(mapStyleProvider).attribution;
    if (draft == null) return const SizedBox.shrink();
    final location = draft.location;

    // The map keeps at least 200 dp however large the text is; the controls
    // scroll in what is left. On a phone at 200% text it had shrunk to a
    // strip too thin to see the pin in.
    return LayoutBuilder(
      builder: (context, box) {
        final controlsMaxHeight = math.max(
          120.0,
          math.min(
            MediaQuery.sizeOf(context).height * 0.45,
            box.maxHeight - 200,
          ),
        );
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: mapAdapter.buildMap(
                      MapViewConfig(
                        initialCamera: _initialCamera,
                        markers: const [],
                        onMarkerTapped: (_) {},
                        onUserCameraIdle: ref
                            .read(provider.notifier)
                            .onPickerCameraIdle,
                        cameraRequest: cameraRequest,
                        areas: [
                          if (location != null)
                            MapArea(
                              center: location,
                              radiusMeters: draft.unlockRadiusMeters.toDouble(),
                              colorHex: draft.category.colorHex,
                            ),
                        ],
                      ),
                    ),
                  ),
                  // The tip of the pin marks the centre of the map.
                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -22),
                        child: Icon(
                          Icons.place,
                          size: 44,
                          color: draft.category.color,
                          semanticLabel:
                              'World location: the centre of the map',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: _Attribution(text: attribution),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: controlsMaxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _PlaceControls(args: widget.args),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UseMyLocationButton extends ConsumerWidget {
  const _UseMyLocationButton({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final locating = ref.watch(
      provider.select((s) => s.locationStatus == PickerLocationStatus.locating),
    );
    return FilledButton.tonalIcon(
      onPressed: locating
          ? null
          : () async {
              final controller = ref.read(provider.notifier);
              if (await controller.shouldExplainLocation()) {
                if (!context.mounted) return;
                final agreed = await confirmLocationUse(
                  context,
                  title: 'Use your location',
                  message:
                      'WORLDS reads your location once, now, to move the map '
                      'to where you are. It is not tracked in the background '
                      'and your position is never shown to other people.',
                );
                if (!agreed) return;
              }
              await controller.useCurrentLocation();
            },
      icon: locating
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Finding your location',
              ),
            )
          : const Icon(Icons.my_location),
      label: const Text('Use my location'),
    );
  }
}

class _PlaceControls extends ConsumerWidget {
  const _PlaceControls({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final controller = ref.read(provider.notifier);
    final location = ref.watch(provider.select((s) => s.draft?.location));
    final radius = ref.watch(
      provider.select(
        (s) => s.draft?.unlockRadiusMeters ?? WorldRules.radiusMin,
      ),
    );
    final zoomedIn = ref.watch(provider.select((s) => s.pickerZoomedIn));
    final theme = Theme.of(context);

    final placement = location == null
        ? 'Move the map and zoom in until the pin marks the exact spot.'
        : zoomedIn
        ? 'The pin marks your World. Move the map to adjust it.'
        : 'Zoom in further to move the pin precisely. The World stays where '
              'it was.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Under the map, not on it: on a 360 dp phone the button covered
        // the pin that marks the exact spot.
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _UseMyLocationButton(args: args),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              location == null ? Icons.touch_app_outlined : Icons.check_circle,
              color: location == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(placement)),
          ],
        ),
        _LocationMessage(args: args),
        const SizedBox(height: 12),
        Text('Unlock radius: $radius m', style: theme.textTheme.titleSmall),
        Slider(
          value: radius.toDouble(),
          min: WorldRules.radiusMin.toDouble(),
          max: WorldRules.radiusMax.toDouble(),
          divisions: (WorldRules.radiusMax - WorldRules.radiusMin) ~/ 5,
          label: '$radius m',
          semanticFormatterCallback: (value) =>
              'Unlock radius ${value.round()} metres',
          onChanged: (value) => controller.setRadius(value.round()),
        ),
        Text(
          'Explorers unlock the World within this distance of the pin. Phone '
          'GPS can be 10 to 30 m out, so a very small radius can be '
          'frustrating.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const _SafetyNote(),
      ],
    );
  }
}

class _LocationMessage extends ConsumerWidget {
  const _LocationMessage({required this.args});

  final WorldEditorArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = worldEditorProvider(args);
    final status = ref.watch(provider.select((s) => s.locationStatus));
    final controller = ref.read(provider.notifier);

    final (text, actionLabel, action) = switch (status) {
      PickerLocationStatus.idle ||
      PickerLocationStatus.locating => (null, null, null),
      PickerLocationStatus.denied => (
        'Location permission was refused. You can still place the World by '
            'moving the map.',
        null,
        null,
      ),
      PickerLocationStatus.deniedForever => (
        'Location is blocked for WORLDS. Move the map instead, or allow '
            'location in Settings.',
        'Open Settings',
        controller.openLocationSettings,
      ),
      PickerLocationStatus.serviceDisabled => (
        "Your phone's location is turned off.",
        'Turn on',
        controller.openLocationSettings,
      ),
      PickerLocationStatus.unavailable => (
        "We couldn't get your location. Move the map instead, or try again.",
        'Try again',
        controller.useCurrentLocation,
      ),
    };
    if (text == null) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Card.filled(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                const Icon(Icons.location_off_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
                if (actionLabel != null && action != null)
                  TextButton(onPressed: action, child: Text(actionLabel)),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close),
                  onPressed: controller.dismissLocationMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// docs/PRODUCT_SPEC.md section 10: only places people can visit lawfully
/// and safely.
class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Choose a public place anyone can reach safely, such as a park, '
              'square or public path. Never place a World in a private home '
              'or garden, a school, a restricted area, or anywhere dangerous '
              'to get to.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}
