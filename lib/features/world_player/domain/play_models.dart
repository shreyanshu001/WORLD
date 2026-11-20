import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/shared/models/world_category.dart';

part 'play_models.freezed.dart';

/// The server's record of how far an account has got in a World. Every
/// change is validated by the server; the app only displays it.
@freezed
abstract class PlayProgress with _$PlayProgress {
  const factory PlayProgress({
    required bool completed,
    String? currentBlockId,
    @Default(<String>[]) List<String> path,
    @Default(<String>[]) List<String> answered,
    @Default(0) int completionCount,
  }) = _PlayProgress;

  factory PlayProgress.fromServer(Map<String, dynamic> json) => PlayProgress(
    completed: json['status'] == 'completed',
    currentBlockId: json['current_block_id'] as String?,
    path: [
      for (final id in json['path'] as List<dynamic>? ?? const []) id as String,
    ],
    answered: [
      for (final id in json['answered'] as List<dynamic>? ?? const [])
        id as String,
    ],
    completionCount: (json['completion_count'] as num?)?.toInt() ?? 0,
  );
}

/// An unlocked World as the player sees it: its parts in order, without
/// answers, and where the account stands.
@freezed
abstract class PlaySession with _$PlaySession {
  const factory PlaySession({
    required String worldId,
    required String title,
    required WorldCategory category,
    String? coverPath,
    required List<ContentBlock> blocks,

    /// Storage paths of the images the parts use, by asset id.
    @Default(<String, String>{}) Map<String, String> assetPaths,
    required PlayProgress progress,
  }) = _PlaySession;

  const PlaySession._();

  ContentBlock? get currentBlock {
    final id = progress.currentBlockId;
    for (final block in blocks) {
      if (block.id == id) return block;
    }
    return null;
  }

  /// Position of the current part, from 0, or -1 when finished or unknown.
  int get currentIndex =>
      blocks.indexWhere((block) => block.id == progress.currentBlockId);
}

/// The outcome of checking the user's position against a World's place.
sealed class UnlockResult {
  const UnlockResult();
}

class Unlocked extends UnlockResult {
  const Unlocked({required this.progress});

  final PlayProgress progress;
}

class TooFar extends UnlockResult {
  const TooFar({required this.distanceMeters, required this.radiusMeters});

  final double distanceMeters;
  final int radiusMeters;
}

/// The reading was too vague to decide.
class Inaccurate extends UnlockResult {
  const Inaccurate({required this.accuracyMeters});

  final double accuracyMeters;
}

/// The outcome of submitting an answer. The accepted answer is never part
/// of it.
sealed class AnswerResult {
  const AnswerResult();
}

class CorrectAnswer extends AnswerResult {
  const CorrectAnswer({this.successMessage});

  final String? successMessage;
}

class WrongAnswer extends AnswerResult {
  const WrongAnswer({required this.attemptsLeft});

  final int attemptsLeft;
}

class AnswerRateLimited extends AnswerResult {
  const AnswerRateLimited({required this.retryAfter});

  final Duration retryAfter;
}

/// The outcome of moving to the next part.
class StepResult {
  const StepResult({
    required this.progress,
    required this.completed,
    required this.stale,
  });

  final PlayProgress progress;
  final bool completed;

  /// The server's progress had already moved on (for example after a retry);
  /// nothing changed and [progress] is the authoritative state.
  final bool stale;
}
