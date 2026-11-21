import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/network/backend_failure.dart';
import 'package:worlds/features/moderation/domain/report.dart';
import 'package:worlds/features/moderation/domain/report_repository.dart';

/// [ReportRepository] backed by the database function `report_world`.
class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ReportOutcome> report(
    String worldId, {
    required ReportReason reason,
    String? details,
  }) async {
    try {
      final json = await _client.rpc<Map<String, dynamic>>(
        'report_world',
        params: {
          'world_id': worldId,
          'reason': reason.wire,
          'details': details,
        },
      );
      return json['already_reported'] == true
          ? ReportOutcome.alreadyReported
          : ReportOutcome.sent;
    } on Object catch (error) {
      throw failureFromError(error);
    }
  }
}
