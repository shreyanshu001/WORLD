import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_providers.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/core/media/media_providers.dart';
import 'package:worlds/core/media/picked_image.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/features/world_creation/application/authoring_providers.dart';
import 'package:worlds/features/world_creation/application/world_editor_state.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/application/world_providers.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// Which World the editor works on. A new World's id is chosen by the app
/// before anything is saved, so retries never create a second World.
typedef WorldEditorArgs = ({String worldId, bool isNew});

final worldEditorProvider = NotifierProvider.autoDispose
    .family<WorldEditorController, WorldEditorState, WorldEditorArgs>(
      WorldEditorController.new,
    );

/// Keeps the creator's draft and talks to the server for it.
///
/// Everything the creator types stays in memory until they save; saving
/// sends the whole World in one request. Puzzle answers are held only in a
/// private field until that request, and are never read back.
class WorldEditorController extends Notifier<WorldEditorState> {
  WorldEditorController(this.args);

  final WorldEditorArgs args;

  /// Below this zoom the centre pin is too imprecise to place a World.
  static const minPlacementZoom = 15.0;
  static const placementZoom = 17.0;
  static const locationTimeout = Duration(seconds: 15);

  final _answers = <String, String>{};
  final _failedUploads =
      <String, ({String assetId, PickedImage image, _ApplyAsset apply})>{};
  int _cameraSequence = 0;

  @override
  WorldEditorState build() {
    if (args.isNew) return WorldEditorState(worldId: args.worldId);
    scheduleMicrotask(_load);
    return WorldEditorState(
      worldId: args.worldId,
      loading: true,
      step: EditorStep.content,
    );
  }

  WorldDraft get _draft => state.draft!;

