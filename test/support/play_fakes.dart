import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/world_player/domain/world_play_repository.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A story: intro, choice (left ending, or right text then right ending).
List<ContentBlock> testStoryBlocks() => const [
  ContentBlock.text(id: 'intro', body: 'Two doors stand before you.'),
  ContentBlock.storyChoice(
    id: 'choice',
    prompt: 'Which door?',
    options: [
      StoryOption(
        id: 'o-left',
        label: 'The left door',
        destinationBlockId: 'left',
      ),
      StoryOption(
        id: 'o-right',
        label: 'The right door',
        destinationBlockId: 'right',
      ),
    ],
  ),
  ContentBlock.completion(id: 'left', title: 'The garden', message: 'Roses.'),
  ContentBlock.text(id: 'right', body: 'A long corridor.'),
  ContentBlock.completion(
    id: 'right-end',
    title: 'The library',
    message: 'Books.',
  ),
];

/// A puzzle: text, question (answer "keeper"), ending.
List<ContentBlock> testPuzzleBlocks() => const [
  ContentBlock.text(id: 'p-text', body: 'A lighthouse stands here.'),
  ContentBlock.question(id: 'p-q', prompt: 'Who lived here?', hint: 'One word'),
  ContentBlock.completion(id: 'p-end', title: 'Solved', message: 'Well done.'),
];

/// In-memory [WorldPlayRepository] that follows the server's rules: steps
/// only from the current part, choices to their destinations, questions
/// answered first, five wrong answers then a pause, idempotent completion.
class FakeWorldPlayRepository implements WorldPlayRepository {
  final blocksByWorld = <String, List<ContentBlock>>{};
  final titles = <String, String>{};
  final progress = <String, PlayProgress>{};
  final answers = <String, String>{};
  final successMessages = <String, String>{};
  final wrongAttempts = <String, int>{};

  /// What the next unlock reports; unlocking creates progress.
  UnlockResult Function(LocationFix fix)? nextUnlock;
  final unlockFixes = <LocationFix>[];
  int loads = 0;
  final steps = <({String from, String? option})>[];
  final submitted = <String>[];

  /// Thrown, then cleared, by the next call of that kind.
  Object? nextLoadError;
  Object? nextStepError;

  /// The next step reports "stale" without changing anything.
  bool nextStepStale = false;

  void addWorld(
    String id,
    List<ContentBlock> blocks, {
    String title = 'Two Doors',
    bool unlocked = false,
  }) {
    blocksByWorld[id] = blocks;
    titles[id] = title;
    if (unlocked) _start(id);
  }

  PlayProgress _start(String id) => progress[id] = PlayProgress(
    completed: false,
    currentBlockId: blocksByWorld[id]!.first.id,
    path: [blocksByWorld[id]!.first.id],
  );

  Future<void> _tick() => Future<void>.delayed(Duration.zero);

  @override
  Future<UnlockResult> unlock(String worldId, LocationFix fix) async {
    unlockFixes.add(fix);
    await _tick();
    final result =
        nextUnlock?.call(fix) ??
        const TooFar(distanceMeters: 240, radiusMeters: 50);
    if (result is Unlocked) {
      final started = progress[worldId] ?? _start(worldId);
      return Unlocked(progress: started);
    }
    return result;
  }

  @override
  Future<PlaySession> load(String worldId) async {
    loads++;
    await _tick();
    if (nextLoadError case final error?) {
      nextLoadError = null;
      throw error;
    }
    final blocks = blocksByWorld[worldId];
    if (blocks == null) throw const AppFailure.notFound();
    final current = progress[worldId];
    if (current == null) throw const AppFailure.locked();
    return PlaySession(
      worldId: worldId,
      title: titles[worldId]!,
      category: WorldCategory.story,
      blocks: blocks,
      progress: current,
    );
  }

  @override
  Future<StepResult> advance(
    String worldId, {
    required String fromBlockId,
    String? optionId,
  }) async {
    steps.add((from: fromBlockId, option: optionId));
    await _tick();
    if (nextStepError case final error?) {
      nextStepError = null;
      throw error;
    }
    final current = progress[worldId]!;
    if (nextStepStale) {
      nextStepStale = false;
      return StepResult(progress: current, completed: false, stale: true);
    }
    if (current.completed) {
      return StepResult(progress: current, completed: true, stale: false);
    }
    if (current.currentBlockId != fromBlockId) {
      return StepResult(progress: current, completed: false, stale: true);
    }
    final blocks = blocksByWorld[worldId]!;
    final index = blocks.indexWhere((b) => b.id == fromBlockId);
    final block = blocks[index];
    String? next;
    switch (block) {
      case StoryChoiceBlock(:final options):
        final option = options.where((o) => o.id == optionId).firstOrNull;
        if (option == null) throw const AppFailure.invalidContent();
        next = option.destinationBlockId;
      case QuestionBlock():
        if (!current.answered.contains(block.id)) {
          throw const AppFailure.invalidContent();
        }
        next = index + 1 < blocks.length ? blocks[index + 1].id : null;
      case CompletionBlock():
        next = null;
      default:
        next = index + 1 < blocks.length ? blocks[index + 1].id : null;
    }
    final updated = next == null
        ? current.copyWith(
            completed: true,
            completionCount: current.completionCount + 1,
          )
        : current.copyWith(currentBlockId: next, path: [...current.path, next]);
    progress[worldId] = updated;
    return StepResult(progress: updated, completed: next == null, stale: false);
  }

  @override
  Future<AnswerResult> answer(
    String worldId, {
    required String blockId,
    required String answer,
  }) async {
    submitted.add(answer);
    await _tick();
    final current = progress[worldId]!;
    if (current.answered.contains(blockId)) {
      return CorrectAnswer(successMessage: successMessages[blockId]);
    }
    final wrong = wrongAttempts[blockId] ?? 0;
    if (wrong >= 5) {
      return const AnswerRateLimited(retryAfter: Duration(minutes: 7));
    }
    if (answer.trim().toLowerCase() == answers[blockId]) {
      progress[worldId] = current.copyWith(
        answered: [...current.answered, blockId],
      );
      return CorrectAnswer(successMessage: successMessages[blockId]);
    }
    wrongAttempts[blockId] = wrong + 1;
    return WrongAnswer(attemptsLeft: 5 - wrong - 1);
  }

  @override
  Future<PlayProgress> restart(String worldId) async {
    await _tick();
    final previous = progress[worldId]!;
    final first = blocksByWorld[worldId]!.first.id;
    return progress[worldId] = PlayProgress(
      completed: false,
      currentBlockId: first,
      path: [first],
      completionCount: previous.completionCount,
    );
  }
}
