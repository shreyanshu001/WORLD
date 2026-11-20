// Runs the app's own Supabase repositories against the development project,
// as two test accounts. Not part of `flutter test`; run it on purpose:
//
//   flutter test test_live
//
// Needs `.env` (project URL and publishable key) and
// `tool/e2e/.accounts.json` (two test accounts, gitignored; created by
// `node tool/e2e/creator_to_explorer.mjs . tool/e2e/.accounts.json`).
// Everything it creates is deleted at the end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/media/picked_image.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/features/world_creation/data/supabase_world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/data/supabase_world_repository.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_repository.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
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
    "the app's repositories work against the real backend",
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
      final authoringB = SupabaseWorldAuthoringRepository(b);
      final worldsA = SupabaseWorldRepository(a);
      final worldsB = SupabaseWorldRepository(b);
      final mediaB = SupabaseWorldMediaRepository(b);

      const place = GeoPoint(latitude: -41.02, longitude: -121.0);
      const near = GeoPoint(latitude: -41.021, longitude: -121.0);
      final worldId = newUuid();
      final textId = newUuid();
      final questionId = newUuid();
      final assetId = newUuid();

      final draft = WorldDraft(
        id: worldId,
        category: WorldCategory.puzzle,
        title: '[e2e] App repository check',
        description: 'Automated check of the app data layer, far out at sea.',
        location: place,
        blocks: [
          ContentBlock.text(id: textId, body: 'Find the old lighthouse.'),
          ContentBlock.question(id: questionId, prompt: 'Who lived here?'),
        ],
      );

      // Save, retry, list and load through the app's codec.
      final saved = await authoringA.save(
        draft,
        answers: {questionId: 'Keeper'},
      );
      expect(saved.status, WorldStatus.draft);
      expect((saved.blocks[1] as QuestionBlock).hasAnswer, isTrue);
      final retried = await authoringA.save(saved);
      expect(retried.id, worldId);
      expect((retried.blocks[1] as QuestionBlock).hasAnswer, isTrue);
      final mine = await authoringA.myWorlds();
      expect(
        mine.where((w) => w.id == worldId).single.lifecycle,
        WorldLifecycle.draft,
      );
      final loaded = await authoringA.load(worldId);
      expect(loaded.blocks, retried.blocks);
      expect(loaded.location, place);

      // Upload, retry under the same id (the duplicate path), use as cover.
      final png = PickedImage(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        ),
        format: ImageFormat.png,
      );
      final asset = await authoringA.uploadImage(
        worldId: worldId,
        assetId: assetId,
        image: png,
      );
      final again = await authoringA.uploadImage(
        worldId: worldId,
        assetId: assetId,
        image: png,
      );
      expect(again, asset);
      final withCover = await authoringA.save(
        loaded.copyWith(coverAssetId: assetId),
      );
      expect(withCover.assetById(assetId)?.storagePath, asset.storagePath);

      // Publish, and find it as someone else.
      final published = await authoringA.publish(worldId);
      expect(published.published, isTrue, reason: '${published.problems}');
      final nearby = await worldsB.nearby(NearbyQuery(center: near));
      expect(nearby.map((w) => w.id), contains(worldId));
      final details = await worldsB.details(worldId, from: near);
      expect(details.isCreator, isFalse);
      expect(details.blockCount, 2);
      expect(details.coverPath, asset.storagePath);
      expect(details.distanceMeters, closeTo(111, 15));
      final url = await mediaB.imageUrl(details.coverPath!);
      expect(await _httpStatus(url), 200);
      expect((await worldsA.details(worldId)).isCreator, isTrue);

      // Someone else cannot read or change it.
      await expectLater(
        authoringB.load(worldId),
        throwsA(const AppFailure.notFound()),
      );
      await expectLater(
        authoringB.save(draft.copyWith(title: '[e2e] Taken over')),
        throwsA(const AppFailure.notFound()),
      );
      await expectLater(
        authoringB.publish(worldId),
        throwsA(const AppFailure.notFound()),
      );

      // Server validation reaches the app as its own failures.
      await expectLater(
        authoringA.save(withCover.copyWith(title: 'ab')),
        throwsA(const AppFailure.invalidContent()),
      );
      await expectLater(
        authoringA.save(withCover.copyWith(blocks: const [])),
        throwsA(const AppFailure.invalidContent()),
      );

      // Unpublish: gone from discovery for others.
      final unpublished = await authoringA.unpublish(worldId);
      expect(unpublished.status, WorldStatus.draft);
      expect(unpublished.publishedAt, published.publishedAt);
      await expectLater(
        worldsB.details(worldId),
        throwsA(const AppFailure.notFound()),
      );

      // Problems come back as typed codes and nothing is published.
      final incompleteId = newUuid();
      await authoringA.save(
        WorldDraft(
          id: incompleteId,
          category: WorldCategory.art,
          title: '[e2e] Incomplete',
        ),
      );
      final refused = await authoringA.publish(incompleteId);
      expect(refused.published, isFalse);
      expect(
        refused.problems.map((p) => p.code),
        containsAll([
          PublishProblemCode.descriptionRequired,
          PublishProblemCode.locationRequired,
          PublishProblemCode.contentRequired,
          PublishProblemCode.artworkRequired,
        ]),
      );

      // Clean up: release the image, delete both Worlds.
      await authoringA.save(withCover.copyWith(coverAssetId: null));
      await authoringA.discardImage(assetId);
      await authoringA.delete(worldId);
      await authoringA.delete(incompleteId);
      await expectLater(
        authoringA.load(worldId),
        throwsA(const AppFailure.notFound()),
      );
      await expectLater(
        authoringA.delete(worldId),
        throwsA(const AppFailure.notFound()),
      );
    },
    skip: accountsFile.existsSync()
        ? false
        : 'No tool/e2e/.accounts.json; see the comment at the top.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
