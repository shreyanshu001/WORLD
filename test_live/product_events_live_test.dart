// Sends product events to the development project the way the app does,
// signed out, and checks that they cannot be read back.
// Not part of `flutter test`; run it on purpose:
//
//   flutter test test_live
//
// Needs `.env` only: no account and no World. Each run leaves three events
// under a launch id of its own, which the server clears after 90 days. They
// count as one launch in the pilot funnel.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/network/supabase_product_event_sink.dart';
import 'package:worlds/core/utils/uuid.dart';

Map<String, String> _env() => {
  for (final line in File('.env').readAsLinesSync())
    if (line.contains('=') && !line.trimLeft().startsWith('#'))
      line.substring(0, line.indexOf('=')).trim(): line
          .substring(line.indexOf('=') + 1)
          .trim(),
};

void main() {
  test(
    'product events reach the real backend and cannot be read back',
    () async {
      final env = _env();
      final client = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_PUBLISHABLE_KEY']!,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final sink = SupabaseProductEventSink(() => client);
      final launch = newUuid();

      // Kept, signed out. The World here does not exist, so no World total
      // is touched.
      await sink.send(sessionId: launch, name: 'explore_opened');
      await sink.send(
        sessionId: launch,
        name: 'world_unlock_attempted',
        worldId: newUuid(),
        outcome: 'too_far',
      );
      expect(
        await client.rpc<bool>(
          'log_event',
          params: {'event_name': 'world_marker_selected', 'session_id': launch},
        ),
        isTrue,
      );

      // Refused: an unknown event, and anything but a known outcome.
      await expectLater(
        sink.send(sessionId: launch, name: 'world_shared'),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        sink.send(
          sessionId: launch,
          name: 'world_unlock_attempted',
          outcome: '37 m away',
        ),
        throwsA(isA<PostgrestException>()),
      );

      // Unreadable: the tables are not part of the API at all.
      await expectLater(
        client.from('product_events').select(),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        client.from('world_event_counts').select(),
        throwsA(isA<PostgrestException>()),
      );
      await expectLater(
        client.rpc<dynamic>('pilot_summary'),
        throwsA(isA<PostgrestException>()),
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
