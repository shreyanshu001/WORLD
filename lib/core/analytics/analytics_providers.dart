import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/analytics/product_analytics.dart';
import 'package:worlds/core/network/supabase_client_provider.dart';
import 'package:worlds/core/network/supabase_product_event_sink.dart';
import 'package:worlds/core/utils/uuid.dart';

/// The client is read when an event is sent, not here: reading this provider
/// must not be able to fail, because screens read it while they are built.
final productEventSinkProvider = Provider<ProductEventSink>(
  (ref) => SupabaseProductEventSink(() => ref.read(supabaseClientProvider)),
);

/// One per app launch: its id is made here and lives only in memory.
final productAnalyticsProvider = Provider<ProductAnalytics>(
  (ref) => ProductAnalytics(
    sink: ref.watch(productEventSinkProvider),
    sessionId: newUuid(),
  ),
);
