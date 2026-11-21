import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';

/// Unlocks and plays Worlds for the signed-in user. The server validates
/// every step: position, choices, answers and completion.
///
/// Every method throws an `AppFailure`: `locked` before the World is
/// unlocked, `notFound` once it is no longer published.
abstract interface class WorldPlayRepository {
  /// Checks one fresh reading against the World's place. The position is
  /// sent once and not stored.
  Future<UnlockResult> unlock(String worldId, LocationFix fix);

  Future<PlaySession> load(String worldId);

  /// Moves on from [fromBlockId]; [optionId] picks a story choice.
  Future<StepResult> advance(
    String worldId, {
    required String fromBlockId,
    String? optionId,
  });

  Future<AnswerResult> answer(
    String worldId, {
    required String blockId,
    required String answer,
  });

  /// Starts again from the first part.
  Future<PlayProgress> restart(String worldId);
}
