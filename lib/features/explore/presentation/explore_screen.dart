import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/analytics/analytics_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/app/theme/app_tokens.dart';
import 'package:worlds/core/maps/map_adapter.dart';
import 'package:worlds/core/widgets/location_explanation_dialog.dart';
import 'package:worlds/core/maps/map_providers.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/features/explore/application/explore_controller.dart';
import 'package:worlds/features/explore/application/explore_state.dart';
import 'package:worlds/features/explore/presentation/explore_messages.dart';
import 'package:worlds/features/explore/presentation/world_list.dart';
import 'package:worlds/features/explore/presentation/world_preview_card.dart';
import 'package:worlds/shared/components/category_style.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';
import 'package:worlds/shared/components/motion.dart';

/// The Explore tab: a map of nearby published Worlds, with search, category
/// filters and a list view that works even if the map does not.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  /// Shown when no area has been chosen yet.
  static const worldViewCamera = MapCamera(
    target: GeoPoint(latitude: 20, longitude: 0),
    zoom: 1.5,
  );

  static const areaZoom = 13.0;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with WidgetsBindingObserver {
  late final MapCamera _initialCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(productAnalyticsProvider).exploreOpened();
    final center = ref.read(exploreControllerProvider).searchCenter;
    _initialCamera = center == null
        ? ExploreScreen.worldViewCamera
        : MapCamera(target: center, zoom: ExploreScreen.areaZoom);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(exploreControllerProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final controller = ref.read(exploreControllerProvider.notifier);
    final mapAdapter = ref.watch(mapAdapterProvider);
    final attribution = ref.watch(mapStyleProvider).attribution;

    final showingMap = state.view == ExploreView.map;

    // The map fills the screen; search and filters float over it. The map
    // stays alive (offstage) while the list is shown.
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Offstage(
              offstage: !showingMap,
              child: TickerMode(
                enabled: showingMap,
                child: _MapPane(
                  state: state,
                  controller: controller,
                  mapAdapter: mapAdapter,
                  initialCamera: _initialCamera,
                  attribution: attribution,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(state: state, controller: controller),
                  // Over the map, messages scroll if they cannot all fit
                  // (large text, a small screen). They take only the room
                  // they need, so the map under them stays reachable.
                  if (showingMap)
                    Flexible(
                      child: SingleChildScrollView(
                        child: ExploreMessages(
                          state: state,
                          controller: controller,
                        ),
                      ),
                    )
                  else ...[
                    ExploreMessages(state: state, controller: controller),
                    Expanded(
                      child: WorldList(state: state, controller: controller),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.controller});

  final ExploreState state;
  final ExploreController controller;

  @override
  Widget build(BuildContext context) {
    final locating = state.locationStatus == LocationStatus.locating;
    final showingMap = state.view == ExploreView.map;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Floating(
                  radius: Radii.lg,
                  child: _SearchField(onChanged: controller.updateSearchText),
                ),
              ),
              const SizedBox(width: Space.sm),
              _RoundButton(
                tooltip: 'Find Worlds near me',
                onPressed: locating
                    ? null
                    : () => _findWorldsNearMe(context, controller),
                child: locating
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Finding your location',
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
              const SizedBox(width: Space.sm),
              _RoundButton(
                tooltip: showingMap ? 'Show as list' : 'Show on map',
                onPressed: () => controller.setView(
                  showingMap ? ExploreView.list : ExploreView.map,
                ),
                child: Icon(
                  showingMap ? Icons.view_agenda_outlined : Icons.map_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm + 2),
          _CategoryChips(
            selected: state.category,
            onSelected: controller.selectCategory,
            floating: showingMap,
          ),
          SizedBox(
            height: Space.sm,
            child: state.loading
                ? const Padding(
                    padding: EdgeInsets.only(top: Space.xs),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        semanticsLabel: 'Searching for Worlds',
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// A raised surface that stays legible over the map.
class _Floating extends StatelessWidget {
  const _Floating({required this.child, this.radius = Radii.md});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      elevation: 3,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      elevation: 3,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.of(context).primary,
        padding: const EdgeInsets.all(Space.md),
        icon: child,
      ),
    );
  }
}

/// Explains why location is wanted before Android's prompt appears, then
/// locates only if the user agrees.
Future<void> _findWorldsNearMe(
  BuildContext context,
  ExploreController controller,
) async {
  if (await controller.shouldExplainLocation()) {
    if (!context.mounted) return;
    final agreed = await confirmLocationUse(
      context,
      title: 'Find Worlds near you',
      message:
          'WORLDS uses your location only when you tap this button, to show '
          'Worlds around you. It is not tracked in the background and is '
          'never shown to other people.',
    );
    if (!agreed) return;
  }
  await controller.locate();
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search Worlds by title',
        prefixIcon: const Icon(Icons.search),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: Space.lg),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.onSelected,
    required this.floating,
  });

  final WorldCategory? selected;
  final ValueChanged<WorldCategory?> onSelected;

  /// Over the map, chips get a shadow so they stay readable.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final elevation = floating ? 2.0 : 0.0;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        // Only five chips: build them all so none is rebuilt while scrolling.
        cacheExtent: 1000,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              elevation: elevation,
              shadowColor: Colors.black38,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in WorldCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(category.icon, size: 18, color: category.color),
                label: Text(category.label),
                selected: selected == category,
                elevation: elevation,
                shadowColor: Colors.black38,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPane extends StatelessWidget {
  const _MapPane({
    required this.state,
    required this.controller,
    required this.mapAdapter,
    required this.initialCamera,
    required this.attribution,
  });

  final ExploreState state;
  final ExploreController controller;
  final MapAdapter mapAdapter;
  final MapCamera initialCamera;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedWorld;
    return Stack(
      children: [
        Positioned.fill(
          child: mapAdapter.buildMap(
            MapViewConfig(
              initialCamera: initialCamera,
              markers: [
                for (final world in state.worlds)
                  MapMarker(
                    id: world.id,
                    point: world.point,
                    colorHex: world.category.colorHex,
                  ),
              ],
              selectedMarkerId: state.selectedWorldId,
              userLocation: state.userLocation,
              cameraRequest: state.cameraRequest,
              onMarkerTapped: controller.selectWorld,
              onUserCameraIdle: controller.onUserCameraIdle,
              onMapTapped: () => controller.selectWorld(null),
            ),
          ),
        ),
        // The preview card sits above the attribution line, never over it.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The card rises into place when a World is selected and
              // fades from one World to the next. Only the card moves: the
              // map under it is never animated.
              StateSwitcher(
                fill: false,
                alignment: Alignment.bottomCenter,
                from: const Offset(0, 0.12),
                child: selected == null
                    ? const SizedBox(
                        key: ValueKey('no-preview'),
                        width: double.infinity,
                      )
                    : Padding(
                        key: ValueKey('preview-${selected.id}'),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: WorldPreviewCard(
                          world: selected,
                          fromUserLocation: state.centerIsUserLocation,
                          onClose: () => controller.selectWorld(null),
                          onOpen: () => context.push(
                            AppRoutes.worldDetails(selected.id),
                            extra: state.userLocation,
                          ),
                        ),
                      ),
              ),
              _MapAttribution(text: attribution),
            ],
          ),
        ),
      ],
    );
  }
}

/// Always-visible map attribution, as the tile provider's terms require.
class _MapAttribution extends StatelessWidget {
  const _MapAttribution({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Space.sm, 0, Space.sm, Space.xs),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: theme.textTheme.labelSmall),
      ),
    );
  }
}
