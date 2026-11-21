import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/features/saved/domain/saved_world.dart';
import 'package:worlds/features/saved/domain/saved_worlds_repository.dart';
import 'package:worlds/shared/models/geo_point.dart';

/// [SavedWorldsRepository] backed by the database functions
/// `get_saved_worlds` and `set_world_saved`. Positions travel in request
/// bodies, never in URLs.
class SupabaseSavedWorldsRepository implements SavedWorldsRepository {
  SupabaseSavedWorldsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SavedPage> list({int offset = 0, GeoPoint? from}) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'get_saved_worlds',
        params: {
          'page_size': SavedWorldsRepository.pageSize,
          'page_offset': offset,
          'from_lat': from?.latitude,
          'from_lon': from?.longitude,
        },
      );
      return SavedPage.fromJson(json);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<void> setSaved(String worldId, {required bool saved}) async {
    try {
      await _client.rpc<Map<String, dynamic>>(
        'set_world_saved',
        params: {'world_id': worldId, 'saved': saved},
      );
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }
}
