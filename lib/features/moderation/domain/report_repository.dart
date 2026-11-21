import 'package:worlds/features/moderation/domain/report.dart';

/// Sends reports of Worlds. A report is visible to its reporter and to
/// moderators only, never to the creator of the World.
///
/// Throws an `AppFailure` when it fails: `rateLimited` after ten reports in
/// a day, `notFound` if the World is no longer published.
abstract interface class ReportRepository {
  Future<ReportOutcome> report(
    String worldId, {
    required ReportReason reason,
    String? details,
  });
}
