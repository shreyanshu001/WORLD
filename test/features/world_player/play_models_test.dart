import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/play_fakes.dart';

void main() {
  test("progress reads the server's record", () {
    final progress = PlayProgress.fromServer({
      'status': 'completed',
      'current_block_id': 'right-end',
      'path': ['intro', 'choice', 'right', 'right-end'],
      'answered': ['q1'],
      'started_at': '2026-11-21T10:00:00Z',
      'completed_at': '2026-11-21T10:05:00Z',
      'completion_count': 2,
    });
    expect(progress.completed, isTrue);
    expect(progress.currentBlockId, 'right-end');
    expect(progress.path, hasLength(4));
    expect(progress.answered, ['q1']);
    expect(progress.completionCount, 2);

    final fresh = PlayProgress.fromServer({
      'status': 'in_progress',
      'current_block_id': 'intro',
      'path': ['intro'],
      'answered': <String>[],
    });
    expect(fresh.completed, isFalse);
    expect(fresh.completionCount, 0);
  });

  test('a session knows its current part', () {
    final session = PlaySession(
      worldId: 'w',
      title: 'Two Doors',
      category: WorldCategory.story,
      blocks: testStoryBlocks(),
      progress: const PlayProgress(completed: false, currentBlockId: 'right'),
    );
    expect(session.currentBlock?.id, 'right');
    expect(session.currentIndex, 3);
    expect(
      session
          .copyWith(progress: const PlayProgress(completed: true))
          .currentIndex,
      -1,
    );
  });
}
