import 'dart:typed_data';

import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/media/image_picker_service.dart';
import 'package:worlds/core/media/picked_image.dart';
import 'package:worlds/features/world_creation/domain/world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';

/// A tiny valid JPEG header, enough for format detection.
final testJpeg = PickedImage(
  bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10]),
  format: ImageFormat.jpeg,
);

/// In-memory [WorldAuthoringRepository] that behaves like the server: it
/// stores whole Worlds, keeps answers out of what it returns, and applies
/// the publishing rules.
class FakeWorldAuthoringRepository implements WorldAuthoringRepository {
  final worlds = <String, WorldDraft>{};

  /// Question ids with a stored answer, and the answers (as a server would
  /// keep hashes; tests check what arrived).
  final storedAnswers = <String, String>{};
  final saves = <({WorldDraft draft, Map<String, String> answers})>[];
  final publishes = <String>[];
  final unpublishes = <String>[];
  final deletes = <String>[];
  final uploads = <({String worldId, String assetId})>[];
  final discarded = <String>[];

  /// Thrown, then cleared, by the next call of that kind.
  Object? nextSaveError;
  Object? nextPublishError;
  Object? nextUploadError;
  Object? nextLoadError;

  /// Problems the next publish reports instead of applying the rules.
  List<PublishProblem>? nextPublishProblems;

  DateTime now = DateTime.utc(2026, 11, 20, 12);

  Future<void> _tick() => Future<void>.delayed(Duration.zero);

  WorldDraft _withAnswers(WorldDraft draft) => draft.copyWith(
    blocks: [
      for (final block in draft.blocks)
        if (block is QuestionBlock)
          block.copyWith(hasAnswer: storedAnswers.containsKey(block.id))
        else
          block,
    ],
  );

  @override
  Future<List<WorldSummary>> myWorlds() async {
    await _tick();
    return [
      for (final w in worlds.values)
        if (w.status != WorldStatus.deleted)
          WorldSummary(
            id: w.id,
            title: w.title,
            category: w.category,
            status: w.status,
            publishedAt: w.publishedAt,
            updatedAt: now,
          ),
    ];
  }

  @override
  Future<WorldDraft> load(String worldId) async {
    await _tick();
    if (nextLoadError case final error?) {
      nextLoadError = null;
      throw error;
    }
    final world = worlds[worldId];
    if (world == null || world.status == WorldStatus.deleted) {
      throw const AppFailure.notFound();
    }
    return _withAnswers(world);
  }

  @override
  Future<WorldDraft> save(
    WorldDraft draft, {
    Map<String, String> answers = const {},
  }) async {
    saves.add((draft: draft, answers: Map.of(answers)));
    await _tick();
    if (nextSaveError case final error?) {
      nextSaveError = null;
      throw error;
    }
    final existing = worlds[draft.id];
    if (existing?.status == WorldStatus.deleted) {
      throw const AppFailure.notFound();
    }
    final ids = {for (final b in draft.blocks) b.id};
    storedAnswers
      ..removeWhere(
        (id, _) => !ids.contains(id) || draft.blockById(id) is! QuestionBlock,
      )
      ..addAll(answers);
    final stored = draft.copyWith(
      title: draft.title.trim(),
      status: existing?.status ?? WorldStatus.draft,
      publishedAt: existing?.publishedAt,
      assets: existing?.assets ?? draft.assets,
    );
    worlds[draft.id] = stored;
    return _withAnswers(stored);
  }

  @override
  Future<PublishResult> publish(String worldId) async {
    publishes.add(worldId);
    await _tick();
    if (nextPublishError case final error?) {
      nextPublishError = null;
      throw error;
    }
    final world = worlds[worldId]!;
    final problems =
        nextPublishProblems ?? WorldRules.publishProblems(_withAnswers(world));
    nextPublishProblems = null;
    if (problems.isNotEmpty) {
      return PublishResult(
        status: world.status,
        publishedAt: world.publishedAt,
        problems: problems,
      );
    }
    final published = world.copyWith(
      status: WorldStatus.published,
      publishedAt: world.publishedAt ?? now,
    );
    worlds[worldId] = published;
    return PublishResult(
      status: WorldStatus.published,
      publishedAt: published.publishedAt,
      problems: const [],
    );
  }

  @override
  Future<PublishResult> unpublish(String worldId) async {
    unpublishes.add(worldId);
    await _tick();
    final world = worlds[worldId]!.copyWith(status: WorldStatus.draft);
    worlds[worldId] = world;
    return PublishResult(
      status: WorldStatus.draft,
      publishedAt: world.publishedAt,
      problems: const [],
    );
  }

  @override
  Future<void> delete(String worldId) async {
    deletes.add(worldId);
    await _tick();
    final world = worlds[worldId];
    if (world == null || world.status == WorldStatus.deleted) {
      throw const AppFailure.notFound();
    }
    worlds[worldId] = world.copyWith(status: WorldStatus.deleted);
  }

  @override
  Future<WorldAsset> uploadImage({
    required String worldId,
    required String assetId,
    required PickedImage image,
  }) async {
    uploads.add((worldId: worldId, assetId: assetId));
    await _tick();
    if (nextUploadError case final error?) {
      nextUploadError = null;
      throw error;
    }
    final asset = WorldAsset(
      id: assetId,
      storagePath: 'owner/$worldId/$assetId.${image.format.extension}',
      mimeType: image.format.mimeType,
    );
    final world = worlds[worldId]!;
    if (!world.assets.any((a) => a.id == assetId)) {
      worlds[worldId] = world.copyWith(assets: [...world.assets, asset]);
    }
    return asset;
  }

  @override
  Future<void> discardImage(String assetId) async {
    discarded.add(assetId);
    await _tick();
    for (final MapEntry(:key, :value) in worlds.entries.toList()) {
      worlds[key] = value.copyWith(
        assets: [
          for (final a in value.assets)
            if (a.id != assetId) a,
        ],
      );
    }
  }
}

/// [ImagePickerService] whose answer the test sets.
class FakeImagePickerService implements ImagePickerService {
  PickedImage? next = testJpeg;
  Object? nextError;
  int picks = 0;

  @override
  Future<PickedImage?> pickPhoto() async {
    picks++;
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return next;
  }
}
