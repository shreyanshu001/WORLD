# Supabase setup

1. Create a Supabase project controlled by the product owner.
2. Enable PostGIS.
3. Link local project with Supabase CLI.
4. Commit every schema change as a migration.
5. Configure Auth email settings.
6. Create Storage buckets and policies through migrations or documented scripts.
7. Configure Flutter with project URL and public anon/publishable key only.
8. Keep service-role credentials in trusted server environments only.
9. Run RLS tests before exposing public clients.

Never commit .env files, service-role keys, database passwords or access tokens. See docs/DATABASE.md and docs/SECURITY_AND_PRIVACY.md.

## Current workflow (no Supabase CLI or Docker yet)

The development project is reached through the Supabase MCP server in `.mcp.json`. Steps 1, 2 and 4 are done; step 3 (CLI link) is not, because the CLI and Docker are not installed on the development machine.

### Changing the schema

1. Write the change as a new file in `migrations/`. Never change a migration that has already been applied; write a new one.
2. **Build the statements:** `node tool/sql/build_editor_sql.js <migration file> [out dir] [tests]` writes three files (to the gitignored `.sql-to-run/` by default): a dry run, the apply, and the tests alone. Each is one statement, a `do` block that carries the migration and tests as text, compares their md5 with the committed files and only then runs them. A copy altered on the way runs nothing (`WORLDS_TEXT_MISMATCH`).
3. **Dry run:** execute `1-dry-run.sql` (MCP `execute_sql`, or the SQL editor). It always ends by raising an error, so nothing persists. Pass: the message starts with `WORLDS_ALL_TESTS_PASSED` and lists each test file's checks.
4. **Apply:** run the file's exact contents with MCP `apply_migration`, naming it after the file. Then check that the stored statement is the committed file: `select md5(statements[1]) from supabase_migrations.schema_migrations` must equal the md5 the build script printed.
5. **Rename the file** to the version Supabase recorded (MCP `list_migrations`), so a later `supabase db push` from the CLI sees no drift.
6. **Re-run the tests** against the applied schema (`3-tests-after-apply.sql`).
7. Run the security and performance advisors (MCP `get_advisors`) and record the result in `docs/PROGRESS.md`.

**If the connection will not run it:** in Checkpoint 4 the Supabase MCP server's confirmation prompt was declined by the editor without being shown, so the owner ran the three files in the Supabase SQL editor instead (`2-apply-migration.sql` applies the migration and writes its history row with the file's own version). In Checkpoint 5 the connection accepted single statements again, and steps 3 to 7 ran through it. Statements that could leave something behind if only part of them ran (several statements in one request) are still refused, which is why every file is one statement.

Never fix the schema with ad-hoc SQL; write a forward migration.

### Tests

`tests/*.sql` are self-contained SQL scripts. Each always ends by raising an exception, which rolls back everything it did.

- **Pass:** the error message is exactly `WORLDS_TESTS_PASSED <file>: <n> checks`.
- **Fail:** any other message, which names the failed check.

Run them in the Supabase SQL editor or with MCP `execute_sql`, one file per run (each ends by raising, so a second file in the same statement never runs). They can move to pgTAP and `supabase test db` once the CLI and Docker are available.

- `tests/profiles_test.sql` — profiles, sign-up bootstrap, RLS.
- `tests/worlds_test.sql` — worlds RLS and `get_nearby_worlds` (filters, clamps, search, validation).
- `tests/world_authoring_test.sql` — Checkpoint 4: saving, publishing, answer secrecy, assets, storage policies and World details.
- `tests/world_play_test.sql` — Checkpoint 5: unlocking, playing, branching, answers and their limit, progress privacy, players' image access, unpublished and hidden Worlds.
- `tests/community_test.sql` — Checkpoint 6: saving, reporting and their limits, privacy of saves and reports, every moderation action and its log, what a hide closes off, profile pages.
- `tests/product_events_test.sql` — Checkpoint 7: what an event may hold, who may send and who may read, the two limits, the 90-day clearing, the per-World totals, the pilot functions.

To run every file against the applied schema, build one statement per file (`node tool/sql/build_editor_sql.js <latest migration> <out dir> <test name>`) and run each `3-tests-after-apply.sql`. Do this after every migration, not only for the new file: a new migration can break an older promise.

Write tests so they need no clean-up: no `delete` statements. Count only your own fixtures, or the difference from a count taken first: the database holds real rows (live checks, and soon testers), and a test that counts a whole table passes only on an empty one. The Supabase connection asks for confirmation before SQL it considers destructive, the editor declines that prompt without showing it, and a test file that contained two clean-up deletes was refused whole (2026-11-21), although it could not have changed anything. Give fixtures their own rows instead, so nothing has to be removed before the next check.

### Moderation runbook

Moderation is done here, in the SQL editor of the Supabase dashboard, by the project owner (docs/DECISIONS.md, D-036). There is no moderator screen in the app. Every action needs your name and a reason; both are kept in `private.moderation_actions`.

