import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';

/// [WorldRepository] backed by Supabase.
///
/// Nearby search runs in PostGIS (`get_nearby_worlds`). Remote procedure
/// calls are POST requests, so the search coordinates travel in the request
/// body, not in URLs that proxies and servers log.
class SupabaseWorldRepository implements WorldRepository {
  SupabaseWorldRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<WorldPreview>> nearby(NearbyQuery query) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'get_nearby_worlds',
        params: {
          'user_lat': query.center.latitude,
          'user_lon': query.center.longitude,
          'radius_meters': query.radiusMeters,
          'category_filter': query.category?.name,
          'search_text': query.searchText,
        },
      );
      return rows
          .cast<Map<String, dynamic>>()
          .map(WorldPreview.fromJson)
          .toList(growable: false);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }
}
