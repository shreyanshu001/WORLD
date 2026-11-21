// Runs the app's player repository against the development project, as two
// test accounts: A publishes a small puzzle World with a picture, B unlocks
// and plays it.
// Not part of `flutter test`; run it on purpose:
//
//   flutter test test_live
//
// Needs `.env` and `tool/e2e/.accounts.json` (see the authoring live test).
// Everything it creates is deleted at the end, files included, apart from
// B's progress row, which goes with the soft-deleted World from discovery.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/media/picked_image.dart';
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

Future<int> _httpStatus(Uri url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(url)).close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close();
  }
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
      final mediaB = SupabaseWorldMediaRepository(b);

      const place = GeoPoint(latitude: -41.03, longitude: -121.0);
      final worldId = newUuid();
      final textId = newUuid();
      final imageId = newUuid();
      final questionId = newUuid();
      final endId = newUuid();
      final usedAssetId = newUuid();
      final spareAssetId = newUuid();

      // A draft first, so two pictures can be uploaded into it: one a part
      // will use, one that stays unused.
      final draft = WorldDraft(
        id: worldId,
        category: WorldCategory.puzzle,
        title: '[e2e] Player check',
        description: 'Automated check of the app player, far out at sea.',
        location: place,
      );
      await authoringA.save(draft);
      final png = PickedImage(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        ),
        format: ImageFormat.png,
      );
      final used = await authoringA.uploadImage(
        worldId: worldId,
        assetId: usedAssetId,
        image: png,
      );
      final spare = await authoringA.uploadImage(
        worldId: worldId,
        assetId: spareAssetId,
        image: png,
      );

      await authoringA.save(
        draft.copyWith(
          blocks: [
            ContentBlock.text(id: textId, body: 'A lighthouse stands here.'),
            ContentBlock.image(
              id: imageId,
              assetId: usedAssetId,
              caption: 'The lamp room',
            ),
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

      // Before unlocking: details say locked, content and pictures are
      // refused.
      expect((await worldsB.details(worldId)).playStatus, PlayStatus.locked);
      await expectLater(
        playB.load(worldId),
        throwsA(const AppFailure.locked()),
      );
      await expectLater(
        mediaB.imageUrl(used.storagePath),
        throwsA(isA<AppFailure>()),
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
      expect(session.blocks, hasLength(4));
      expect((session.blocks[2] as QuestionBlock).successMessage, isEmpty);
      expect(session.currentBlock?.id, textId);

      // The picture a part uses can be fetched through Storage; the one no
      // part uses cannot, and is not listed.
      expect(session.assetPaths, {usedAssetId: used.storagePath});
      final picture = await mediaB.imageUrl(used.storagePath);
      expect(await _httpStatus(picture), 200);
      await expectLater(
        mediaB.imageUrl(spare.storagePath),
        throwsA(isA<AppFailure>()),
      );

      var step = await playB.advance(worldId, fromBlockId: textId);
      expect(step.progress.currentBlockId, imageId);
      final retried = await playB.advance(worldId, fromBlockId: textId);
      expect(retried.stale, isTrue);
      step = await playB.advance(worldId, fromBlockId: imageId);
      expect(step.progress.currentBlockId, questionId);

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

      // Unpublished: no longer playable, and its pictures are closed again.
      await authoringA.unpublish(worldId);
      await expectLater(
        playB.load(worldId),
        throwsA(const AppFailure.notFound()),
      );
      await expectLater(
        mediaB.imageUrl(used.storagePath),
        throwsA(isA<AppFailure>()),
      );

      // Clean up: release both pictures, delete the World.
      await authoringA.save(draft);
      await authoringA.discardImage(usedAssetId);
      await authoringA.discardImage(spareAssetId);
      await authoringA.delete(worldId);
    },
    skip: accountsFile.existsSync()
        ? false
        : 'No tool/e2e/.accounts.json; see the authoring live test.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
