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
2. **Dry run:** execute the new migration and the relevant test files together as one SQL statement (MCP `execute_sql`). The tests end by raising an exception, so the whole statement rolls back and nothing persists.
3. **Apply:** run the file's exact contents with MCP `apply_migration`, naming it after the file.
4. **Re-run the tests** against the applied schema.
5. **Rename the file** to the version Supabase recorded (MCP `list_migrations`), so a later `supabase db push` from the CLI sees no drift.
6. Run the security and performance advisors (MCP `get_advisors`) and record the result in `docs/PROGRESS.md`.

Never fix the schema with ad-hoc SQL; write a forward migration.

### Tests

`tests/*.sql` are self-contained SQL scripts. Each always ends by raising an exception, which rolls back everything it did.

- **Pass:** the error message is exactly `WORLDS_TESTS_PASSED <file>: <n> checks`.
- **Fail:** any other message, which names the failed check.

Run them in the Supabase SQL editor or with MCP `execute_sql`, one file per run (each ends by raising, so a second file in the same statement never runs). They can move to pgTAP and `supabase test db` once the CLI and Docker are available.

- `tests/profiles_test.sql` — profiles, sign-up bootstrap, RLS.
- `tests/worlds_test.sql` — worlds RLS and `get_nearby_worlds` (filters, clamps, search, validation).

### Development seed data

`seed/dev_worlds.sql` places a few `[dev]` Worlds around a point you choose, owned by an existing account, so the Explore map has something to show before World creation exists. It is not a migration. Run it only on the development project, after editing its three marked values; it includes the one-line clean-up.

### Auth email (manual dashboard settings)

Supabase's built-in email sender only delivers to members of the project's team and is limited to 2 emails per hour. With **Confirm email** turned on (Supabase's default), sign-up fails for any other address with "Email address not authorized".

- **Development:** turn off *Authentication → Sign In / Providers → Email → Confirm email*, or sign up only with a team member's address.
- **Pilot:** configure custom SMTP before inviting testers, and keep email confirmation on.
