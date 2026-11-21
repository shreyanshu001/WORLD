import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/core/network/storage_buckets.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/features/worlds/domain/world_preview.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// [WorldRepository] backed by Supabase.
///
/// Nearby search runs in PostGIS (`get_nearby_worlds`). Remote procedure
/// calls are POST requests, so coordinates travel in the request body, not
/// in URLs that proxies and servers log.
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

  @override
  Future<WorldDetails> details(String worldId, {GeoPoint? from}) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>?>(
        'get_world_details',
        params: {
          'world_id': worldId,
          'from_lat': from?.latitude,
          'from_lon': from?.longitude,
        },
      );
      if (json == null) throw const AppFailure.notFound();
      return WorldDetails.fromJson(json);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }
}

/// [WorldMediaRepository] backed by Supabase Storage signed URLs.
class SupabaseWorldMediaRepository implements WorldMediaRepository {
  SupabaseWorldMediaRepository(this._client);

  /// How long a signed address stays valid.
  static const urlLifetime = Duration(hours: 1);

  final SupabaseClient _client;

  @override
  Future<Uri> imageUrl(String storagePath) async {
    try {
      final url = await _client.storage
          .from(StorageBuckets.worldMedia)
          .createSignedUrl(storagePath, urlLifetime.inSeconds);
      return Uri.parse(url);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }
}
