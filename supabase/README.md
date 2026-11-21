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

### Development seed data

`seed/dev_worlds.sql` places a few `[dev]` Worlds around a point you choose, owned by an existing account, so the Explore map has something to show before World creation exists. It is not a migration. Run it only on the development project, after editing its three marked values; it includes the one-line clean-up.

### Auth email (manual dashboard settings)

Supabase's built-in email sender only delivers to members of the project's team and is limited to 2 emails per hour. With **Confirm email** turned on (Supabase's default), sign-up fails for any other address with "Email address not authorized".

- **Development:** turn off *Authentication → Sign In / Providers → Email → Confirm email*, or sign up only with a team member's address.
- **Pilot:** configure custom SMTP before inviting testers, and keep email confirmation on.

**Current state (development project):** *Confirm email* was turned **off** on 2026-11-20. The public auth settings (`GET /auth/v1/settings` with the publishable key) report `mailer_autoconfirm: true`. Turn it back on together with custom SMTP before the pilot.