```sql
-- 1. What is waiting, oldest first.
select * from private.moderation_queue();

-- 2. One of these, with the World's id from the queue.
select private.hide_world('<world id>', '<your name>', '<why>');       -- out of sight; its creator cannot undo it
select private.dismiss_reports('<world id>', '<your name>', '<why>');  -- nothing wrong; reports closed
select private.remove_world('<world id>', '<your name>', '<why>');     -- deleted for good

-- 3. Undo a hide.
select private.restore_world('<world id>', '<your name>', '<why>');

-- The record of what was done.
select * from private.moderation_actions order by acted_at desc;
```

- Hiding closes a World to everyone but its creator at once: map, details, play, saved lists and their profile page. The creator sees "Hidden by moderation" and cannot edit, publish or delete it.
- Restoring publishes it again only if it was published when hidden and is still complete; otherwise it becomes a draft the creator can publish.
- The reporter is never shown to the creator. The queue shows it to you.
- The live tests leave one pending report per run for a deleted `[e2e]` World, made by the test account. Close them with `dismiss_reports`.

### Reading the pilot

What the pilot measures and what it deliberately does not is in docs/DECISIONS.md, D-039. In the SQL editor:

```sql
-- Day by day (UTC), the last 30 days: launches reaching each step, and what was started, finished, published, saved and reported.
select * from private.pilot_funnel();
select * from private.pilot_funnel('2026-12-01');   -- from a given day

-- The pilot so far in one row: creators, repeat creators, explorers, second discoveries, completions.
select * from private.pilot_summary();

-- Per World: details opened and unlock attempts.
select * from private.pilot_worlds();
```

- A launch is one start of the app, not one person. No account is stored with it, but a launch that unlocked a World can be matched to one by comparing times with `world_progress` (D-039).
- The steps the app reports (Explore, selecting, details, unlock attempts) can be sent by anyone who has the app's public key, and stop being recorded after 20,000 events in 24 hours. A day whose numbers look wrong may have been flooded. The steps counted from other tables (started, completed, published, saved, reported) cannot be forged this way.
- Runs of `test_live/product_events_live_test.dart` each add one launch with three events.

### Operations before the pilot (checked 2026-11-21)

Facts from the providers' own pages on that date. They change; read them again before inviting testers.

- **Supabase Free plan** ([pricing](https://supabase.com/pricing), [billing](https://supabase.com/docs/guides/platform/billing-on-supabase), [database size](https://supabase.com/docs/guides/platform/database-size), [pausing](https://supabase.com/kb/faqs/platform/free-project-pausing), [production checklist](https://supabase.com/docs/guides/deployment/going-into-prod)):
  - A project is paused after about a week with too little activity. A paused project keeps its data but the app cannot reach it until someone restores it in the dashboard. A quiet week during the pilot would do this.
  - 500 MB of database per project, on a 2 GB disk that does not grow; at 95% of the disk the database becomes read-only. Storage and egress have their own allowances on the pricing page; World images count against them.
  - **No automatic backups and no downloadable backups.** Today a mistake in the SQL editor, or a lost project, cannot be undone. The Pro plan (from $25 a month on that date) adds daily backups kept 7 days and no pausing.
  - **Decided 2026-11-21 (D-042):** the owner chose to stay on the Free plan for now, accepting no backups and the pausing.
  - Nobody is named yet as the person who watches the project, restores it if it pauses and runs moderation. That is an owner decision.
- **OpenFreeMap map tiles** ([terms](https://openfreemap.org/tos/), [site](https://openfreemap.org), [source](https://github.com/hyperknot/openfreemap)): free, no key, no stated limit on views or requests, provided as it is with no warranty and no promise of uptime; the terms can change at any time. The attribution the app always shows, "OpenFreeMap © OpenMapTiles Data from OpenStreetMap", is the text the project asks for. There is no fallback provider configured: if the service is down the map is blank, and `MAP_STYLE_URL` and `MAP_ATTRIBUTION` are the switch to another one. The project publishes its tiles for self-hosting.
- **Logs:** the app writes two lines to the phone's own log, each with only the kind of error (startup failed; the map could not be drawn). Nothing is sent anywhere: there is no crash or error reporting service. A crash on a tester's phone is known only if the tester says so.

### Development seed data

`seed/dev_worlds.sql` places a few `[dev]` Worlds around a point you choose, owned by an existing account, so the Explore map has something to show before World creation exists. It is not a migration. Run it only on the development project, after editing its three marked values; it includes the one-line clean-up.

### Auth email (manual dashboard settings)

Supabase's built-in email sender only delivers to members of the project's team and is limited to 2 emails per hour. With **Confirm email** turned on (Supabase's default), sign-up fails for any other address with "Email address not authorized".

- **Development:** turn off *Authentication → Sign In / Providers → Email → Confirm email*, or sign up only with a team member's address.
- **Pilot:** configure custom SMTP before inviting testers, and keep email confirmation on.

**Current state (development project):** *Confirm email* was turned **off** on 2026-11-20. The public auth settings (`GET /auth/v1/settings` with the publishable key) report `mailer_autoconfirm: true`. Turn it back on together with custom SMTP before the pilot.
