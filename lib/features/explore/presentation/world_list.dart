import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:worlds/app/router/app_routes.dart';
import 'package:worlds/core/utils/distance_format.dart';
import 'package:worlds/core/widgets/empty_view.dart';
import 'package:worlds/features/explore/application/explore_controller.dart';
import 'package:worlds/features/explore/application/explore_state.dart';
import 'package:worlds/shared/components/category_style.dart';

/// The search results as a list: an accessible alternative to the map that
/// works even if the map cannot load.
class WorldList extends StatelessWidget {
  const WorldList({required this.state, required this.controller, super.key});

  final ExploreState state;
  final ExploreController controller;

  @override
  Widget build(BuildContext context) {
    if (state.searchCenter == null) {
      return const EmptyView(
        icon: Icons.travel_explore,
        title: 'No area chosen yet',
        message: 'Find Worlds near you with the location button.',
      );
    }
    if (state.worlds.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: state.loading ? 'Searching…' : 'No Worlds found',
        message: state.loading ? null : 'Try another area or category.',
      );
    }

    final distanceSuffix = state.centerIsUserLocation
        ? 'away'
        : 'from the map centre';
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.worlds.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final world = state.worlds[index];
        return ListTile(
          leading: Icon(world.category.icon, color: world.category.color),
          title: Text(world.title),
          subtitle: Text(
            '${world.category.label} · by ${world.creatorName} · '
            '${formatDistance(world.distanceMeters)} $distanceSuffix',
          ),
          trailing: IconButton(
            tooltip: 'View details of ${world.title}',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => context.push(
              AppRoutes.worldDetails(world.id),
              extra: state.userLocation,
            ),
          ),
          onTap: () => controller.showWorldOnMap(world.id),
        );
      },
    );
  }
}
