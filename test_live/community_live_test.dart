// Runs the app's saving, reporting and profile repositories against the
// development project, as the two test accounts: B publishes a small World,
// A saves it, reports it and looks at B's page.
// Not part of `flutter test`; run it on purpose:
//
//   flutter test test_live
//
// Needs `.env` and `tool/e2e/.accounts.json` (see the authoring live test).
// The World is deleted at the end. One report by account A stays behind for
// each run, because nothing but moderation can close a report; at most ten
// runs fit in a day.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/utils/uuid.dart';
import 'package:worlds/features/moderation/data/supabase_report_repository.dart';
import 'package:worlds/features/moderation/domain/report.dart';
import 'package:worlds/features/profile/data/supabase_profile_repository.dart';
import 'package:worlds/features/saved/data/supabase_saved_worlds_repository.dart';
import 'package:worlds/features/world_creation/data/supabase_world_authoring_repository.dart';
import 'package:worlds/features/world_creation/domain/world_draft.dart';
import 'package:worlds/features/worlds/data/supabase_world_repository.dart';
import 'package:worlds/features/worlds/domain/content_block.dart';
import 'package:worlds/shared/models/geo_point.dart';
import 'package:worlds/shared/models/world_category.dart';

Map<String, String> _env() => {
  for (final line in File('.env').readAsLinesSync())
    if (line.contains('=') && !line.trimLeft().startsWith('#'))
      line.substring(0, line.indexOf('=')).trim(): line
          .substring(line.indexOf('=') + 1)
          .trim(),
};

Future<SupabaseClient> _signIn(Map<String, dynamic> account) async {
  final env = _env();
  final client = SupabaseClient(
    env['SUPABASE_URL']!,
    env['SUPABASE_PUBLISHABLE_KEY']!,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.signInWithPassword(
    email: account['email'] as String,
    password: account['password'] as String,
  );
  return client;
}

void main() {
  final accountsFile = File('tool/e2e/.accounts.json');

  test(
    'saving, reporting and profile pages work against the real backend',
    () async {
      final accounts =
          jsonDecode(accountsFile.readAsStringSync()) as Map<String, dynamic>;
      final a = await _signIn(accounts['a'] as Map<String, dynamic>);
      final b = await _signIn(accounts['b'] as Map<String, dynamic>);
      addTearDown(() async {
        await a.dispose();
        await b.dispose();
      });

      // B creates here, so the daily limit on new Worlds of account A is
      // left to the other live tests.
      final authoringB = SupabaseWorldAuthoringRepository(b);
      final worldsA = SupabaseWorldRepository(a);
      final savedA = SupabaseSavedWorldsRepository(a);
      final savedB = SupabaseSavedWorldsRepository(b);
      final reportsA = SupabaseReportRepository(a);
      final reportsB = SupabaseReportRepository(b);
      final profilesA = SupabaseProfileRepository(a);
      final profilesB = SupabaseProfileRepository(b);

      const place = GeoPoint(latitude: -41.06, longitude: -121.0);
      const nearby = GeoPoint(latitude: -41.061, longitude: -121.0);
      final worldId = newUuid();
      await authoringB.save(
        WorldDraft(
          id: worldId,
          category: WorldCategory.story,
          title: '[e2e] Community check',
          description: 'Automated check of saving and reporting, out at sea.',
          location: place,
          blocks: [ContentBlock.text(id: newUuid(), body: 'Nothing here.')],
        ),
      );
      expect((await authoringB.publish(worldId)).published, isTrue);

      // Saving: private, repeatable, visible in details and in the list.
      final before = await worldsA.details(worldId);
      expect(before.isSaved, isFalse);
      final creator = before.creatorUsername;

      await savedA.setSaved(worldId, saved: true);
      await savedA.setSaved(worldId, saved: true);
      expect((await worldsA.details(worldId)).isSaved, isTrue);

      final listed = await savedA.list(from: nearby);
      final mine = listed.items.where((w) => w.id == worldId).single;
      expect(mine.title, '[e2e] Community check');
      expect(mine.creatorUsername, creator);
      expect(mine.distanceMeters, closeTo(111, 15));

      // The creator sees neither the save nor who saved.
      expect(
        (await savedB.list()).items.where((w) => w.id == worldId),
        isEmpty,
      );
      expect(await b.from('saved_worlds').select('world_id'), isEmpty);

      await savedA.setSaved(worldId, saved: false);
      expect(
        (await savedA.list()).items.where((w) => w.id == worldId),
        isEmpty,
      );
      expect((await worldsA.details(worldId)).isSaved, isFalse);

      // Reporting: once per World while pending; never visible to the
      // creator; the outcome of moderation is not readable at all.
      expect(
        await reportsA.report(
          worldId,
          reason: ReportReason.spamOrMisleading,
          details: '  Automated check; please ignore.  ',
        ),
        ReportOutcome.sent,
      );
      expect(
        await reportsA.report(worldId, reason: ReportReason.other),
        ReportOutcome.alreadyReported,
      );
      await expectLater(
        reportsB.report(worldId, reason: ReportReason.other),
        throwsA(const AppFailure.invalidContent()),
      );

      final ownReports = await a
          .from('world_reports')
          .select('id, reason, description')
          .eq('world_id', worldId);
      expect(ownReports, hasLength(1));
      expect(
        ownReports.single['description'],
        'Automated check; please ignore.',
      );
      expect(
        await b.from('world_reports').select('id').eq('world_id', worldId),
        isEmpty,
      );
      await expectLater(
        a.from('world_reports').select('status'),
        throwsA(isA<PostgrestException>()),
      );

      // Profile pages: public fields and published Worlds for everyone,
      // private counts for the owner only.
      final seenByA = await profilesA.page(creator);
      expect(seenByA.isOwn, isFalse);
      expect(seenByA.publishedCount, greaterThanOrEqualTo(1));
      expect(seenByA.worlds.map((w) => w.id), contains(worldId));
      expect(seenByA.draftCount, isNull);
      expect(seenByA.discoveredCount, isNull);
      expect(seenByA.completedCount, isNull);

      final seenByB = await profilesB.page(creator);
      expect(seenByB.isOwn, isTrue);
      expect(seenByB.draftCount, isNotNull);
      expect(seenByB.discoveredCount, isNotNull);
      await expectLater(
        profilesA.page('nobody_by_this_name'),
        throwsA(const AppFailure.notFound()),
      );

      // Unpublished: it can no longer be saved or reported.
      await authoringB.unpublish(worldId);
      await expectLater(
        savedA.setSaved(worldId, saved: true),
        throwsA(const AppFailure.notFound()),
      );
      await authoringB.delete(worldId);
    },
    skip: accountsFile.existsSync()
        ? false
        : 'No tool/e2e/.accounts.json; see the authoring live test.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
