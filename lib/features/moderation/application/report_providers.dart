import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/features/moderation/data/supabase_report_repository.dart';
import 'package:worlds/features/moderation/domain/report.dart';
import 'package:worlds/features/moderation/domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => SupabaseReportRepository(ref.watch(supabaseClientProvider)),
);

/// Sends one report. Its value is the outcome once the server has answered,
/// and null before that.
final reportControllerProvider =
    AsyncNotifierProvider.autoDispose<ReportController, ReportOutcome?>(
      ReportController.new,
    );

class ReportController extends AsyncNotifier<ReportOutcome?> {
  @override
  FutureOr<ReportOutcome?> build() => null;

  Future<void> send(
    String worldId, {
    required ReportReason reason,
    required String details,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final trimmed = details.trim();
    final result = await AsyncValue.guard<ReportOutcome?>(
      () => ref
          .read(reportRepositoryProvider)
          .report(
            worldId,
            reason: reason,
            details: trimmed.isEmpty ? null : trimmed,
          ),
    );
    if (ref.mounted) state = result;
  }
}
