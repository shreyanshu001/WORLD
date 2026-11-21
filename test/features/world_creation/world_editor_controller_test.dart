import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/location/location_providers.dart';
import 'package:worlds/core/location/location_service.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/core/media/media_providers.dart';
import 'package:worlds/features/auth/application/auth_providers.dart';
import 'package:worlds/features/auth/domain/auth_user.dart';
import 'package:worlds/features/world_creation/application/authoring_providers.dart';
import 'package:worlds/features/world_creation/application/world_editor_controller.dart';
import 'package:worlds/features/world_creation/application/world_editor_state.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

import '../../support/creation_fakes.dart';
import '../../support/explore_fakes.dart';
import '../../support/fakes.dart';

void main() {
  const worldId = '11111111-1111-4111-8111-111111111111';
  const args = (worldId: worldId, isNew: true);
  const place = GeoPoint(latitude: 51.5, longitude: -0.12);

  late FakeWorldAuthoringRepository repository;
  late FakeImagePickerService picker;
  late FakeLocationService location;
  late ProviderContainer container;

  setUp(() {
    repository = FakeWorldAuthoringRepository();
    picker = FakeImagePickerService();
    location = FakeLocationService();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(signedInAs: const AuthUser(id: 'alice')),
        ),
        worldAuthoringRepositoryProvider.overrideWithValue(repository),
        imagePickerServiceProvider.overrideWithValue(picker),
        locationServiceProvider.overrideWithValue(location),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    container.listen(worldEditorProvider(args), (_, _) {});
  });

  WorldEditorController editor() =>
      container.read(worldEditorProvider(args).notifier);
  WorldEditorState state() => container.read(worldEditorProvider(args));

  void startPuzzle() {
    editor()
      ..chooseCategory(WorldCategory.puzzle)
      ..updateTitle('Lighthouse Riddle');
  }

  test('a new World starts with nothing saved and no request made', () {
    expect(state().draft, isNull);
    expect(state().step, EditorStep.category);
    expect(repository.saves, isEmpty);
  });

  test('choosing a category starts the draft and moves to details', () {
    editor().chooseCategory(WorldCategory.story);
    expect(state().draft!.category, WorldCategory.story);
    expect(state().draft!.id, worldId);
    expect(state().step, EditorStep.details);
    expect(state().hasUnsavedChanges, isTrue);
  });

  test('saving twice updates one World under the same id', () async {
    startPuzzle();
    expect(await editor().save(), isTrue);
    editor().updateTitle('Lighthouse Riddle II');
    expect(await editor().save(), isTrue);

    expect(repository.worlds.keys, [worldId]);
    expect(repository.worlds[worldId]!.title, 'Lighthouse Riddle II');
    expect(state().hasUnsavedChanges, isFalse);
    expect(state().existsOnServer, isTrue);
  });

  test('a title that is too short is not sent', () async {
    editor()
      ..chooseCategory(WorldCategory.art)
      ..updateTitle('ab');
    expect(await editor().save(), isFalse);
    expect(repository.saves, isEmpty);
    expect(state().saveError, const AppFailure.invalidContent());
  });

  test('a failed save keeps the edits and can be retried', () async {
    startPuzzle();
    repository.nextSaveError = const AppFailure.offline();
    expect(await editor().save(), isFalse);
    expect(state().saveError, const AppFailure.offline());
    expect(state().draft!.title, 'Lighthouse Riddle');

    expect(await editor().save(), isTrue);
    expect(state().saveError, isNull);
  });

  test('an answer is sent once, then only "has an answer" is kept', () async {
    startPuzzle();
    final question = editor().addBlock(BlockType.question)!;
    editor().setAnswer(question, '  Lighthouse Keeper ');
    expect(state().pendingAnswerIds, {question});
    expect(state().toString(), isNot(contains('Keeper')));

    expect(await editor().save(), isTrue);
    expect(repository.saves.last.answers, {question: '  Lighthouse Keeper '});
    expect(state().pendingAnswerIds, isEmpty);
    expect(
      (state().draft!.blockById(question)! as QuestionBlock).hasAnswer,
      isTrue,
    );

    // The next save does not resend it.
    editor().updateTitle('Lighthouse Riddle II');
    await editor().save();
    expect(repository.saves.last.answers, isEmpty);
  });

  test('removing a block clears choices that led to it', () {
    editor().chooseCategory(WorldCategory.story);
    final choice = editor().addBlock(BlockType.storyChoice)!;
    final ending = editor().addBlock(BlockType.completion)!;
    final block = state().draft!.blockById(choice)! as StoryChoiceBlock;
    editor().updateBlock(
      block.copyWith(
        options: [
          block.options.first.copyWith(destinationBlockId: ending),
          block.options.last,
        ],
      ),
    );

    editor().removeBlock(ending);

    final updated = state().draft!.blockById(choice)! as StoryChoiceBlock;
    expect(updated.options.first.destinationBlockId, isNull);
    expect(state().draft!.blocks, hasLength(1));
  });

  test('blocks can be moved without dragging', () {
    editor().chooseCategory(WorldCategory.experience);
    final a = editor().addBlock(BlockType.text)!;
    final b = editor().addBlock(BlockType.image)!;
    final c = editor().addBlock(BlockType.completion)!;

    editor().moveBlock(2, 0);
    expect(state().draft!.blocks.map((x) => x.id), [c, a, b]);
    editor().moveBlock(0, 1);
    expect(state().draft!.blocks.map((x) => x.id), [a, c, b]);
  });

  test('the block limit is enforced', () {
    editor().chooseCategory(WorldCategory.experience);
    for (var i = 0; i < WorldRules.maxBlocks; i++) {
      expect(editor().addBlock(BlockType.text), isNotNull);
    }
    expect(editor().addBlock(BlockType.text), isNull);
  });

  test('changing category is refused when parts would not fit', () {
    editor().chooseCategory(WorldCategory.puzzle);
    editor().addBlock(BlockType.question);
    expect(editor().chooseCategory(WorldCategory.story), isFalse);
    expect(state().draft!.category, WorldCategory.puzzle);
    expect(editor().chooseCategory(WorldCategory.experience), isTrue);
  });

  test('the map centre becomes the place only when zoomed in', () {
    editor().chooseCategory(WorldCategory.story);
    editor().onPickerCameraIdle(const MapCamera(target: place, zoom: 12));
    expect(state().draft!.location, isNull);
    expect(state().pickerZoomedIn, isFalse);

    editor().onPickerCameraIdle(const MapCamera(target: place, zoom: 16));
    expect(state().draft!.location, place);
  });

  test('the radius stays within 25 to 150 m', () {
    editor().chooseCategory(WorldCategory.story);
    expect(state().draft!.unlockRadiusMeters, 50);
    editor().setRadius(5);
    expect(state().draft!.unlockRadiusMeters, 25);
    editor().setRadius(500);
    expect(state().draft!.unlockRadiusMeters, 150);
  });

  test('"use my location" reads one position, only when asked', () async {
    editor().chooseCategory(WorldCategory.story);
    expect(location.totalCalls, 0);

    location.permission = LocationPermissionStatus.granted;
    await editor().useCurrentLocation();

    expect(location.positionReads, 1);
    expect(state().draft!.location, location.position);
    expect(state().cameraRequest!.target, location.position);
  });

  test('refused location leaves the map usable', () async {
    editor().chooseCategory(WorldCategory.story);
    location.requestResult = LocationPermissionStatus.denied;
    await editor().useCurrentLocation();
    expect(state().locationStatus, PickerLocationStatus.denied);
    expect(state().draft!.location, isNull);
    expect(location.positionReads, 0);
  });

  test('publishing saves first, then publishes once', () async {
    startPuzzle();
    editor()
      ..updateDescription('A riddle at the lighthouse.')
      ..onPickerCameraIdle(const MapCamera(target: place, zoom: 17));
    final question = editor().addBlock(BlockType.question)!;
    final block = state().draft!.blockById(question)! as QuestionBlock;
    editor()
      ..updateBlock(block.copyWith(prompt: 'Who lived here?'))
      ..setAnswer(question, 'The keeper');

    expect(await editor().publish(), isTrue);

    expect(repository.saves, hasLength(1));
    expect(repository.publishes, [worldId]);
    expect(state().draft!.status, WorldStatus.published);
    expect(state().hasUnsavedChanges, isFalse);
  });

  test(
    'problems the server reports are kept and nothing is published',
    () async {
      startPuzzle();
      repository.nextPublishProblems = const [
        PublishProblem(PublishProblemCode.locationRequired),
      ];
      expect(await editor().publish(), isFalse);
      expect(state().serverProblems, const [
        PublishProblem(PublishProblemCode.locationRequired),
      ]);
      expect(state().draft!.status, WorldStatus.draft);
    },
  );

  test('a publish that times out can be retried safely', () async {
    startPuzzle();
    editor()
      ..updateDescription('A riddle.')
      ..onPickerCameraIdle(const MapCamera(target: place, zoom: 17));
    final question = editor().addBlock(BlockType.question)!;
    final block = state().draft!.blockById(question)! as QuestionBlock;
    editor()
      ..updateBlock(block.copyWith(prompt: 'Who?'))
      ..setAnswer(question, 'Keeper');
    repository.nextPublishError = const AppFailure.offline();

    expect(await editor().publish(), isFalse);
    expect(state().saveError, const AppFailure.offline());
    expect(await editor().publish(), isTrue);
    expect(repository.worlds.keys, [worldId]);
  });

  test(
    'unpublishing keeps the publish date, so it reads "Unpublished"',
    () async {
      startPuzzle();
      editor()
        ..updateDescription('A riddle.')
        ..onPickerCameraIdle(const MapCamera(target: place, zoom: 17));
      final question = editor().addBlock(BlockType.question)!;
      final block = state().draft!.blockById(question)! as QuestionBlock;
      editor()
        ..updateBlock(block.copyWith(prompt: 'Who?'))
        ..setAnswer(question, 'Keeper');
      await editor().publish();

      expect(await editor().unpublish(), isTrue);
      expect(state().draft!.lifecycle, WorldLifecycle.unpublished);
    },
  );

  test(
    'a cover upload saves the World first and uses a fixed id on retry',
    () async {
      editor()
        ..chooseCategory(WorldCategory.art)
        ..updateTitle('Harbour Mural');
      repository.nextUploadError = const AppFailure.uploadFailed();

      await editor().pickCover();
      expect(repository.saves, hasLength(1));
      expect(state().failedUploads, {coverUploadTarget});
      expect(state().draft!.coverAssetId, isNull);
      final firstAssetId = repository.uploads.single.assetId;

      await editor().retryUpload(coverUploadTarget);
      expect(repository.uploads.map((u) => u.assetId), [
        firstAssetId,
        firstAssetId,
      ]);
      expect(state().failedUploads, isEmpty);
      expect(state().draft!.coverAssetId, firstAssetId);
      expect(repository.worlds[worldId]!.coverAssetId, firstAssetId);
    },
  );

  test('an unsupported image is explained and nothing is uploaded', () async {
    editor()
      ..chooseCategory(WorldCategory.art)
      ..updateTitle('Harbour Mural');
    picker.nextError = const AppFailure.imageNotSupported();
    await editor().pickCover();
    expect(state().uploadError, const AppFailure.imageNotSupported());
    expect(repository.uploads, isEmpty);
  });

  test('cancelling the picker changes nothing', () async {
    editor()
      ..chooseCategory(WorldCategory.art)
      ..updateTitle('Harbour Mural');
    picker.next = null;
    await editor().pickCover();
    expect(repository.saves, isEmpty);
    expect(repository.uploads, isEmpty);
  });

  test('a replaced cover is released after saving', () async {
    editor()
      ..chooseCategory(WorldCategory.art)
      ..updateTitle('Harbour Mural');
    await editor().pickCover();
    final first = state().draft!.coverAssetId!;
    await editor().pickCover();
    final second = state().draft!.coverAssetId!;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(second, isNot(first));
    expect(repository.discarded, [first]);
    expect(state().draft!.assets.map((a) => a.id), [second]);
  });

  test('deleting marks the editor as done', () async {
    startPuzzle();
    await editor().save();
    expect(await editor().delete(), isTrue);
    expect(state().deleted, isTrue);
    expect(repository.deletes, [worldId]);
  });

  test('an existing World loads from the server', () async {
    const existing = (worldId: worldId, isNew: false);
    repository.worlds[worldId] = const WorldDraft(
      id: worldId,
      category: WorldCategory.story,
      title: 'Seeded',
    );
    container.listen(worldEditorProvider(existing), (_, _) {});
    expect(container.read(worldEditorProvider(existing)).loading, isTrue);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final loaded = container.read(worldEditorProvider(existing));
    expect(loaded.draft!.title, 'Seeded');
    expect(loaded.hasUnsavedChanges, isFalse);
  });
}