  void _edit(WorldDraft Function(WorldDraft draft) change) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: change(draft),
      saveError: null,
      serverProblems: const [],
    );
  }

  // ---------------------------------------------------------------------------
  // Loading and steps
  // ---------------------------------------------------------------------------

  Future<void> retryLoad() => _load();

  Future<void> _load() async {
    if (!ref.mounted) return;
    state = state.copyWith(loading: true, loadError: null);
    try {
      final draft = await ref
          .read(worldAuthoringRepositoryProvider)
          .load(args.worldId);
      if (!ref.mounted) return;
      state = state.copyWith(draft: draft, saved: draft, loading: false);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, loadError: _failure(error));
    }
  }

  /// Steps after the first need a category chosen.
  void goTo(EditorStep step) {
    if (state.draft == null && step != EditorStep.category) return;
    state = state.copyWith(step: step);
  }

  // ---------------------------------------------------------------------------
  // Details
  // ---------------------------------------------------------------------------

  /// Sets the category. Returns false, changing nothing, if some blocks are
  /// not allowed in [category].
  bool chooseCategory(WorldCategory category) {
    final draft = state.draft;
    if (draft == null) {
      state = state.copyWith(
        draft: WorldDraft(id: args.worldId, category: category),
        step: EditorStep.details,
      );
      return true;
    }
    final allowed = WorldRules.allowedBlocks(category);
    if (draft.blocks.any((block) => !allowed.contains(block.type))) {
      return false;
    }
    _edit((d) => d.copyWith(category: category));
    return true;
  }

  void updateTitle(String title) => _edit((d) => d.copyWith(title: title));

  void updateDescription(String description) =>
      _edit((d) => d.copyWith(description: description));

  // ---------------------------------------------------------------------------
  // Place
  // ---------------------------------------------------------------------------

  void setRadius(int meters) => _edit(
    (d) => d.copyWith(
      unlockRadiusMeters: meters.clamp(
        WorldRules.radiusMin,
        WorldRules.radiusMax,
      ),
    ),
  );

  /// The creator moved the picker map. Its centre becomes the World's place
  /// once the map is zoomed in far enough to be precise.
  void onPickerCameraIdle(MapCamera camera) {
    final zoomedIn = camera.zoom >= minPlacementZoom;
    state = state.copyWith(pickerZoomedIn: zoomedIn);
    if (zoomedIn) _edit((d) => d.copyWith(location: camera.target));
  }

  /// Whether "use my current location" will show Android's prompt, so the
  /// app should first explain why it wants location.
  Future<bool> shouldExplainLocation() async {
    final location = ref.read(locationServiceProvider);
    try {
      if (!await location.isServiceEnabled()) return false;
      return await location.checkPermission() ==
          LocationPermissionStatus.denied;
    } on Object {
      return false;
    }
  }

  /// One position sample, taken only because the creator asked. The World
  /// is placed there and the map moves to it.
  Future<void> useCurrentLocation() async {
    if (state.locationStatus == PickerLocationStatus.locating) return;
    final location = ref.read(locationServiceProvider);
    state = state.copyWith(locationStatus: PickerLocationStatus.locating);
    void finish(PickerLocationStatus status) {
      if (ref.mounted) state = state.copyWith(locationStatus: status);
    }

    try {
      if (!await location.isServiceEnabled()) {
        return finish(PickerLocationStatus.serviceDisabled);
      }
      var permission = await location.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      switch (permission) {
        case LocationPermissionStatus.denied:
          return finish(PickerLocationStatus.denied);
        case LocationPermissionStatus.deniedForever:
          return finish(PickerLocationStatus.deniedForever);
        case LocationPermissionStatus.granted:
          break;
      }
      final point = await location.currentPosition(timeLimit: locationTimeout);
      if (!ref.mounted) return;
      state = state.copyWith(
        locationStatus: PickerLocationStatus.idle,
        pickerZoomedIn: true,
        cameraRequest: CameraRequest(
          id: ++_cameraSequence,
          target: point,
          zoom: placementZoom,
        ),
      );
      _edit((d) => d.copyWith(location: point));
    } on Object {
      finish(PickerLocationStatus.unavailable);
    }
  }

  Future<void> openLocationSettings() async {
    final location = ref.read(locationServiceProvider);
    if (state.locationStatus == PickerLocationStatus.serviceDisabled) {
      await location.openLocationSettings();
    } else {
      await location.openAppSettings();
    }
  }

  void dismissLocationMessage() =>
      state = state.copyWith(locationStatus: PickerLocationStatus.idle);

  /// Moves the picker to [point], for example the World's saved place.
  void showOnPicker(GeoPoint point) {
    state = state.copyWith(
      cameraRequest: CameraRequest(
        id: ++_cameraSequence,
        target: point,
        zoom: placementZoom,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  /// Adds a block at the end. Returns its id, or null at the block limit.
  String? addBlock(BlockType type) {
    final draft = state.draft;
    if (draft == null || draft.blocks.length >= WorldRules.maxBlocks) {
      return null;
    }
    final id = newUuid();
    final block = switch (type) {
      BlockType.text => ContentBlock.text(id: id),
      BlockType.image => ContentBlock.image(id: id),
      BlockType.storyChoice => ContentBlock.storyChoice(
        id: id,
        options: [
          StoryOption(id: newUuid()),
          StoryOption(id: newUuid()),
        ],
      ),
      BlockType.question => ContentBlock.question(id: id),
      BlockType.artwork => ContentBlock.artwork(id: id),
      BlockType.completion => ContentBlock.completion(id: id),
    };
    _edit((d) => d.copyWith(blocks: [...d.blocks, block]));
    return id;
  }

  void updateBlock(ContentBlock block) => _edit(
    (d) => d.copyWith(
      blocks: [for (final b in d.blocks) b.id == block.id ? block : b],
    ),
  );

  /// Removes a block and any choice that led to it.
  void removeBlock(String blockId) {
    _answers.remove(blockId);
    _failedUploads.remove(blockId);
    state = state.copyWith(
      pendingAnswerIds: _answers.keys.toSet(),
      failedUploads: _failedUploads.keys.toSet(),
    );
    _edit(
      (d) => d.copyWith(
        blocks: [
          for (final block in d.blocks)
            if (block.id != blockId)
              if (block is StoryChoiceBlock)
                block.copyWith(
                  options: [
                    for (final option in block.options)
                      option.destinationBlockId == blockId
                          ? option.copyWith(destinationBlockId: null)
                          : option,
                  ],
                )
              else
                block,
        ],
      ),
    );
  }

  /// Moves the block at [from] so it ends up at index [to].
  void moveBlock(int from, int to) {
    final blocks = [..._draft.blocks];
    if (from < 0 || from >= blocks.length) return;
    final target = to.clamp(0, blocks.length - 1);
    if (target == from) return;
    blocks.insert(target, blocks.removeAt(from));
    _edit((d) => d.copyWith(blocks: blocks));
  }

  /// Sets the answer to send with the next save. An empty answer cancels it.
  void setAnswer(String blockId, String answer) {
    if (answer.trim().isEmpty) {
      _answers.remove(blockId);
    } else {
      _answers[blockId] = answer;
    }
    state = state.copyWith(
      pendingAnswerIds: _answers.keys.toSet(),
      serverProblems: const [],
    );
  }

  // ---------------------------------------------------------------------------
  // Saving, publishing and deleting
  // ---------------------------------------------------------------------------

  /// Saves the whole World. Returns whether the server confirmed it.
  Future<bool> save() async {
    final draft = state.draft;
    if (draft == null || state.saving) return false;
    if (WorldRules.titleError(draft.title) != null) {
      state = state.copyWith(saveError: const AppFailure.invalidContent());
      return false;
    }
    final answers = Map.of(_answers);
    state = state.copyWith(saving: true, saveError: null);
    try {
      final result = await ref
          .read(worldAuthoringRepositoryProvider)
          .save(draft, answers: answers);
      if (!ref.mounted) return true;
      for (final MapEntry(:key, :value) in answers.entries) {
        if (_answers[key] == value) _answers.remove(key);
      }
      final current = state.draft!;
      state = state.copyWith(
        saving: false,
        saved: result,
        draft: current == draft ? result : _keepEdits(current, result),
        pendingAnswerIds: _answers.keys.toSet(),
        serverProblems: const [],
      );
      _refreshLists();
      unawaited(_discardUnusedImages());
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(saving: false, saveError: _failure(error));
      }
      return false;
    }
  }

  /// The creator kept typing while a save was in flight: keep their edits,
  /// but take what only the server knows.
  WorldDraft _keepEdits(WorldDraft local, WorldDraft server) {
    final answered = {
      for (final block in server.blocks)
        if (block is QuestionBlock && block.hasAnswer) block.id,
    };
    return local.copyWith(
      status: server.status,
      publishedAt: server.publishedAt,
      assets: server.assets,
      blocks: [
        for (final block in local.blocks)
          if (block is QuestionBlock && answered.contains(block.id))
            block.copyWith(hasAnswer: true)
          else
            block,
      ],
    );
  }

  /// Saves if needed, then publishes. Returns whether the World is live.
  ///
  /// Publishing an already published World succeeds again on the server,
  /// so retrying after a timeout cannot publish twice.
  Future<bool> publish() async {
    if (state.draft == null || state.busy) return false;
    if (state.hasUnsavedChanges || !state.existsOnServer) {
      if (!await save()) return false;
    }
    state = state.copyWith(publishing: true, serverProblems: const []);
    try {
      final result = await ref
          .read(worldAuthoringRepositoryProvider)
          .publish(args.worldId);
      if (!ref.mounted) return result.published;
      if (!result.published) {
        state = state.copyWith(
          publishing: false,
          serverProblems: result.problems,
        );
        return false;
      }
      _setStatus(result.status, result.publishedAt);
      state = state.copyWith(publishing: false);
      _refreshLists();
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(publishing: false, saveError: _failure(error));
      }
      return false;
    }
  }

  /// Takes the World off the map. Returns whether the server confirmed it.
  Future<bool> unpublish() async {
    if (state.busy) return false;
    state = state.copyWith(publishing: true, saveError: null);
    try {
      final result = await ref
          .read(worldAuthoringRepositoryProvider)
          .unpublish(args.worldId);
      if (!ref.mounted) return true;
      _setStatus(result.status, result.publishedAt);
      state = state.copyWith(publishing: false);
      _refreshLists();
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(publishing: false, saveError: _failure(error));
      }
      return false;
    }
  }

  /// Deletes the World for everyone. Returns whether the server confirmed.
  Future<bool> delete() async {
    if (state.busy) return false;
    state = state.copyWith(saving: true, saveError: null);
    try {
      if (state.existsOnServer) {
        await ref.read(worldAuthoringRepositoryProvider).delete(args.worldId);
      }
      if (!ref.mounted) return true;
      state = state.copyWith(saving: false, deleted: true);
      _refreshLists();
      return true;
    } on NotFoundFailure {
      // Already deleted, for example by an earlier attempt that timed out.
      if (ref.mounted) state = state.copyWith(saving: false, deleted: true);
      _refreshLists();
      return true;
    } on Object catch (error) {
      if (ref.mounted) {
        state = state.copyWith(saving: false, saveError: _failure(error));
      }
      return false;
    }
  }

  void _setStatus(WorldStatus status, DateTime? publishedAt) {
    WorldDraft? update(WorldDraft? d) =>
        d?.copyWith(status: status, publishedAt: publishedAt);
    state = state.copyWith(
      draft: update(state.draft),
      saved: update(state.saved),
    );
  }

  void _refreshLists() {
    ref.invalidate(myWorldsProvider);
    ref.invalidate(worldDetailsProvider);
  }

  // ---------------------------------------------------------------------------
  // Images
  // ---------------------------------------------------------------------------

  Future<void> pickCover() => _pickImage(
    coverUploadTarget,
    (draft, assetId) => draft.copyWith(coverAssetId: assetId),
  );

  void removeCover() => _edit((d) => d.copyWith(coverAssetId: null));

  Future<void> pickBlockImage(String blockId) =>
      _pickImage(blockId, (draft, assetId) {
        final block = draft.blockById(blockId);
        final updated = switch (block) {
          ImageBlock() => block.copyWith(assetId: assetId),
          ArtworkBlock() => block.copyWith(assetId: assetId),
          CompletionBlock() => block.copyWith(assetId: assetId),
          _ => null,
        };
        if (updated == null) return draft;
        return draft.copyWith(
          blocks: [for (final b in draft.blocks) b.id == blockId ? updated : b],
        );
      });

  void removeBlockImage(String blockId) {
    final block = _draft.blockById(blockId);
    if (block is CompletionBlock) updateBlock(block.copyWith(assetId: null));
  }

  /// Uploads the last failed image for [target] again, under the same id.
  Future<void> retryUpload(String target) async {
    final failed = _failedUploads[target];
    if (failed == null) return;
    await _upload(target, failed.assetId, failed.image, failed.apply);
  }

  Future<void> _pickImage(String target, _ApplyAsset apply) async {
    if (state.draft == null || state.uploading.contains(target)) return;
    state = state.copyWith(uploadError: null);
    final PickedImage? image;
    try {
      image = await ref.read(imagePickerServiceProvider).pickPhoto();
    } on Object catch (error) {
      if (ref.mounted) state = state.copyWith(uploadError: _failure(error));
      return;
    }
    if (image == null || !ref.mounted) return;
    // Files go into the World's own folder, which the server only allows
    // once the World exists.
    if (!state.existsOnServer && !await save()) return;
    await _upload(target, newUuid(), image, apply);
  }

  Future<void> _upload(
    String target,
    String assetId,
    PickedImage image,
    _ApplyAsset apply,
  ) async {
    state = state.copyWith(
      uploading: {...state.uploading, target},
      uploadError: null,
    );
    try {
      final asset = await ref
          .read(worldAuthoringRepositoryProvider)
          .uploadImage(worldId: args.worldId, assetId: assetId, image: image);
      if (!ref.mounted) return;
      _failedUploads.remove(target);
      state = state.copyWith(
        uploading: {...state.uploading}..remove(target),
        failedUploads: _failedUploads.keys.toSet(),
      );
      _edit((d) => apply(d.copyWith(assets: [...d.assets, asset]), asset.id));
      await save();
    } on Object catch (error) {
      if (!ref.mounted) return;
      _failedUploads[target] = (assetId: assetId, image: image, apply: apply);
      state = state.copyWith(
        uploading: {...state.uploading}..remove(target),
        failedUploads: _failedUploads.keys.toSet(),
        uploadError: _failure(error),
      );
    }
  }

  /// Releases images that neither the saved World nor the open draft uses.
  /// Best effort: a failure leaves the file for a later clean-up.
  Future<void> _discardUnusedImages() async {
    final saved = state.saved;
    final draft = state.draft;
    if (saved == null || draft == null) return;
    final inUse = {...saved.usedAssetIds, ...draft.usedAssetIds};
    final unused = [
      for (final asset in saved.assets)
        if (!inUse.contains(asset.id)) asset.id,
    ];
    for (final assetId in unused) {
      try {
        await ref.read(worldAuthoringRepositoryProvider).discardImage(assetId);
      } on Object {
        continue;
      }
      if (!ref.mounted) return;
      List<WorldAsset> without(List<WorldAsset> assets) => [
        for (final asset in assets)
          if (asset.id != assetId) asset,
      ];
      state = state.copyWith(
        saved: state.saved?.copyWith(assets: without(state.saved!.assets)),
        draft: state.draft?.copyWith(assets: without(state.draft!.assets)),
      );
    }
  }

  static AppFailure _failure(Object error) =>
      error is AppFailure ? error : const AppFailure.unexpected();
}

typedef _ApplyAsset = WorldDraft Function(WorldDraft draft, String assetId);
