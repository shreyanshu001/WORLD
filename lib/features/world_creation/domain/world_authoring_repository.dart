import 'package:worlds/core/media/picked_image.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/world_creation/domain/world_rules.dart';
import 'package:worlds/features/worlds/domain/world_status.dart';

/// The outcome of a publish request.
class PublishResult {
  const PublishResult({
    required this.status,
    required this.publishedAt,
    required this.problems,
  });

  final WorldStatus status;
  final DateTime? publishedAt;

  /// Empty when the World was published.
  final List<PublishProblem> problems;

  bool get published => status == WorldStatus.published;
}

/// Creates and edits the signed-in user's own Worlds.
///
/// Every method throws an `AppFailure` when it fails. Ids are chosen by the
/// app, so repeating a call after a timeout is safe.
abstract interface class WorldAuthoringRepository {
  /// The user's Worlds, newest change first. Deleted Worlds are not listed.
  Future<List<WorldSummary>> myWorlds();

  Future<WorldDraft> load(String worldId);

  /// Creates or replaces the World and all its blocks. [answers] maps
  /// question block ids to answers to set; they are hashed by the server and
  /// never come back.
  Future<WorldDraft> save(
    WorldDraft draft, {
    Map<String, String> answers = const {},
  });

  Future<PublishResult> publish(String worldId);

  /// Returns the World to draft, out of discovery.
  Future<PublishResult> unpublish(String worldId);

  /// Soft delete: the World disappears for everyone, including its creator.
  Future<void> delete(String worldId);

  /// Uploads [image] as asset [assetId] of the World and registers it.
  /// Repeating the call with the same [assetId] finishes a half-done upload.
  Future<WorldAsset> uploadImage({
    required String worldId,
    required String assetId,
    required PickedImage image,
  });

  /// Releases an image the World no longer uses and deletes its file.
  Future<void> discardImage(String assetId);
}
