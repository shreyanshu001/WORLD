import 'package:worlds/core/analytics/product_analytics.dart';

/// One recorded event.
typedef SentEvent = ({String name, String? worldId, String? outcome});

/// A [ProductEventSink] that keeps what it was sent, or fails on demand.
class FakeProductEventSink implements ProductEventSink {
  final sent = <SentEvent>[];
  final sessionIds = <String>{};

  /// Thrown by every send while set, as a dead network would.
  Object? error;

  List<String> get names => [for (final event in sent) event.name];

  @override
  Future<void> send({
    required String sessionId,
    required String name,
    String? worldId,
    String? outcome,
  }) async {
    if (error case final error?) throw error;
    sessionIds.add(sessionId);
    sent.add((name: name, worldId: worldId, outcome: outcome));
  }
}
