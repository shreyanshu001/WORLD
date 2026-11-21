import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/world_player/domain/world_play_repository.dart';
import 'package:worlds/features/worlds/domain/content_block_codec.dart';
import 'package:worlds/shared/models/world_category.dart';

/// [WorldPlayRepository] backed by the database functions in
/// `20261121051737_create_world_play.sql`. Positions travel in request
/// bodies (remote procedure calls are POST requests), never in URLs.
class SupabaseWorldPlayRepository implements WorldPlayRepository {
  SupabaseWorldPlayRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _call(
    String function,
    Map<String, Object?> params,
  ) async {
    try {
      return await _client.rpc<Map<String, dynamic>>(function, params: params);
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }

  @override
  Future<UnlockResult> unlock(String worldId, LocationFix fix) async {
    final json = await _call('unlock_world', {
      'world_id': worldId,
      'latitude': fix.point.latitude,
      'longitude': fix.point.longitude,
      'accuracy_meters': fix.accuracyMeters,
    });
    return switch (json['result']) {
      'unlocked' => Unlocked(
        progress: PlayProgress.fromServer(
          json['progress'] as Map<String, dynamic>,
        ),
      ),
      'too_far' => TooFar(
        distanceMeters: (json['distance_meters'] as num).toDouble(),
        radiusMeters: (json['unlock_radius_meters'] as num).toInt(),
      ),
      _ => Inaccurate(accuracyMeters: fix.accuracyMeters),
    };
  }

  @override
  Future<PlaySession> load(String worldId) async {
    final json = await _call('get_world_play', {'world_id': worldId});
    final world = json['world'] as Map<String, dynamic>;
    return PlaySession(
      worldId: world['id'] as String,
      title: world['title'] as String,
      category: WorldCategory.values.byName(world['category'] as String),
      coverPath: world['cover_path'] as String?,
      blocks: [
        for (final block in json['blocks'] as List<dynamic>)
          ContentBlockCodec.fromJson(block as Map<String, dynamic>),
      ],
      assetPaths: {
        for (final asset in json['assets'] as List<dynamic>? ?? const [])
          (asset as Map<String, dynamic>)['id'] as String:
              asset['storage_path'] as String,
      },
      progress: PlayProgress.fromServer(
        json['progress'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<StepResult> advance(
    String worldId, {
    required String fromBlockId,
    String? optionId,
  }) async {
    final json = await _call('advance_world', {
      'world_id': worldId,
      'from_block_id': fromBlockId,
      'option_id': optionId,
    });
    return StepResult(
      progress: PlayProgress.fromServer(
        json['progress'] as Map<String, dynamic>,
      ),
      completed: json['completed'] as bool? ?? false,
      stale: json['stale'] as bool? ?? false,
    );
  }

  @override
  Future<AnswerResult> answer(
    String worldId, {
    required String blockId,
    required String answer,
  }) async {
    final json = await _call('answer_question', {
      'world_id': worldId,
      'block_id': blockId,
      'answer': answer,
    });
    if (json['correct'] == true) {
      return CorrectAnswer(successMessage: json['success_message'] as String?);
    }
    if (json['rate_limited'] == true) {
      return AnswerRateLimited(
        retryAfter: Duration(
          seconds: (json['retry_after_seconds'] as num?)?.toInt() ?? 60,
        ),
      );
    }
    return WrongAnswer(
      attemptsLeft: (json['attempts_left'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<PlayProgress> restart(String worldId) async => PlayProgress.fromServer(
    await _call('restart_world', {'world_id': worldId}),
  );
}
