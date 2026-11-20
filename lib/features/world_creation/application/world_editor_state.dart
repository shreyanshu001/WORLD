import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/maps/map_types.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';

part 'world_editor_state.freezed.dart';

/// The creator's steps, in order.
enum EditorStep {
  category('Type'),
  details('Details'),
  location('Place'),
  content('Content'),
  review('Publish');

  const EditorStep(this.label);

  final String label;
}

/// Where "use my current location" stands in the place picker.
enum PickerLocationStatus {
  idle,
  locating,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

/// The upload target for a World's cover image.
const coverUploadTarget = 'cover';

@freezed
abstract class WorldEditorState with _$WorldEditorState {
  const factory WorldEditorState({
    required String worldId,

    /// What the creator is editing; null until a category is chosen for a
    /// new World, or while an existing World loads.
    WorldDraft? draft,

    /// The copy last confirmed by the server; null if never saved.
    WorldDraft? saved,
    @Default(false) bool loading,
    AppFailure? loadError,
    @Default(EditorStep.category) EditorStep step,
    @Default(false) bool saving,
    AppFailure? saveError,

    /// Questions whose new answer will be sent with the next save. The
    /// answers themselves are kept out of this state so they are never
    /// logged or shown.
    @Default(<String>{}) Set<String> pendingAnswerIds,

    /// Upload targets in progress: block ids, or [coverUploadTarget].
    @Default(<String>{}) Set<String> uploading,

    /// Upload targets whose last upload failed and can be retried.
    @Default(<String>{}) Set<String> failedUploads,
    AppFailure? uploadError,
    @Default(false) bool publishing,

    /// Problems the server reported on the last publish attempt.
    @Default(<PublishProblem>[]) List<PublishProblem> serverProblems,
    @Default(PickerLocationStatus.idle) PickerLocationStatus locationStatus,

    /// Moves the place picker's map once.
    CameraRequest? cameraRequest,

    /// False when the place picker was last left too far out to place the
    /// pin precisely.
    @Default(true) bool pickerZoomedIn,
    @Default(false) bool deleted,
  }) = _WorldEditorState;

  const WorldEditorState._();

  bool get existsOnServer => saved != null;

  bool get hasUnsavedChanges =>
      draft != null && (draft != saved || pendingAnswerIds.isNotEmpty);

  bool get busy => saving || publishing || uploading.isNotEmpty;

  /// What still blocks publishing, as far as the app can tell.
  List<PublishProblem> get publishProblems => draft == null
      ? const []
      : WorldRules.publishProblems(draft!, pendingAnswerIds: pendingAnswerIds);
}
