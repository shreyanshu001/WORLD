import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/analytics/product_analytics.dart';

/// [ProductEventSink] backed by the database function `log_event`, the only
/// way into the private events table. It works signed out, because browsing
/// needs no account.
class SupabaseProductEventSink implements ProductEventSink {
  /// [client] is asked for only when an event is sent. A client that cannot
  /// be made then fails inside [send], where [ProductAnalytics] ignores it,
  /// and never while a screen is being built.
  SupabaseProductEventSink(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<void> send({
    required String sessionId,
    required String name,
    String? worldId,
    String? outcome,
  }) async {
    await _client().rpc<bool>(
      'log_event',
      params: {
        'event_name': name,
        'session_id': sessionId,
        'world_id': worldId,
        'outcome': outcome,
      },
    );
  }
}
