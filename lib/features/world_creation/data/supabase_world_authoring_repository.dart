import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/media/picked_image.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/core/network/storage_buckets.dart';
import 'package:worlds/features/world_creation/domain/world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_draft_codec.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';

/// [WorldAuthoringRepository] backed by the database functions in
/// `20261120090000_create_world_authoring.sql` and the private
/// `world-media` bucket. Clients cannot write the tables directly.
class SupabaseWorldAuthoringRepository implements WorldAuthoringRepository {
  SupabaseWorldAuthoringRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppFailure.unauthenticated();
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<List<WorldSummary>> myWorlds() => _guard(() async {
    final rows = await _client
        .from('worlds')
        .select('id, title, category, status, published_at, updated_at')
        .eq('creator_id', _userId)
        .neq('status', 'deleted')
        .order('updated_at', ascending: false);
    return rows.map(WorldDraftCodec.summaryFromRow).toList(growable: false);
  });

  @override
  Future<WorldDraft> load(String worldId) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'get_world_draft',
      params: {'world_id': worldId},
    );
    return WorldDraftCodec.fromServer(json);
  });

  @override
  Future<WorldDraft> save(
    WorldDraft draft, {
    Map<String, String> answers = const {},
  }) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'save_world',
      params: {
        'world': WorldDraftCodec.toSaveJson(draft),
        'question_answers': answers,
      },
    );
    return WorldDraftCodec.fromServer(json);
  });

  @override
  Future<PublishResult> publish(String worldId) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'publish_world',
      params: {'world_id': worldId},
    );
    return _publishResult(json);
  });

  @override
  Future<PublishResult> unpublish(String worldId) => _guard(() async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'unpublish_world',
      params: {'world_id': worldId},
    );
    return _publishResult(json);
  });

  @override
  Future<void> delete(String worldId) => _guard(
    () => _client.rpc<void>('delete_world', params: {'world_id': worldId}),
  );

  @override
  Future<WorldAsset> uploadImage({
    required String worldId,
    required String assetId,
    required PickedImage image,
  }) => _guard(() async {
    final path = '$_userId/$worldId/$assetId.${image.format.extension}';
    try {
      await _client.storage
          .from(StorageBuckets.worldMedia)
          .uploadBinary(
            path,
            image.bytes,
            fileOptions: FileOptions(contentType: image.format.mimeType),
          );
    } on StorageException catch (error) {
      // A retry after the file arrived but registration failed: the file is
      // already there, so carry on and register it.
      if (error.statusCode != '409') rethrow;
    }
    final json = await _client.rpc<Map<String, dynamic>>(
      'register_world_asset',
      params: {'asset_id': assetId, 'world_id': worldId, 'storage_path': path},
    );
    return WorldAsset(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      mimeType: json['mime_type'] as String,
    );
  });

  @override
  Future<void> discardImage(String assetId) => _guard(() async {
    final path = await _client.rpc<String>(
      'forget_world_asset',
      params: {'asset_id': assetId},
    );
    await _client.storage.from(StorageBuckets.worldMedia).remove([path]);
  });

  static PublishResult _publishResult(Map<String, dynamic> json) {
    final publishedAt = json['published_at'];
    return PublishResult(
      status: WorldStatus.values.byName(json['status'] as String),
      publishedAt: publishedAt is String ? DateTime.parse(publishedAt) : null,
      problems: [
        for (final problem in json['problems'] as List<dynamic>? ?? const [])
          PublishProblem(
            PublishProblemCode.fromWire(
              (problem as Map<String, dynamic>)['code'] as String,
            ),
            blockId: problem['block_id'] as String?,
          ),
      ],
    );
  }
}
