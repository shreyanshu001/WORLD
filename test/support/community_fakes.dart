import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/features/moderation/domain/report.dart';
import 'package:worlds/features/moderation/domain/report_repository.dart';
import 'package:worlds/features/saved/domain/saved_world.dart';
import 'package:worlds/features/saved/domain/saved_worlds_repository.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

/// A saved World for tests.
SavedWorld testSaved(
  String id,
  String title, {
  WorldCategory category = WorldCategory.story,
  String creator = 'alice',
  String? creatorDisplayName = 'Alice',
  double? distanceMeters,
}) => SavedWorld(
  id: id,
  title: title,
  category: category,
  creatorUsername: creator,
  creatorDisplayName: creatorDisplayName,
  distanceMeters: distanceMeters,
  savedAt: DateTime.utc(2026, 11, 21),
);

/// In-memory [SavedWorldsRepository] that keeps one list per account, as
/// the server does: it answers for whoever [currentUserId] says is asking.
class FakeSavedWorldsRepository implements SavedWorldsRepository {
  FakeSavedWorldsRepository({required this.currentUserId});

  final String? Function() currentUserId;

  /// Saved Worlds by user id, newest first.
  final savedByUser = <String, List<SavedWorld>>{};

  /// Published Worlds that can be saved, by id.
  final catalogue = <String, SavedWorld>{};

  /// Reported as "not available at the moment".
  int unavailable = 0;

  /// Worlds per page; small values let tests page with few Worlds.
  int pageSize = SavedWorldsRepository.pageSize;

  final listRequests = <({int offset, GeoPoint? from})>[];
  final setRequests = <({String worldId, bool saved})>[];

  /// Thrown, then cleared, by the next call of that kind.
  Object? nextListError;
  Object? nextSetError;

  List<SavedWorld> _mine() {
    final user = currentUserId();
    if (user == null) throw const AppFailure.permissionDenied();
    return savedByUser.putIfAbsent(user, () => []);
  }

  /// Saves [world] for [userId] directly, as if done earlier.
  void seed(String userId, List<SavedWorld> worlds) {
    savedByUser.putIfAbsent(userId, () => []).addAll(worlds);
    for (final world in worlds) {
      catalogue[world.id] = world;
    }
  }

  @override
  Future<SavedPage> list({int offset = 0, GeoPoint? from}) async {
    listRequests.add((offset: offset, from: from));
    await Future<void>.delayed(Duration.zero);
    if (nextListError case final error?) {
      nextListError = null;
      throw error;
    }
    final mine = _mine();
    final page = mine.skip(offset).take(pageSize).toList();
    return SavedPage(
      items: page,
      hasMore: offset + page.length < mine.length,
      unavailable: unavailable,
    );
  }

  @override
  Future<void> setSaved(String worldId, {required bool saved}) async {
    setRequests.add((worldId: worldId, saved: saved));
    await Future<void>.delayed(Duration.zero);
    if (nextSetError case final error?) {
      nextSetError = null;
      throw error;
    }
    final mine = _mine();
    mine.removeWhere((world) => world.id == worldId);
    if (!saved) return;
    final world = catalogue[worldId];
    if (world == null) throw const AppFailure.notFound();
    mine.insert(0, world);
  }
}

/// In-memory [ReportRepository]: one waiting report per World, like the
/// server.
class FakeReportRepository implements ReportRepository {
  final sent = <({String worldId, ReportReason reason, String? details})>[];

  /// Thrown, then cleared, by the next report.
  Object? nextError;

  @override
  Future<ReportOutcome> report(
    String worldId, {
    required ReportReason reason,
    String? details,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    if (sent.any((report) => report.worldId == worldId)) {
      return ReportOutcome.alreadyReported;
    }
    sent.add((worldId: worldId, reason: reason, details: details));
    return ReportOutcome.sent;
  }
}
