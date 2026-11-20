// Runs the app's player repository against the development project, as two
// test accounts: A publishes a small puzzle World, B unlocks and plays it.
// Not part of `flutter test`; run it on purpose:
//
//   flutter test test_live
//
// Needs `.env` and `tool/e2e/.accounts.json` (see the authoring live test).
// Everything it creates is deleted at the end, apart from B's progress row,
// which goes with the soft-deleted World from discovery.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/features/world_creation/data/supabase_world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_player/data/supabase_world_play_repository.dart';
import 'package:worlds/features/world_player/domain/play_models.dart';
import 'package:worlds/features/worlds/data/supabase_world_repository.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_details.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

Map<String, String> _env() => {
  for (final line in File('.env').readAsLinesSync())
    if (line.contains('=') && !line.trimLeft().startsWith('#'))
      line.substring(0, line.indexOf('=')).trim(): line
          .substring(line.indexOf('=') + 1)
          .trim(),
};

Future<SupabaseClient> _signIn(Map<String, dynamic> account) async {
  final env = _env();
  final client = SupabaseClient(
    env['SUPABASE_URL']!,
    env['SUPABASE_PUBLISHABLE_KEY']!,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.signInWithPassword(
    email: account['email'] as String,
    password: account['password'] as String,
  );
  return client;
}

void main() {
  final accountsFile = File('tool/e2e/.accounts.json');

  test(
    "the app's player works against the real backend",
    () async {
      final accounts =
          jsonDecode(accountsFile.readAsStringSync()) as Map<String, dynamic>;
      final a = await _signIn(accounts['a'] as Map<String, dynamic>);
      final b = await _signIn(accounts['b'] as Map<String, dynamic>);
      addTearDown(() async {
        await a.dispose();
        await b.dispose();
      });

      final authoringA = SupabaseWorldAuthoringRepository(a);
      final playB = SupabaseWorldPlayRepository(b);
      final worldsB = SupabaseWorldRepository(b);

      const place = GeoPoint(latitude: -41.03, longitude: -121.0);
      final worldId = newUuid();
      final textId = newUuid();
      final questionId = newUuid();
      final endId = newUuid();

      await authoringA.save(
        WorldDraft(
          id: worldId,
          category: WorldCategory.puzzle,
          title: '[e2e] Player check',
          description: 'Automated check of the app player, far out at sea.',
          location: place,
          blocks: [
            ContentBlock.text(id: textId, body: 'A lighthouse stands here.'),
            ContentBlock.question(
              id: questionId,
              prompt: 'Who lived here?',
              successMessage: 'Right, the keeper!',
            ),
            ContentBlock.completion(
              id: endId,
              title: 'Solved',
              message: 'Done.',
            ),
          ],
        ),
        answers: {questionId: 'Keeper'},
      );
      expect((await authoringA.publish(worldId)).published, isTrue);

      // Before unlocking: details say locked, content is refused.
      expect((await worldsB.details(worldId)).playStatus, PlayStatus.locked);
      await expectLater(
        playB.load(worldId),
        throwsA(const AppFailure.locked()),
      );

      // Too far, then near enough.
      final far = await playB.unlock(
        worldId,
        const LocationFix(
          point: GeoPoint(latitude: -41.032, longitude: -121.0),
          accuracyMeters: 10,
        ),
      );
      expect(far, isA<TooFar>());
      expect((far as TooFar).distanceMeters, closeTo(222, 10));

      final near = await playB.unlock(
        worldId,
        const LocationFix(point: place, accuracyMeters: 10),
      );
      expect(near, isA<Unlocked>());
      expect(
        (await worldsB.details(worldId)).playStatus,
        PlayStatus.inProgress,
      );

      // Play: content without the answer or success message.
      final session = await playB.load(worldId);
      expect(session.blocks, hasLength(3));
      expect((session.blocks[1] as QuestionBlock).successMessage, isEmpty);
      expect(session.currentBlock?.id, textId);

      var step = await playB.advance(worldId, fromBlockId: textId);
      expect(step.progress.currentBlockId, questionId);
      final retried = await playB.advance(worldId, fromBlockId: textId);
      expect(retried.stale, isTrue);

      await expectLater(
        playB.advance(worldId, fromBlockId: questionId),
        throwsA(const AppFailure.invalidContent()),
      );
      final wrong = await playB.answer(
        worldId,
        blockId: questionId,
        answer: 'the cook',
      );
      expect(wrong, isA<WrongAnswer>());
      expect((wrong as WrongAnswer).attemptsLeft, 4);
      final right = await playB.answer(
        worldId,
        blockId: questionId,
        answer: '  KEEPER ',
      );
      expect(right, isA<CorrectAnswer>());
      expect((right as CorrectAnswer).successMessage, 'Right, the keeper!');

      step = await playB.advance(worldId, fromBlockId: questionId);
      expect(step.progress.currentBlockId, endId);
      step = await playB.advance(worldId, fromBlockId: endId);
      expect(step.completed, isTrue);
      expect(step.progress.completionCount, 1);
      final again = await playB.advance(worldId, fromBlockId: endId);
      expect(again.progress.completionCount, 1);
      expect((await worldsB.details(worldId)).playStatus, PlayStatus.completed);

      // Progress survives a fresh load (as after an app restart).
      final reloaded = await playB.load(worldId);
      expect(reloaded.progress.completed, isTrue);

      final restarted = await playB.restart(worldId);
      expect(restarted.completed, isFalse);
      expect(restarted.currentBlockId, textId);
      expect(restarted.completionCount, 1);

      // Unpublished: no longer playable.
      await authoringA.unpublish(worldId);
      await expectLater(
        playB.load(worldId),
        throwsA(const AppFailure.notFound()),
      );

      await authoringA.delete(worldId);
    },
    skip: accountsFile.existsSync()
        ? false
        : 'No tool/e2e/.accounts.json; see the authoring live test.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
