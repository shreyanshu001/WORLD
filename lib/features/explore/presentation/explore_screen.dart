import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(state: state, controller: controller),
            SizedBox(
              height: 4,
              child: state.loading
                  ? const LinearProgressIndicator(
                      semanticsLabel: 'Searching for Worlds',
                    )
                  : null,
            ),
            ExploreMessages(state: state, controller: controller),
            Expanded(
              child: IndexedStack(
                index: state.view == ExploreView.map ? 0 : 1,
                children: [
                  _MapPane(
                    state: state,
                    controller: controller,
                    mapAdapter: mapAdapter,
                    initialCamera: _initialCamera,
                    attribution: attribution,
                  ),
                  WorldList(state: state, controller: controller),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchField(onChanged: controller.updateSearchText),
              ),
              IconButton(
                tooltip: 'Find Worlds near me',
                onPressed: locating
                    ? null
                    : () => _findWorldsNearMe(context, controller),
                icon: locating
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Finding your location',
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
              IconButton(
                tooltip: showingMap ? 'Show as list' : 'Show on map',
                onPressed: () => controller.setView(
                  showingMap ? ExploreView.list : ExploreView.map,
                ),
                icon: Icon(showingMap ? Icons.view_list : Icons.map_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CategoryChips(
            selected: state.category,
            onSelected: controller.selectCategory,
          ),
        ],
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
        isDense: true,
        border: const OutlineInputBorder(),
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
  const _CategoryChips({required this.selected, required this.onSelected});

  final WorldCategory? selected;
  final ValueChanged<WorldCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
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
              if (selected != null)
                Padding(
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
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: theme.textTheme.labelSmall),
      ),
    );
  }
}
