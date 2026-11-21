# WORLDS — Implementation progress

**Phase:** MVP implementation  
**Current checkpoint:** 7 (Beta and pilot): the code and records a pilot needs are on its branch; the pilot itself has not been run. Checkpoint 6 was merged into `main` by the owner with no recorded answer to its moderation and privacy review, and Checkpoints 4 and 5 are still awaiting their device checks  
**Product direction:** Approved  
**Documentation handoff:** Core product, journey, UX and acceptance specifications published to GitHub  
**App implementation:** Foundation, accounts and profiles, the Explore map, World details, the World creator, on-site unlocking, the World player, saved Worlds, reporting, creator pages and profile counts. Moderation is done in the Supabase dashboard, not in the app. Share links are not built. The Checkpoint 4, 5, 6 and 7 database migrations are applied to the development project and verified. The owner merged Checkpoints 4, 5 and 6 into `main` on GitHub on 2026-11-21 (pull requests #6, #7 and #8), so `main` holds Checkpoints 0–6; Checkpoint 7 is on its branch.

| Checkpoint | Status | Evidence |
|---|---|---|
| Documentation handoff | Complete | Product/technical docs plus `UI_UX_SPECIFICATION.md`, `USER_JOURNEYS.md`, `FEATURE_ACCEPTANCE_CRITERIA.md` |
| 0. Repository audit | Audit delivered. Owner answered D1 and D3 and asked for the scaffold; ten decisions remain open | `docs/REPOSITORY_AUDIT.md`, commit `f1b92f1`, 2026-11-19 |
| 1. Project foundation | Implemented; device test deferred by owner; continued to Checkpoint 2 at owner's request | See "Checkpoint 1 record" below |
| 2. Backend and identity | Implemented; device test and security review pending | See "Checkpoint 2 record" below |
| 3. Explore map | Implemented; real-device map check pending | See "Checkpoint 3 record" below |
| 4. World details and creator | Implemented (4A–4G); migration applied and tested; two-account API check passed; owner device check pending | See "Checkpoint 4 record" below |
| 5. Experience player | Implemented; migration applied and tested; account A to account B check passed through the app's own data layer; no device verification | See "Checkpoint 5 record" below |
| 6. Saved/profile/moderation | Implemented; migration applied; saving, reporting and profile pages checked against the real backend; merged into `main` by the owner (pull request #8); no answer on record to the moderation and privacy review; no device verification | See "Checkpoint 6 record" below |
| 7. Beta and pilot | Pilot tooling implemented on its branch (product events, large text, contrast, motion, operations notes); events migration applied and tested. The pilot itself has not been run; no device verification | See "Checkpoint 7 record" below |

## Current blockers

- On-device: the app has been installed and launched on the owner's phone and runs without crashing, but its screen has not been seen. Sign-up through real Supabase Auth, sign-in, sign-out, session restore and the map are untested on a device.
- Email confirmation was turned off in the dashboard by the owner on 2026-11-20 for development, so new accounts are signed in at once and any address can register, including ones the user does not own. Before the pilot: set up custom SMTP and turn confirmation back on (see `supabase/README.md`).
- The Checkpoint 2 gate is a security review by the owner.
- The Checkpoint 2 security review has not been explicitly given.
- Checkpoint 3's map package and tile provider were adopted on recommendation when the owner said "continue" (D-016, D-017); the owner has not chosen them explicitly.
- The pilot area, and so the Explore default centre, is undecided (D-021).
- Schema changes through the Supabase connection: in Checkpoint 4 its approval prompt was declined by the editor, so the owner ran prepared files in the Supabase SQL editor. In Checkpoint 5 the connection ran single statements again (dry run, apply and tests all went through it); requests made of several statements were still refused. The prepared files are now one statement each (see `supabase/README.md`).
- Checkpoint 4 has not been checked on a phone by the owner: the creator, place picker, photo picker and details screen are unseen on a real screen.
- Checkpoint 5 has not run on a phone at all: unlocking with a real GPS reading, the permission prompt from the details screen and the player are untested on a device. No phone was attached on 2026-11-21.
- Checkpoint 6 has not run on a phone, and no moderation action has been run for real: the moderation functions have only run inside rolled-back tests, and the runbook in `supabase/README.md` has not been followed by a person.
- The Checkpoint 6 gate is the owner's moderation and privacy review. Five decisions taken for it are proposals (D-034 to D-038).
- Checkpoint 6 was merged into `main` by the owner on 2026-11-21 (pull request #8, 14:01 IST) while Checkpoint 7 was in progress. No answer to its moderation and privacy review, or to D-034 to D-038, is on record.
- Before a pilot (Checkpoint 7): the owner chose to stay on the Free plan for now (D-042), so there are no backups and a quiet project pauses; no one is named to operate the project and moderate; testers have not been told what is measured; there is no fallback map and no crash reporting (see `supabase/README.md` and D-039). The pilot area is still undecided (asked on 2026-11-21).
- Checkpoints 4 and 5 were merged into `main` by the owner on 2026-11-21 (pull requests #6 and #7) with their device checks still open. `AGENTS.md` still describes the state before Checkpoint 4 under "Before coding" and "Current task"; a correction is proposed in the Checkpoint 5 report and left to the owner.
- Gap G1 (unlisted Worlds by direct link) is still open; the creator does not offer "unlisted" (D-029).
- The application ID is the placeholder `com.example.worlds`. It must be replaced before any release build.
- Supabase region and plan are unverified. Verified: Postgres 17.12; sign-up enabled; email confirmation **off** since 2026-11-20 (`mailer_autoconfirm: true` from the public auth settings; it was `false` before).

## Checkpoint 0 record

- **Date:** 2026-11-19
- **Commit audited:** `d31f872` on `main`. The audit is committed as `f1b92f1` on branch `checkpoint-0-audit-and-scaffold`.
- **Summary:** The project is greenfield: the repository holds documentation only, and the product owner confirmed that no Flutter source exists elsewhere. The audit covers the installed toolchain, a dependency compatibility spike run outside the repository, map package and tile-provider review, Supabase platform facts, and a consistency pass over the documents.
- **Files changed:** `docs/REPOSITORY_AUDIT.md` (new), `docs/PROGRESS.md`, `docs/DEPENDENCY_DECISIONS.md`, `.mcp.json` (new, Supabase MCP server config added at the owner's request). No application source and no migrations.
- **Tests and results:** The repository has no Dart code, so there was nothing to format, analyze or test in it (`dart format` reported "Formatted no files"). In the throwaway spike on Flutter 3.38.3: dependency resolution passed, `build_runner` passed, `flutter analyze` reported no issues, `flutter test` passed 2 of 2, and `flutter build apk --debug` failed on the machine's default JDK 20 and passed on JDK 21.
- **Manual device verification:** None. A physical Android 16 device was detected but nothing was installed on it; real-device map verification is the Checkpoint 3 gate.
- **Known issues:**
  - Installed Flutter 3.38.3 is one year behind current stable 3.50.0; 11 of 17 recommended packages resolve below their latest release.
  - A user-level Gradle setting forces JDK 20, which breaks the MapLibre plugin build. A project-level fix is verified and planned for Checkpoint 1.
  - The Supabase project's region, plan, Postgres version and auth settings are not verified. Its schema and extensions were inspected after delivery; see "Project inspection after delivery" in the audit.
  - No Supabase CLI, Docker or `psql` is installed. Whether the Supabase CLI runs through `npx` on this machine is not verified.
  - Android SDK licenses are not all accepted.
  - Four gaps between the specification documents (G1–G4 in the audit) need product decisions.
  - `.mcp.json` enables write-capable Supabase MCP tools; the audit recommends `read_only=true` until Checkpoint 2.
- **Approval status:** Pending.

## Checkpoint 1 scaffold record

Only the scaffold part of Checkpoint 1 is done. It was created at the product owner's request on 2026-11-19.

- **Date:** 2026-11-19
- **Commit:** `319a8d3` on branch `checkpoint-0-audit-and-scaffold` (local only, not pushed).
- **Summary:** Empty Flutter app created at the repository root with Flutter 3.38.3, Android only, plus the folder structure from `docs/TECHNICAL_ARCHITECTURE.md`. Empty folders hold a `.gitkeep` file so git tracks them.
- **Created:**
  - `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `android/` — from `flutter create --org com.example --project-name worlds --platforms android --empty .`
  - `lib/main.dart` and `lib/app/app.dart` — a root `WorldsApp` widget that shows a placeholder title.
  - `lib/app/{router,theme,config}/`, `lib/core/{errors,location,maps,network,widgets,utils}/`, `lib/shared/{models,components}/`.
  - `lib/features/{auth,explore,worlds,world_player,world_creation,saved,profile,moderation}/`, each with `data`, `domain`, `application` and `presentation`.
  - `supabase/migrations/` and `supabase/functions/`.
  - `test/app/app_test.dart` — one smoke test.
- **Changed:** `.gitignore` (Flutter template entries added), `README.md` (Development section), Android app label set to `WORLDS`.
- **Not done:** no dependencies beyond Flutter's defaults, no theme, router, app shell, Supabase initialisation or environment configuration. No migrations.
- **Tests and results:**
  - `dart format --output=none --set-exit-if-changed .` — 3 files, 0 changed.
  - `flutter analyze` — no issues.
  - `flutter test` — 1 of 1 passed.
  - `flutter build apk --debug` — passed. The APK reports package `com.example.worlds`, label `WORLDS`, minSdk 24, targetSdk 36, and `INTERNET` as its only Android permission (from Flutter's debug manifest).
- **Manual device verification:** Not done. The owner approved installing on the connected phone, but the phone was no longer attached over USB when the build finished, so the app has not been launched on a device.
- **Known issues:**
  - Launch on a real device is unverified.
  - The application ID is a placeholder.
  - `INTERNET` is declared only for debug and profile builds; the main manifest needs it once networking is added.
  - The Gradle JDK pin (decision D2) is not yet added; the scaffold builds without it, but the map plugin will not.
- **Approval status:** Pending.

## Checkpoint 1 record

- **Date:** 2026-11-20
- **Branch:** `checkpoint-1-app-foundation` (local only, not pushed). Commit: `d598dbc`.
- **Summary:** App foundation on top of the scaffold. Startup validates build-time configuration and initialises Supabase with the publishable key, showing a loading screen and then either the app or an error screen (with retry when retrying can help). Material 3 light and dark themes, a `go_router` shell with four tabs that each keep their own stack, placeholder screens that say plainly they are not built yet, shared loading/empty/error views, and the typed `AppFailure` model from the architecture document.
- **Files:**
  - `lib/main.dart`, `lib/app/app.dart`, `lib/app/startup_gate.dart`, `lib/app/bootstrap.dart`, `lib/app/app_shell.dart`.
  - `lib/app/config/env.dart` — reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`; rejects missing values, non-HTTPS URLs and secret or service-role keys; never shows a key value.
  - `lib/app/router/app_router.dart`, `lib/app/router/app_routes.dart`, `lib/app/theme/app_theme.dart`.
  - `lib/core/errors/app_failure.dart` and its generated `app_failure.freezed.dart`.
  - `lib/core/network/supabase_client_provider.dart`.
  - `lib/core/widgets/{loading_view,empty_view,error_view}.dart`.
  - `lib/features/{explore,saved,world_creation,profile}/presentation/*_screen.dart`.
  - `test/app/{bootstrap,startup_gate,app_shell}_test.dart`, `test/app/config/env_test.dart`, `test/core/errors/app_failure_test.dart`, `test/core/widgets/state_views_test.dart`. The scaffold's single smoke test was replaced by these.
  - `android/gradle/gradle-daemon-jvm.properties` (Java 21), `INTERNET` in the main Android manifest.
  - `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml` (strict analyzer modes, generated files excluded), `.env.example` (publishable-key name), `README.md`.
  - Local only, gitignored: `.env` with the project URL and publishable key, read through the read-only Supabase tool.
- **Database/API changes:** none.
- **Tests and results:**
  - `dart format --output=none --set-exit-if-changed .` — 25 files, 0 changed (generated files included).
  - `flutter analyze` — no issues.
  - `flutter test` — 27 of 27 passed. One test caught a real bug: the retry handler passed `setState` a callback that returned a Future, which Flutter rejects. Fixed.
  - `dart run build_runner build --delete-conflicting-outputs` — succeeded (about 75 s).
  - `flutter build apk --debug --dart-define-from-file=.env` — passed in about 3 minutes. The APK reports package `com.example.worlds`, label `WORLDS`, minSdk 24, targetSdk 36, and `INTERNET` as its only Android permission.
- **Manual device verification:** Deferred by the product owner on 2026-11-20 ("I will test it later"). Real Supabase initialisation and on-device navigation are therefore unverified.
- **Known issues:**
  - Launch on a device is unverified, so the Checkpoint 1 acceptance criterion "app launches on Android" is not yet met.
  - `json_serializable`, `json_annotation` and `mocktail` are added but unused until Checkpoint 2.
  - The application ID is still the placeholder `com.example.worlds`.
  - The theme's seed colour is a placeholder; there is no design system.
  - Android SDK licenses are still not all accepted.
- **Approval status:** Pending.

## Checkpoint 2 record

- **Date:** 2026-11-20
- **Branch:** `checkpoint-2-backend-identity` (local only, not pushed). Commits: `19e6874` and the follow-up fix `3438787`.
- **Started:** at the owner's instruction to continue implementation, with Checkpoint 1's device test deferred. Owner decisions: apply migrations to the remote project through the MCP connection (D-015) and choose usernames at sign-up (D-014).
- **Database changes, applied to the development project:**
  - `supabase/migrations/20261119190312_enable_postgis.sql` — PostGIS in the `extensions` schema.
  - `supabase/migrations/20261119190424_create_profiles.sql` — `public.profiles` with RLS, explicit grants (public read; owners update `username`, `display_name`, `bio` only; no client insert or delete), an `updated_at` trigger, and the sign-up trigger that creates the profile. Helpers live in a `private` schema the API does not expose.
  - Each file was applied from its exact bytes (the tool input was compared character for character), then renamed to the version Supabase recorded.
- **Database tests:** `supabase/tests/profiles_test.sql`, 32 checks covering bootstrap (requested, lower-cased, taken, invalid, missing and colliding generated names), RLS on, private schema unreachable, anon read-only, owner can update own permitted columns, user A cannot change user B, denied columns and insert/delete with their specific error codes, value limits, and `updated_at`.
  - Dry run (migrations plus tests in one rolled-back statement): passed, 32 checks; database still empty afterwards.
  - Mutation check: with the update policy weakened to `using (true)`, the tests failed with `FAIL user A: updated user B's profile`.
  - Against the applied schema: passed, 32 checks.
  - Supabase security advisor: no findings. Performance advisor: no findings.
- **App:**
  - Auth: `lib/features/auth/` — domain (`AuthUser`, `AuthRepository`, `CredentialRules`), Supabase data source, Riverpod controllers, sign-in, sign-up and a reusable sign-in prompt.
  - Profile: `lib/features/profile/` — `Profile` model, repository, rules mirroring the database, profile view with sign-out, profile editing, and a one-time notice when the server assigns a different username.
  - Saved and Create tabs show a sign-in prompt when signed out; Explore stays open to everyone.
  - Router: `/sign-in`, `/register`, `/profile/edit`; signed-out users are sent from `/profile/edit` to sign-in.
  - Errors: auth errors are mapped by Supabase error code (verified against Supabase's error-code reference), database errors by SQLSTATE; network errors map to "offline".
  - Riverpod automatic retry is turned off so failures reach the screen and the user chooses when to retry.
  - `http` added as a direct dependency (already present transitively) to recognise network errors. `build.yaml` makes JSON keys snake_case.
- **Tests and results:**
  - `dart format --output=none --set-exit-if-changed .` — 53 files, 0 changed.
  - `flutter analyze` — no issues.
  - `flutter test --timeout 60s` — 101 of 101 passed. These caught two bugs, both fixed: pages opened with `push` were not left after sign-in, because go_router's redirect only sees the page underneath; and a test awaited a fake timer outside the test clock.
  - Follow-up fix found in review: after a failed or unconfirmed sign-up, signing in to another account could show "X was taken" for that account. The requested username is now kept only when sign-up ends signed in, and cleared on sign-in and sign-out; two regression tests added. The profile save now stays alive until it finishes, so the profile always refreshes.
  - Real Data API, anonymous requests with the publishable key: listing profiles returned HTTP 200 with an empty list; a missing single row returned HTTP 406 `PGRST116`; an edit returned HTTP 401 `42501`. All three match the app's error mapping. The public auth settings show sign-up enabled and email confirmation on.
  - `flutter build apk --debug --dart-define-from-file=.env` — passed; `INTERNET` is still the only permission.
- **Manual device verification:** Deferred by the owner.
- **Not verified:**
  - Real sign-up through Supabase Auth. The database tests insert users as `postgres`, because `supabase_auth_admin` cannot be assumed; the sign-up function is `security definer`, so it runs with the same rights either way.
  - "Fresh database builds from migrations" beyond this first run: the project was empty and the two files were applied in order, but no separate clean database was rebuilt (that would need a paid branch, or the CLI and Docker).
- **Known issues:**
  - Email confirmation and Supabase's default SMTP restrict sign-up as described under Current blockers.
  - Supabase's own minimum password length is 6; the app asks for 8. The project's server setting is unverified.
  - No password reset or email-change flow yet; out of this checkpoint's scope.
- **Approval status:** Pending security review.

## Checkpoint 3 record

- **Date:** 2026-11-20
- **Branch:** `checkpoint-3-explore-map` (local only, not pushed). Commits: `26df7e3`, plus a follow-up adding the location explanation and these notes.
- **Started:** at the owner's "continue". Map package and tile provider adopted on recommendation (D-016, D-017); title search added to the nearby query (D-018); browsing without an account (D-019).
- **Database changes, applied to the development project:**
  - `supabase/migrations/20261120050626_create_worlds.sql` — `public.worlds` (GIST index on location, discovery and creator indexes, `updated_at` trigger), one read policy (published public Worlds, plus creators' own non-deleted Worlds), read-only grants, and `get_nearby_worlds` (validation, clamps, title search with literal `%` and `_`, explicit published/public filter, preview fields only, callable signed out).
  - Applied from the file's exact bytes, renamed to the recorded version.
- **Database tests:** `supabase/tests/worlds_test.sql`, 36 checks: every status and visibility, distance order and values, coordinates, creator name, radius clamps (up to 25 km, down to 100 m), category filter, case-insensitive and literal-character search, paging clamps, coordinate and category validation, what signed-out users and creators can read, no client writes, and table constraints.
  - Dry run with the migration: passed, 36 checks; `profiles_test.sql`: 32 checks, so nothing regressed.
  - Mutation check: without the query's own published/public filter, the tests failed (a creator got their own draft back), even though signed-out results were unaffected.
  - Against the applied schema: 36 and 32 checks passed.
  - Security advisor: no findings. Performance advisor: one informational note that the location index is unused, expected while the table is empty.
  - Real Data API, anonymous: valid nearby call HTTP 200; latitude 91 and an unknown category HTTP 400 `22023`; table read HTTP 200 with no rows.
- **App:**
  - `lib/core/maps/` — `MapAdapter` (declarative: markers, selection, one-shot camera requests, user-camera-idle events) and its MapLibre implementation. MapLibre's own location layer stays off.
  - `lib/core/location/` — `LocationService` and its geolocator implementation: one reading with a 15-second limit, no streams.
  - `lib/features/worlds/` — `WorldPreview`, `WorldRepository`, Supabase implementation (POST, so coordinates are not in URLs).
  - `lib/features/explore/` — controller and screen: search with pause, category chips, markers and preview card, list view, locate button, and messages for no area yet, no results, search failure with retry, location refused, blocked (opens Settings, retries on return), services off, and no fix. Map attribution is always visible.
  - Optional settings `MAP_STYLE_URL`, `MAP_ATTRIBUTION`, `EXPLORE_DEFAULT_CENTER`.
  - Android: fine and coarse location declared; geolocator's location foreground service removed.
  - `supabase/seed/dev_worlds.sql` — development seed script; not run.
- **Tests and results:**
  - `dart format --output=none --set-exit-if-changed .` — 82 files, 0 changed.
  - `flutter analyze` — no issues.
  - `flutter test --timeout 60s` — 137 of 137 passed. New: 19 Explore screen tests (including a slow older search arriving after a newer one), architecture tests (map and location SDKs and Supabase confined to their layers, domain free of Flutter and SDKs, manifest without background location, Gradle wrapper version), and unit tests.
  - `flutter build apk --debug --dart-define-from-file=.env` — passed. The built APK requests only INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_NETWORK_STATE and ACCESS_WIFI_STATE (the last two from MapLibre). No background location, no foreground-service permission, and geolocator's service is absent from the merged manifest.
- **Incident:** the Gradle wrapper was changed to 9.7.1 outside this work, most likely by the editor's Gradle tooling, which broke the build (Android Gradle Plugin 8.11.1 cannot run on Gradle 9.6+). Restored to 8.14 with the owner's approval; a test now fails if it changes again.
- **Manual device verification:** Partial, with the owner's approval. What was done on the phone over USB:
  - Installed the debug APK (still installed) and launched it twice.
  - Took one screenshot. It was opened once, showed the system notification shade rather than the app, and was deleted.
  - Collapsed the notification shade with `cmd statusbar collapse`.
  - Wrote a temporary UI dump file to the phone, which came back empty, and deleted it.

  Observed: the app stayed running for several minutes with no crash or "not responding" record. That the map's native view was created is **inferred** from a display surface the app created at the map's size; the screen itself was never seen. Map rendering, tiles, attribution placement, markers and the location flow on a real device are **not verified**.
- **Known issues:**
  - The Checkpoint 3 gate (real-device map and tile check) is open. Recommended before Checkpoint 4, whose location picker reuses the map.
  - No Worlds exist yet, so a device shows the empty state unless the seed script is run.
  - Map tiles come from OpenFreeMap, a third party that sees the device's IP address and the areas viewed; no SLA. Every style, tile, font and sprite request goes to the single host `tiles.openfreemap.org` (checked from the style and tile index).
  - Pilot area and default centre undecided.
  - The app asks for one page of up to 50 results. In an area with more than 50 Worlds within 5 km, the furthest ones are silently left out; paging is not implemented.
- **Follow-up after review:**
  - Added the location explanation required by `docs/SECURITY_AND_PRIVACY.md` ("Explain why location is requested"): before Android's prompt, a short dialog says location is used only on tap, never tracked in the background, never shown to others. "Not now" touches nothing. It is skipped when permission is already granted or blocked. 138 of 138 tests pass.
  - Seed script rehearsed in a rolled-back run with a test account: it inserted 8 Worlds (7 published, 1 draft); a signed-out nearby search returned 6, without the draft or the World 6 km away.
  - The nearby call with exactly the app's payload (five keys, two of them null) returned HTTP 200.
- **Approval status:** Pending.

## Checkpoint 4 record

- **Date:** 2026-11-20
- **Branch:** `checkpoint-4-world-creator`, from `main` at `11e17f0` (Checkpoints 0–3 merged by PRs #1–#4). Commits: `078211f` (email-setting note carried over), `1c70075` (4A: details and migration), `581fb0c` (4B–4F: creator), `7aab36b` (records), `dc61038` (duplicate-upload retry fix, 4G records), `e75419b` (Create-tab leave guard, live checks), `4d6875e` (visual identity, D-031), plus these records. Only `078211f` is on GitHub; the rest are local.
- **Started:** the owner approved Checkpoint 4 with a written brief (stages 4A–4G) and asked for work to continue without questions unless genuinely blocked. Restrictive defaults were taken where the documents conflict or are silent and reported in the baseline: D-023 to D-029. Backend hosting stays on Supabase Cloud (owner, D-030).
- **Baseline before coding:** `dart format` 82 files, 0 changed; `flutter analyze` no issues; `flutter test` 138 of 138. Database: the three earlier migrations only; tables `profiles` and `worlds`; no storage bucket; one profile, no Worlds.

### Database
- `supabase/migrations/20261120090000_create_world_authoring.sql`:
  - `worlds.location` may be empty for drafts; `cover_asset_id` references `world_assets`.
  - `world_assets`, `world_content_blocks` (deferred unique position), `private.world_question_secrets` (no API access), all with row level security; clients have no write grants.
  - Private `world-media` bucket (5 MB; JPEG, PNG, WebP) with upload, read and delete policies on `storage.objects`.
  - Functions `save_world`, `get_world_draft`, `publish_world`, `unpublish_world`, `delete_world`, `register_world_asset`, `forget_world_asset` (signed-in only) and `get_world_details` (everyone). See `docs/DATABASE.md`.
- `supabase/tests/world_authoring_test.sql`: about 70 checks covering grants and row level security, bucket settings, answer normalisation (case, spaces, Unicode compatibility forms), signed-out refusal, create and idempotent retry, answers hashed and never returned, rejected content (an `answer` key in a block, a part not allowed in the category, unknown keys, lengths, 31 parts, a bad latitude), publish problems, idempotent publish, published Worlds staying complete, discovery and details without content or answers, another user unable to read, save, unpublish, delete or hijack block ids, unpublish, forward-only story choices, reorder, removal, category rules, asset registration (owner, folder, type and size), storage upload policy, covers public only while published, hidden and deleted Worlds, the daily creation limit and table constraints.
- **Applied, 2026-11-20:** the owner ran three prepared files in the Supabase SQL editor, because data-changing SQL through the Supabase connection needs an approval prompt this editor declines automatically.
  - Dry run (migration plus all three test files, rolled back): `WORLDS_ALL_TESTS_PASSED: profiles_test 32 checks; worlds_test 36 checks; world_authoring_test 74 checks`.
  - Apply (the file plus its migration-history row): "Success. No rows returned". `list_migrations` now shows `20261120090000 create_world_authoring`. The stored statement equals the committed file apart from Windows line endings added by the clipboard (1,199 CR characters; md5 without them `226b7fd74bdc2f8b8936f78403199311`, the same as the file).
  - Tests against the applied schema: the same 32, 36 and 74 checks passed.
  - Read-only checks afterwards: three new tables with row level security, the private bucket (5 MB; JPEG, PNG, WebP), three storage policies, eight new functions with the intended grants (only `get_world_details` callable signed out), and no API access to the `private` schema.
  - Security advisor: an INFO note that `private.world_question_secrets` has no policies (intended: no client access); WARN notes that signed-in users can call the eight `security definer` functions and that anyone can call `get_world_details` (intended: they are the API and check `auth.uid()` themselves); and a WARN that leaked-password protection is off in Auth settings. Performance advisor: INFO notes on unused indexes, expected while the tables are empty.
- **Stage 4G, creator to explorer, 2026-11-20:** a script used the public APIs exactly as the app does (publishable key, real user sessions) with two labelled test accounts (`e2e_creator_74c7a3`, `e2e_explorer_74c7a3`, `example.com` addresses) and a test World in the South Pacific (-41, -121). **46 of 46 checks passed**:
  - Account A saved a puzzle (answer stored, never returned), retried the save, uploaded a PNG, registered it, set it as the cover and published, then published again without change.
  - Storage refused an overwrite, a GIF, a file over 5 MB, uploads into another user's folder, a signed-out upload, and account B uploading into A's World.
  - Account B and a signed-out visitor found the World in nearby search with a server-computed distance, opened its details (cover, part count, no content, no answer) and could show the cover, but could not read A's unused image or any block content.
  - Account B could not read A's draft copy, save over it, unpublish it, delete it, release its images or reuse its block ids; direct table writes and signed-out saves were refused; an answer inside block content and emptying a published World were refused.
  - After A unpublished, B could neither find nor open the World. A released and deleted both images and deleted the World.
  - A follow-up probe showed that uploading the same file twice returns HTTP 400 with `{"statusCode": "409", "error": "Duplicate"}`; the app's retry path now accepts either field.
  - Left behind: two soft-deleted test Worlds (invisible to everyone), no files, and the two test accounts, kept for Checkpoint 5's two-account tests.

### App
- **4A, World details** (`lib/features/worlds/presentation/world_details_screen.dart`): cover or category panel, title, category, creator, description, unlock radius with a Locked panel (distance from the user only when they shared a location), part count, creator status (Draft, Unpublished, Published, Hidden). Actions only where they work: "Show on map" (focuses the World on Explore) and, for the creator, "Edit World". No Start, Unlock, Save, Share or Report yet. Loading, not-available and error-with-retry states. Opened from the Explore preview card and from each list row.
- **4B, Create tab** (`create_screen.dart`): the creator's Worlds grouped as Drafts, Published and Hidden by moderation, a first-World empty state, loading and retry. "New World" opens the editor with an app-chosen id.
- **4C, Details and place:** title, description and optional cover; place picker with a centre pin, the unlock radius drawn at true size, a 25–150 m slider with a GPS-accuracy note, "Use my location" with an explanation before Android's prompt (no location read otherwise), and the public-place safety note.
- **4D, Content:** typed editors for text, image, choice (2–4 options leading only to later parts), question (answer field that clears once stored), artwork and ending; only the parts the category allows; reorder by drag or Move up/Move down; incomplete parts marked.
- **4E, Saving and images:** every step saves the whole World before moving on; unsaved-changes guard on leaving; save errors shown with retry. Photos from the system picker, resized, checked by their bytes, uploaded under a fixed id so a retry completes the same upload; replaced images are released.
- **4F, Review and publish:** problems with Fix links, an explorer preview that follows choices (shared renderer for the future player), a required public-place confirmation, Publish (saves first; a retry after a timeout cannot publish twice), Unpublish, "View on map", Delete World.
- Dependency added: `image_picker` 1.2.3 (D-028). Architecture tests keep it in `lib/core/media` and forbid photo, storage and camera permissions.

### Tests and results
- `dart format --output=none --set-exit-if-changed .` — 129 files, 0 changed.
- `flutter analyze` — no issues.
- `flutter test --timeout 60s` — 211 of 211 passed (73 new: details screen, creator flows end to end with fakes, editor controller, publishing rules, draft codec, media and utility helpers, error mapping, routes, architecture). The tests caught three layout bugs before any device saw them: the editor's bottom bar overflowing on a 411 dp phone, details actions laid out below the screen, and the preview's bottom bar taking the whole body height.
- `flutter build apk --debug --dart-define-from-file=.env` — passed. Permissions in the built APK: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, and AndroidX's app-internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. No background location, storage, media or camera permission.

### After review (same day)
- **The app's own data layer against the real backend:** `test_live/authoring_repository_live_test.dart` runs the app's Supabase repositories as the two test accounts (save and retry, list, load, image upload and the duplicate retry path, cover, publish, nearby and details as the other account, the cover through its signed URL, refusals arriving as the app's own failures, unpublish, typed publish problems, clean-up). Passed (`flutter test test_live`, 1 test, about 11 s). Not part of `flutter test`.
- **Silent data loss fixed:** tapping the active Create tab returned to its first screen and closed the editor without asking, dropping unsaved changes. The editor now registers a leave check that the bottom navigation asks first. Regression test added (212 tests).
- **The 4G script is now in the repository** as `tool/e2e/creator_to_explorer.mjs`; the test accounts' passwords stay in the gitignored `tool/e2e/.accounts.json`.
- **Visual identity (D-031):** at the owner's request ("the UI is not nice … make it high quality"), the living-atlas direction from the UI spec was implemented: tokens and component themes, full-screen Explore map with floating controls, richer preview card, cover hero with atlas contours, Create cards and first-World state, segmented editor progress, review checklist and a "Your World is live" moment. `test_screens/` renders the main screens with sample data so the design can be reviewed; each screen was rendered and checked at 411 × 891 dp before handover. 212 of 212 tests pass; `flutter analyze` reports no issues.

### Manual device verification
The redesigned build (`4d6875e`) with the applied backend was installed on the owner's phone over USB and launched: it is running, with nothing in the crash log and no Flutter errors or layout overflows in the system log. The screen has **not** been seen, so the creator, place picker, photo picker, preview and details screen are not visually verified on a device. The owner's checklist is in the Checkpoint 4 report.

### Known issues
- The server checks an uploaded file's declared type, extension, owner and size, but does not decode the image; a mislabelled file would be stored but fail to display. Server-side decoding would need an Edge Function.
- Files of deleted Worlds, and files whose release fails, stay in storage; there is no scheduled clean-up yet.
- No thumbnails: images are resized on the phone to 2,048 px only.
- Leaked-password protection is off in Supabase Auth (security advisor WARN); turning it on is a dashboard setting and may need a paid plan.
- Two soft-deleted test Worlds from the 4G check remain in the database, invisible to everyone; the two test accounts remain for Checkpoint 5.
- Unlisted Worlds (G1) remain open. The play-account decision was made later the same day (D-032).
- Corrected 2026-11-21: this list said the visual design was still the Material 3 baseline. That was written before the redesign recorded under "After review"; the "living atlas" direction was adopted at the owner's request as D-031, with its exact values still open to the owner's review.

### Approval status
Pending the owner's device check and approval. The Checkpoint 4 gate (publish with account A, verify as account B) passed at the API level with the real backend.

## Checkpoint 5 record

- **Dates:** 2026-11-20 (implementation) and 2026-11-21 (database applied, review fixes, these records).
- **Branch:** `checkpoint-5-world-player`, from `checkpoint-4-world-creator` at `98ad78d`. Commits `bd7a479` (player, unlocking, migration), `ddc612a` (screen renders, live check) and `e662d8e` (decisions and schema notes) are on GitHub. `5dfeb6d` (image access, applied migration, player fixes, tests) and the documentation commits after it, starting with `cc4a273`, are local and not pushed, so the branch on GitHub still holds the first version of the migration under its old file name.
- **Started:** work began on 2026-11-20, the day the owner decided that unlocking and playing need an account (D-032). The unlock and play rules were chosen by the implementation and are recorded as proposed (D-033). The session of 2026-11-21 continued at the owner's "continue"; it had no record of the wording of the approval to start, so none is quoted here.
- **Baseline on 2026-11-21, before any change:** `dart format --output=none --set-exit-if-changed .` 147 files, 0 changed; `flutter analyze` no issues; `flutter test --timeout 60s` 230 of 230. Database: four migrations; the play migration was committed but not applied.

### Database
- `supabase/migrations/20261121051737_create_world_play.sql` (committed first as `20261121090000_…`, renamed to the version Supabase recorded):
  - `world_progress` (current part, `path`, `answered`, completion count) and `world_visits`, readable by their owner only, written only by the functions; `private.world_answer_attempts` with no API access. Row level security on all three.
  - `unlock_world`, `get_world_play`, `advance_world`, `answer_question`, `restart_world`: signed-in users only, each checking `auth.uid()` and that the World is published and public. `get_world_details` now also returns `play_status`.
  - `is_unlocked_world_image` and a second read policy on `world_assets`: an account that unlocked a published World can read the images its parts use.
- **Changed on 2026-11-21, before applying** (the migration had never been run, so it was still editable):
  - The first version let a player read every image registered to an unlocked World, including ones no part uses, and gave signed-out users a `select` grant on `world_progress` to make its policy work. Now players read only the images the parts use, the Checkpoint 4 policy is left as it was, and signed-out users have no access to progress.
  - `supabase/tests/world_play_test.sql` gained checks for that, for a World hidden by moderation (content, restart, answers, details and images all refused to a player who had unlocked it), for resuming after a fresh load, and for the grants of every play function.
- **A test that could not pass:** the first dry run stopped at `FAIL puzzle: the answer or its success message was served`. The committed test searched the play content for "keeper", and its fixture World is titled "Keeper Riddle". The functions were right; the test now searches for the answer and the success message. This also shows the SQL had not been executed anywhere before 2026-11-21.
- **Applied on 2026-11-21 through the Supabase connection** (D-015):
  - Dry run, migration plus `world_play_test.sql` as one rolled-back statement: `WORLDS_ALL_TESTS_PASSED: world_play_test 52 checks`. The three older test files were not part of the dry run; they ran after applying.
  - Apply with `apply_migration`, name `create_world_play`: success. Recorded version `20261121051737`. The stored statement's md5 is `df539f313babd8796475bab352bd12d7`, the same as the committed file (23,922 characters, one statement).
  - Tests against the applied schema, each file as one rolled-back statement: `world_authoring_test 74 checks`, `world_play_test 52 checks`, `profiles_test 32 checks`, `worlds_test 36 checks`.
  - Every test statement carried the md5 of the committed file and would have refused to run if its text differed.
  - Read-only checks afterwards: row level security on the three new tables; the two read policies on `world_assets`; the five play functions and `is_unlocked_world_image` callable by signed-in users only; `get_world_details` still callable signed out.
  - Security advisor: INFO that `private.world_answer_attempts` and `private.world_question_secrets` have no policies (intended: no client access); WARN that signed-in users can call 14 `security definer` functions and anyone can call `get_world_details` (intended: they are the API and check the caller themselves); WARN that leaked-password protection is off in Auth settings.
  - Performance advisor: INFO on four unused indexes (little data yet); WARN that `world_assets` has two permissive read policies for signed-in users. That is the price of keeping the players' rule separate from the Checkpoint 4 policy; with at most 40 images per World it costs nothing measurable.
- **Tooling:** `tool/sql/build_editor_sql.js` now writes each file as one statement that verifies its own text (md5) before running, and reports a failure by its message alone.

### Account A to account B (the Checkpoint 5 gate, at the level of the app's data layer)
`flutter test test_live` — 2 of 2 passed against the development project, with the two labelled test accounts and a test World far out at sea. `test_live/play_repository_live_test.dart` uses the app's own repositories:
- A uploads two pictures, saves and publishes a puzzle (text, picture, question, ending); one picture is used by a part, the other is not.
- B sees it as locked and is refused its content and its picture; an unlock from about 222 m away is "too far"; an unlock at its place succeeds and details then say "in progress".
- B receives four parts without the answer or the success message, and the one picture the parts use. B fetches that picture through Storage with a signed address (HTTP 200) and is refused the unused one.
- B steps forward; a repeated step changes nothing; the question cannot be skipped; a wrong answer leaves 4 tries; the right answer in other case and spacing returns the success message.
- B finishes; finishing again counts once; details say "completed"; a fresh load still says completed; starting again keeps the count.
- After A unpublishes, B gets "not available" and the picture is refused again. A releases both pictures and deletes the World.
- Left behind in the development database, counted on 2026-11-21 after the last run: 13 soft-deleted test Worlds (invisible to everyone; they include earlier checkpoints' runs), 3 progress rows, 3 visit rows and 4 answer attempts of test account B, no files and no image records.

### App
- **Details** (`lib/features/world_player/presentation/play_panel.dart`): a locked or unlocked panel and one main action that matches the real state: "Sign in to unlock", "Check my location" (then "Check again"), "Start", "Continue" or "Play again". Before Android's prompt, a dialog says one reading is taken now, not stored, not tracked and not shown to others. Too far (with the distance and radius), a vague reading (over 100 m, refused before asking the server), permission refused, blocked (opens Settings), location off, no fix and server failure each have their own message and a way to try again.
- **Location** (`lib/core/location`): `currentFix` takes one high-accuracy reading with its uncertainty and a 20-second limit. No streams, no background use.
- **Player** (`lib/features/world_player`): full screen above the tabs at `/play/:id`; one part at a time on the renderer shared with the creator's preview; a thin progress bar and "Part n of m"; story options as cards; an answer field with tries left; Continue or Finish at the bottom; a completion screen with "Find another World" and "Play again". The app never moves on by itself: every step, answer and restart is the server's.
- **Sign-in:** opening the player signed out leads to sign-in and back to the World's details.
- **Fixed on 2026-11-21 after reading the code against the journeys:**
  - After too many wrong answers the answer field stayed closed until the player was reopened. It now reopens when the server's pause ends.
  - A failed "Play again" on the completion screen showed nothing. It now says so and can be tried again.
  - If the creator changed the World while someone played it, the player could sit on a spinner for ever. It now loads the World again, and a place it cannot show offers "Try again". A failed reload is reported like a failed step.

### Tests and results (2026-11-21, after all changes)
- `dart format --output=none --set-exit-if-changed .` — 147 files, 0 changed.
- `flutter analyze` — no issues.
- `flutter test --timeout 60s` — 236 of 236 passed. Player and unlocking tests cover: a branching story to its end and again; a puzzle with a hint, a wrong and a right answer; the pause after too many tries and its end; a failed step, a stale step, a failed catch-up; a World changed mid-play; a place the app cannot show; a failed "Play again"; picture and artwork parts with the images they use; locked, unavailable and resumed Worlds; the explanation before the prompt, too far, a vague reading, refused permission, Continue and Play again on details; the sign-in redirect.
- `flutter test test_live` — 2 of 2 passed (real backend), run again after the picture checks were added.
- `flutter build apk --debug --dart-define-from-file=.env` — passed. Permissions in the built APK are the same as in Checkpoint 4: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE and AndroidX's app-internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. No background location, storage, media or camera permission.
- Database: 32, 36, 74 and 52 checks, as above.

### Acceptance criteria (docs/FEATURE_ACCEPTANCE_CRITERIA.md, section 7)
| Criterion | Status | Evidence |
| --- | --- | --- |
| Only server-authorized content | Met | `get_world_play` refuses before unlocking (WR403) and for unpublished, hidden or deleted Worlds; SQL tests and the live check |
| Renderer supports the six part types | Met in tests; real pictures not seen on a screen | Shared `BlockView`, used by the creator's preview and the player; player tests show text, picture, artwork, choice, question and ending parts (pictures as placeholders). The live check proves a player can fetch a part's picture from Storage |
| Valid choices only | Met | `advance_world` takes an option id and finds the destination itself, in the same World and later in the list; unknown options refused |
| Answers checked by the server, limited, never sent | Met | Hash comparison in `answer_question`; five wrong per ten minutes; payload checks in SQL tests and the live check |
| Fresh foreground reading at unlock; uncertainty and retry explicit | Met in tests; not on a device | One reading on tap; over 100 m refused with advice; "Check again" |
| Account requirement decided and documented first | Met | D-032 |
| Progress server-confirmed and resumed | Met at the API level | A fresh load returns the server's place (SQL test, live check, widget test). Killing the app on a phone, reinstalling and signing in again are not tested |
| Duplicate steps and completion idempotent | Met | Stale steps change nothing; completion counted once (SQL tests, live check) |
| Unpublished and hidden behaviour consistent and tested | Met | Both refuse content, steps, answers, restart and images; details stay open only to the creator |
| Complete flow for creator A and explorer B | Met through the app's data layer; not on devices | `flutter test test_live` |

### Manual device verification
None for Checkpoint 5. `adb devices` listed no device on 2026-11-21. The last build installed on the owner's phone is Checkpoint 4's (`4d6875e`), which has no player. Unlocking depends on a real GPS reading, so this is the largest untested part of the checkpoint.

### Known issues
- Unlocking and the player have never run on a phone. The 100 m accuracy limit and the 25 m allowance are untested in the field; indoors or between tall buildings a phone may not reach 100 m.
- GPS is a convenience gate. A spoofed position unlocks a World; nothing claims otherwise.
- `world_visits` keeps, per account and World, the first and last time an unlock succeeded and a count. No coordinates are stored, but a row does say that the account was at that World's place at those times. Review against `docs/SECURITY_AND_PRIVACY.md` before the pilot.
- "Part n of m" and the progress bar count every part, including branches the reader did not take.
- Reopening the player on a question already answered shows "Correct!" rather than the creator's success message.
- "Play again" from the details screen shows the completion screen for a moment before the first part.
- There is no way back to an earlier part, and the completion screen has no save or share action (Checkpoint 6).
- If the creator removes the part a player is on, that player restarts from the first part and answers questions again.
- A part type or schema version the installed app does not know stops the player with a general error; there is no "update the app" message.
- Answer attempts are kept for the limit and never cleaned up. The limit is per account, and accounts are free to create while email confirmation is off.
- The design-review renders were regenerated on 2026-11-21 (`flutter test test_screens --update-goldens`, 9 of 9). They show the normal states only, not the failure states the fixes touch. Run without `--update-goldens`, that script compares against whatever images are on the machine and is not a test.
- The player and the unlock panel have not been checked with large text or TalkBack.
- No mutation check was run for the play SQL tests (weakening a rule to see a test fail), as Checkpoints 2 and 3 had. The tests did fail once for a real reason, the wrong check described above.
- Open from earlier checkpoints: unlisted Worlds (G1), the pilot area (D-021), the application ID, custom SMTP and email confirmation, leaked-password protection.

### Approval status
Pending the owner's device check and approval. Checkpoint 6 has not been started.

## Checkpoint 6 record

- **Date:** 2026-11-21.
- **Branch:** `checkpoint-6-saved-profile-moderation`, from `checkpoint-5-world-player` at `3081614`. Commits: `05b3158` (database), `3ac2386` (data layer, live check), `5011b0b` (screens and tests), `fd2df92` (renders), `07ef6a1` (bookmark style), `3002b62` (decisions, schema notes, runbook), `eb496d1` and later (this record). The branch was published to GitHub at its starting commit `3081614`; the Checkpoint 6 commits are local, not pushed.
- **Started:** the owner wrote "pushed continue further" after the Checkpoint 5 report, having pushed that branch. The device checks of Checkpoints 4 and 5 and the decisions listed in that report were still open. Where the documents leave a choice, restrictive defaults were taken and recorded as proposals: D-034 (saved Worlds), D-035 (reports), D-036 (moderation in the dashboard only), D-037 (profile pages and counts), D-038 (no share links yet).
- **Baseline before coding:** the Checkpoint 5 results at `3081614`, run earlier the same day: 147 files formatted with none changed, no analysis issues, 236 of 236 tests, live tests 2 of 2.

### Database
- `supabase/migrations/20261121060535_create_saved_reports_moderation.sql` (written as `20261121120000_…`, renamed to the version Supabase recorded):
  - `saved_worlds` with `set_world_saved` and `get_saved_worlds`; `world_reports` with `report_world`; `private.moderation_actions` with `private.hide_world`, `restore_world`, `remove_world`, `dismiss_reports` and `moderation_queue`; `get_profile_page`; `get_world_details` now also returns `is_saved`. Details in `docs/DATABASE.md`.
  - Row level security on the three new tables. Clients cannot write them. API roles cannot reach the moderation functions or the log at all.
- `supabase/tests/community_test.sql`, 47 checks: grants and row level security; profile pages (exact field list, public and own views, paging, unknown username); saving (repeatable, drafts refused, order, distance, paging, privacy from other accounts and from the creator, an unpublished World counted and not listed, the 500 limit); reporting (reasons, length, drafts and own Worlds refused, a second report changing nothing, the moderation status unreadable, privacy, ten a day per account); moderation (the queue, a note required, hide, what a hide closes off, the creator unable to republish, delete or call moderation, restore, dismiss, remove, the log holding exactly the four actions).
- **Applied on 2026-11-21 through the Supabase connection** (D-015):
  - The first dry run was declined by the connection's confirmation step, which this editor answers "no" without showing it. Two small probes that could not change anything showed the cause: `delete` statements in the test's clean-up. The test was rewritten to need no clean-up (other fixtures instead), not disguised. The migration itself was not changed.
  - Dry run, migration plus `community_test.sql` as one rolled-back statement: `WORLDS_ALL_TESTS_PASSED: community_test 47 checks`.
  - Apply with `apply_migration`, name `create_saved_reports_moderation`: success. Recorded version `20261121060535`. The stored statement's md5 is `aab70225993b4124fdb08bf8bdac1ebb`, the same as the committed file (23,133 characters, one statement).
  - **A test that only passed on an empty database:** `community_test.sql` first counted the whole moderation queue and the whole log. That held in the dry run, when there were no real reports, and would have failed afterwards: the live checks leave real pending reports behind, and so will real use. Found in review after applying; the three counts are now limited to the test's own Worlds.
  - Tests against the applied schema: the corrected `community_test.sql` as one rolled-back statement, with two real pending reports in the database: `WORLDS_ALL_TESTS_PASSED: community_test 47 checks`.
  - The four older test files were not part of the dry run and were first run with this migration later the same day, against the applied schema, each as a rolled-back statement: `world_authoring_test 74 checks`, `world_play_test 52 checks`, `profiles_test 32 checks`, `worlds_test 36 checks`. With `community_test`, all five files have passed against the applied schema. `.sql-to-run/3-tests-after-apply.sql` runs all five in one paste in the SQL editor.
  - Read-only checks afterwards: row level security on the three tables; one read policy each on `saved_worlds` and `world_reports`; signed-in users may select only `id`, `world_id`, `reporter_id`, `reason`, `description` and `created_at` of `world_reports`; the saving and reporting functions callable by signed-in users only; `get_profile_page` and `get_world_details` callable signed out; the six moderation functions callable by no API role.
  - Security advisor: INFO that the three private tables have no policies (intended: no client access); WARN that anyone can call `get_profile_page` and `get_world_details` and that signed-in users can call 18 `security definer` functions (intended: they are the API and check the caller themselves); WARN that leaked-password protection is off. Performance advisor: INFO on seven unused indexes; the WARN about two read policies on `world_assets` from Checkpoint 5, unchanged.

### Against the real backend
- `flutter test test_live/community_live_test.dart` passed right after applying, and again in the full `flutter test test_live` run at the end (3 of 3). It uses the app's own repositories as the two test accounts:
  - B publishes a World. A sees it as not saved, saves it twice (one row), sees it saved in details and in the list with the creator and a distance of about 111 m.
  - B, its creator, cannot see the save: neither through the app's repository nor by reading `saved_worlds` directly.
  - A removes it. A reports it (details trimmed by the server); a second report says "already reported"; B cannot report their own World.
  - A can read their own report but not its status; B can read no report of their World.
  - A sees B's page with the World and without private counts; B sees their own counts; an unknown username is "not found".
  - After B unpublishes, A can no longer save it.
- The existing authoring and player live tests passed against the new schema (2 of 2).
- Left behind, counted after the final run: 21 soft-deleted test Worlds in all (invisible to everyone), no saved rows, no files, an empty moderation log, and two pending reports by test account A of deleted `[e2e]` Worlds (one per run of the community test). The runbook says how to close such reports.
- The daily limits apply to the test accounts too. Account A has created 19 Worlds in 24 hours (limit 20), so the authoring and player live tests cannot run again until the oldest of those is a day old, from about 10:50 UTC on 2026-11-21. A refusal with "too many attempts" there is the limit, not a regression.

### App
- **Saved tab** (`lib/features/saved`): the account's own list with cover or category panel, title, category, creator and, when the user has already shared a location on Explore, distance. Removing takes the World out at once and puts it back with a message if the server refuses. Twenty at a time with "Show more". Saved Worlds that are not published now are counted, not listed. Loading, empty (with "Explore the map"), error and retry states. The list and the saved flags are tied to the signed-in user and start again when another signs in.
- **World details:** a bookmark that saves at once and goes back with a message on failure; signed out it leads to sign-in and back to the World. "Report this World" in a menu, only for Worlds made by someone else. The creator line opens the creator page. Back works wherever the page was opened.
- **Report form** (`lib/features/moderation`): one of six reasons, optional details up to 500 characters with a counter, Send disabled until a reason is chosen, a confirmation that says the creator is not told who reported, and its own words for "already reported", the daily limit and a World that is gone. A failure shows beside the Send button and the form is kept.
- **Creator page** (`/creators/<username>`): display name, username, bio, the number of published Worlds and the Worlds themselves, a page at a time. No activity counts.
- **Own profile:** Published, Discovered and Completed as the server counts them, the published Worlds, and a line leading to Create when there are unpublished ones.
- **Routes:** World details and creator pages also open as full pages above the tabs (`/worlds/<id>`, `/creators/<username>`), so Back returns to Saved or to the page they came from. `/report/<id>` needs an account.
- No Share action and no unlisted Worlds (D-038). No moderator screens (D-036).

### Tests and results (2026-11-21, after all changes)
- `dart format --output=none --set-exit-if-changed .` — 170 files, 0 changed.
- `flutter analyze` — no issues.
- `flutter test --timeout 60s` — 273 of 273 passed (37 new; two of them, added after the report, run the new screens at 200% text). New tests cover: Saved signed out, empty, populated, opening details and coming back, removal and its rollback, paging, a failed load and retry, the unavailable count, and one account never seeing another's list; saving from details with rollback, a World saved earlier, the Saved tab following a save, and the sign-in round trip from a signed-out save; the report flow, a second report, the daily limit with the form kept, a failed send and retry, no report action for the creator, and sign-in when signed out; creator pages (public fields only, opening from a World and back, paging, unknown username, failed load, no Worlds); the own profile's counts, zeros and a failed load; the server field mappings; the redirects.
- The first run of the new tests caught two layouts that overflowed with wide text (the report menu label and the profile counts row) and a report error shown out of sight at the end of a scrolling form. All three were fixed.
- `flutter test test_live` — 3 of 3 passed (real backend).
- `flutter test test_screens --update-goldens` — 12 of 12; seven new renders (Saved, details with a saved World, the report form and its confirmation, Saved when empty, the own profile, a creator page). All seven were looked at.
- `flutter build apk --debug --dart-define-from-file=.env` — passed. Permissions unchanged: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE and AndroidX's app-internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. No background location.
- Database: all five test files against the applied schema: 32, 36, 74, 52 and 47 checks, as above.

### Acceptance criteria (docs/FEATURE_ACCEPTANCE_CRITERIA.md, section 8)
| Criterion | Status | Evidence |
| --- | --- | --- |
| Save and remove persist; optimistic UI rolls back on failure | Met | SQL tests, live check, widget tests for both rollbacks |
| Saved list private to the user and paginated | Met | Other accounts and the creator read nothing (SQL tests, live check); pages of 20; the account-switch widget test |
| Profile shows real data only; counts backed by real queries | Met | Counts come from `worlds` and `world_progress`; zeros when there is nothing; private counts null for anyone else |
| Creator's drafts and published Worlds separated | Met | The Create tab groups them (Checkpoint 4); the profile lists published Worlds and links to Create for the rest |
| Report flow validates reason and details and rate limits | Met | Server checks and limits in SQL tests; the form's own limits and messages in widget tests |
| Reporter identity and details not exposed to creator or public | Met | SQL tests and the live check, reading the table directly as the creator |
| Trusted moderator role is server-controlled | Met by having no role in the app | Moderation runs only in the dashboard (D-036); API roles are refused (SQL tests). The owner has not confirmed this approach |
| Hide or unpublish removes content from discovery promptly | Met in tests | After a hide: nearby search, details, play, saving, the saved list and the profile page all drop it in the same transaction. Not run against real data |
| Moderation action auditable and not bypassable by the creator | Met in tests | One log row per action with who, why, before and after; a refused action changes nothing; the creator cannot republish, delete or call moderation |
| Deletion and retention behaviour documented | Documented as implemented | `docs/DATABASE.md`. Retention periods and account deletion are undecided |

### Manual device verification
None. No phone was attached on 2026-11-21. The last build on the owner's phone is Checkpoint 4's.

### Known issues
- Nothing in this checkpoint has run on a phone. Large text was checked in widget tests only (Saved, details, the report form, a creator page and the own profile lay out without overflow at 200%); TalkBack is unchecked.
- No moderation action has been run on the development database outside rolled-back tests. The runbook should be tried once on a test World before the pilot.
- The dry run before applying covered only the new test file; the four older files ran after applying (see Database).
- A creator whose World is hidden sees "Hidden by moderation" and nothing else: no reason, no way to appeal. A reporter is never told the outcome.
- Reports of a World that was deleted afterwards stay in the queue until dismissed, including one per run of the live test.
- The Discovered count includes Worlds that were unlocked and have since been unpublished or removed.
- The saved list reloads when a World is saved or removed in this app; a change made on another device shows after pulling to refresh or reopening.
- No Share action, no unlisted Worlds, no account deletion, no retention periods, no product events (`world_saved`, `world_reported`); the last belongs to Checkpoint 7.
- Open from earlier checkpoints: the device checks of Checkpoints 4 and 5, the proposed unlock thresholds (D-033), `world_visits` timestamps against the privacy document, the pilot area (D-021), the application ID, custom SMTP and email confirmation, leaked-password protection.

### Approval status
Pending the owner's moderation and privacy review. Checkpoint 7 has not been started.

**Later on 2026-11-21:** the owner pushed the branch, asked for work to continue ("pushed continue further") and merged it into `main` as pull request #8. No answer to the review is on record.

## Checkpoint 7 record

- **Date:** 2026-11-21.
- **Branch:** `checkpoint-7-pilot-readiness`, from `checkpoint-6-saved-profile-moderation` at `ea76409`. Commits: `495233f` (events migration), `514c774` (the four events in the app), `01d15a4` (migration applied, live check), `7858e89` and `4bb5890` (large text), `7410ec4`, `221056b` and `6a3be5f` (motion and its tests), `5d15c2b` (dark-theme contrast), `12aff72` (tap targets and the accessibility guideline checks), `b8389c0` (the two text colours the owner approved), and the commits with this record. The owner pushed the branch to GitHub more than once while the work was in progress. The agent pushed nothing.
- **What this checkpoint is, and is not:** it is the part of "Beta and pilot" that is code and records: measuring the funnel, layouts at large text, contrast, motion, what the app logs, and what the providers promise. The pilot itself needs phones, testers, a chosen area and 15 to 20 curated Worlds, and has not been run. Nothing here should be read as "the pilot is ready".
- **Started:** the owner wrote "pushed continue further" after the Checkpoint 6 report, having pushed that branch, and merged it into `main` later the same day (pull request #8). The moderation and privacy review that report asked for was not given, and D-034 to D-038 were not answered. Restrictive defaults were taken again: D-039 (product events).
- **Asked for during the checkpoint:** the owner wrote "use good animation and transition and smothness". Taken as approval of the Motion list in `docs/UI_UX_SPECIFICATION.md` and nothing more of that section (D-040).
- **Baseline before coding:** the Checkpoint 6 results at `ea76409`: 273 of 273 tests, no analysis issues.

### Database
- `supabase/migrations/20261121081022_create_product_events.sql` (written as `20261121130000_…`, renamed to the version Supabase recorded): `private.product_events`, `private.world_event_counts`, `public.log_event`, and `private.pilot_funnel`, `pilot_summary` and `pilot_worlds` for the SQL editor. Details in `docs/DATABASE.md`; the reasoning in D-039.
- `supabase/tests/product_events_test.sql`, 18 checks: who may send and who may read, what an event may hold, unknown events and outcomes refused, the per-launch and daily limits, the 90-day clearing, per-World totals for published public Worlds only, and the three pilot functions. It needs no clean-up and counts only its own launches or the difference from a first count.
- **Applied on 2026-11-21 through the Supabase connection** (D-015):
  - Dry run, migration plus its test as one rolled-back statement: `WORLDS_ALL_TESTS_PASSED: product_events_test 18 checks`.
  - Apply with `apply_migration`, name `create_product_events`: success. Recorded version `20261121081022`. The stored statement's md5 is `6ccf29a8ef1702c14215757dfa03f778`, the same as the committed file (9,821 characters, one statement).
  - **All six test files against the applied schema**, each as one rolled-back statement that checks its own text before running: `profiles_test 32 checks`, `worlds_test 36 checks`, `world_authoring_test 74 checks`, `world_play_test 52 checks`, `community_test 47 checks`, `product_events_test 18 checks`. Each passed at the first attempt. A helper agent relayed the six built statements unchanged; a statement altered on the way would have run nothing.
  - Read-only checks afterwards: row level security on both tables, no policies, no privileges for `anon` or `authenticated`; neither role may use schema `private`; `log_event` callable by both; the three pilot functions callable by neither.
  - Security advisor: INFO that five private tables have no policies (the two new ones among them; intended, no client access); WARN that `log_event`, `get_profile_page` and `get_world_details` can be called signed out and that signed-in users can call 19 `security definer` functions (intended: they are the API and check the caller themselves); WARN that leaked-password protection is off. Performance advisor: INFO on six unused indexes (two of them new); the WARN about two read policies on `world_assets` from Checkpoint 5, unchanged.

### Against the real backend
- `flutter test test_live/product_events_live_test.dart` — 1 of 1, twice: after applying, and in the final verification at 10:06 UTC. Signed out, through the app's own sink: three events accepted; an unknown event and a free-text outcome refused; `product_events`, `world_event_counts` and `pilot_summary` unreachable through the API.
- Left behind: three events per run, each run under a launch id of its own; no per-World totals. The server clears them after 90 days.
- **The other live tests** (authoring, player, community) could not run during the work: test account A had made 19 of its 20 Worlds for the day, and the limit reopened at about 10:50 UTC on 2026-11-21. A full `flutter test test_live` run started at 10:53 UTC and passed, 4 of 4: authoring, player, community and product events, all through the app's own repositories. Like every run it leaves soft-deleted `[e2e]` Worlds, one pending report of one of them (close it with `dismiss_reports`) and three events.

### App
- **Product events** (`lib/core/analytics`, `lib/core/network/supabase_product_event_sink.dart`): Explore opened (once per launch), a World selected, details opened (once per World per launch, and not the creator's own), an unlock attempted with how it ended. The methods take no position, so none can be sent, and an architecture test keeps position-holding code out of these files. Sending never waits and never throws.
  - **Caught by existing tests:** the first version read the backend client while Explore was being built, which broke the two startup tests. The client is now asked for only when an event is sent, inside the guarded call, with a test that a backend that never started cannot break a screen.
- **Large text.** `test/app/large_text_test.dart` walks the screens of Checkpoints 2 to 5 at 200% text in 26 checks. It found and fixed:
  - An Explore message with a button left its text a column a few letters wide. The button now goes under the message when text is large.
  - Over the map, messages ran off the screen when they could not all fit. They scroll now.
  - The preview card's button and the editor's "Incomplete" chip overflowed their rows. Both now drop to their own line.
  - The editor's five step names were cut off (not an overflow, so the test could not see it). Above 130% the bar shows numbers with "Step 4 of 5: Content" underneath; each segment keeps its full name for screen readers.
  - Nothing changes at ordinary sizes. The test proves no overflow and that every screen can be reached and used; it cannot see text that is merely cut short, and it uses the test font, which is wider than the phone's.
- **Contrast** (D-041): every colour pair measured. In the dark theme category names and icons were unreadable (Story 2.3:1) and now use the shade the badge already used (6.0:1 or better). In the light theme, by the owner's choice on 2026-11-21, Puzzle's name is `#8E5500` (6.1:1, was 4.2:1) and the distance label `#885010` (5.1:1, was 4.2:1); icons, badges, markers, panels and tints are unchanged. `test/shared/category_contrast_test.dart` measures all of it. Four smaller light-theme shortfalls remain and are listed under Known issues.
- **Controls a screen reader and a thumb can use** (`test/app/accessibility_guidelines_test.dart`, added after the owner's "yes move forward"): Flutter's Android accessibility guidelines run on each main screen in the light and the dark theme, 12 walks: every control at least 48 by 48 dp, every control with a name, text standing out from what is behind it. They found three controls too small to touch reliably: the preview card's close button (40 dp), the back and menu buttons over a World's cover (40 dp) and the editor's step buttons (43 dp). All three are fixed and look as they did. No control was without a name. The only contrast flag was the light-theme distance label on World details at 4.23:1, the value measured by hand in D-041; its colour is the owner's, so the test requires exactly that label to fall short and nothing else. This is the nearest thing to a TalkBack pass that can be done without a phone, and it is not one: it cannot tell whether the names make sense or are read in a sensible order.
- **Motion** (D-040, `lib/shared/components/motion.dart`, `Motion` in `lib/app/theme/app_tokens.dart`): the preview card rises into place; Explore messages fade and their space eases; the player turns parts forward, grows its progress bar and marks a correct answer and a finished World once; going live and a sent report are marked once; World details, Saved, Create, Profile and creator pages fade from loading into content; the unlock panel eases between answers; the save button fades between its two shapes. All of it takes its duration from one place and takes none when the device is set to remove animations; Flutter's own page transitions, ripples, sheets and dialogs are not covered and still play. The map, tab switches, page transitions and the editor's steps were deliberately left alone, and nothing loops.
- **What the app logs:** two lines, both to the phone's own log, both holding only the kind of error: startup failing (`lib/app/bootstrap.dart`) and the map failing to draw (`lib/core/maps/maplibre_map_adapter.dart`). No message text, account, World or position. Nothing is sent anywhere; the packages include no crash or analytics service. No global error handler was added.
- **Operations notes** in `supabase/README.md`, from the providers' pages on 2026-11-21: the Free plan pauses a quiet project after about a week, has no backups, and holds 500 MB on a 2 GB disk; OpenFreeMap is free with no stated limits and no promise of uptime, and no fallback map is configured. Also the queries for reading the pilot.

### Tests and results (2026-11-21, after all changes)
- `dart format --output=none --set-exit-if-changed .` — 181 files, 0 changed.
- `flutter analyze` — no issues.
- `flutter test --timeout 90s` — 337 of 337 passed (64 new: 9 for product events, 1 architecture rule, 26 at 200% text, 11 for motion, 5 for contrast, 12 accessibility guideline walks).
- `flutter test test_live/product_events_live_test.dart` — 1 of 1 (real backend).
- **Full live run:** `flutter test test_live`, 10:53 UTC — 4 of 4 against the real backend.
- `flutter test test_screens --update-goldens` — 12 of 12. Renders of the screens whose layout code changed were looked at and are as before at ordinary size: Explore with a selected World, details after "too far", the editor's content step (step names, the Incomplete chip), the finished World and the sent report; and, after the tap-target fixes, Explore with a selected World, locked details and the editor's first step again.
- `flutter build apk --debug --dart-define-from-file=.env` — passed. Permissions unchanged: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE and AndroidX's app-internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. No background location. Built again at `b8389c0`, after the tap-target fixes and the two colour changes.
- Database: six test files against the applied schema: 32, 36, 74, 52, 47 and 18 checks, as above.

### Acceptance criteria (docs/FEATURE_ACCEPTANCE_CRITERIA.md, section 9)
| Criterion | Status | Evidence |
| --- | --- | --- |
| Physical-device testing on low and mid-range Android and varied networks | Not done | No phone was attached |
| Permission denial, GPS accuracy, services off and stale readings tested | In widget tests only | Every case is covered with a fake location service, at ordinary and 200% text. Never on a phone |
| Map tile provider terms, attribution, volume and fallback rechecked | Rechecked; no fallback | `supabase/README.md`. The attribution shown is the text asked for. No second provider is configured |
| Supabase free-tier limits understood; backup and operational owner identified | Limits written down; no backup, no owner named | `supabase/README.md`. Both are owner decisions |
| Crash and error reporting reviewed for personal data and location | Reviewed | Two local log lines with the kind of error only; nothing leaves the phone. It also means crashes on testers' phones go unseen |
| Text scaling, TalkBack and contrast verified | Partly | 200% text in widget tests (no overflow); contrast measured, the dark-theme defect fixed, two light-theme labels corrected by the owner's choice, four smaller shortfalls recorded (D-041); tap-target size, control names and rendered text contrast checked on every main screen in both themes. TalkBack itself not listened to |
| 15 to 20 curated Worlds in one walkable pilot area | Not done | The area is undecided (D-021) |
| Testers complete the creator-to-explorer flow independently | Not done | No testers yet |
| Funnel measured: map, details, start, completion; first publish; second discovery; repeat creators | Can be measured; nothing measured | `private.pilot_funnel`, `pilot_summary`, `pilot_worlds`; tested in SQL and against the real backend. The only data is test launches |
| No critical crash, authorization flaw or unsafe seeded content | Not established | No device use and no seeded content. Database authorization is covered by 259 SQL checks |
| Product owner explicitly approves wider release | Not given | — |

### Manual device verification
**First device pass, 2026-11-21, on the owner's phone** (Realme RMX5110, Android 16, 360 by 797 dp, 7.6 GB RAM), after the owner approved Checkpoint 7 and attached it. A debug build was installed over the old one, keeping the owner's session; the agent drove it over USB (taps, typing, screenshots, the screen reader's view of each screen through `uiautomator`) and read the app's log. The owner was using the phone at times during the pass; every input was checked against the app in front first, and none was sent while another app was.

What was seen working on the phone:
- **Start and accounts:** the app opens on Explore, signed in as the owner's account from before; the profile shows its real counts.
- **The live map:** OpenFreeMap tiles, labels and the attribution line draw, and the map moves.
- **Find Worlds near me:** one reading, the map centred on the phone, and the nearby search answered "No Worlds within 5 km here yet". Permission had been granted earlier, so the explanation and Android's prompt were not shown again.
- **Create:** the first-World screen, the five editor steps, the place picker's "Use my location" with the real map and pin, adding a Text and an Ending part, the Incomplete label, the publish step refusing an incomplete World ("Part 2: Fill in the empty fields") with a working Fix button, and "Everything needed is in place" once complete. Saving reached the server (the draft is in the database with its place and two parts).
- **200% text** (Android's font size at its largest, set and put back by the agent): every editor step, Explore, Saved and Profile. No overflow was logged; the step bar showed numbers with "Step 3 of 5: Place".
- **Dark theme** (set and put back): Create and Explore draw in the dark colours with the lighter category colours.
- **Screen reader view:** every control on the screens visited has a name, tabs say "Tab 1 of 4" and so on, fields are named by their hints.

Found on the phone and fixed in `f57b9d8`, each with a regression test at 360 by 797 dp (`test/features/world_creation/narrow_phone_test.dart`); the widget tests had used a 411 dp screen, which hid all four:
- "Use my location" sat on the place picker's map and covered the pin that marks the exact spot.
- At 200% text the place picker's map shrank to a strip too thin to see the pin.
- The description's hint was cut off with an ellipsis.
- A category badge next to the category's written name made the screen reader say the name twice ("Story / Story").
The first one was checked on the phone after the fix only in part: the fixed build was installed, but by the time the place step was opened the World had been published (below) and the screen showed its details instead.

**The test World was published without the agent pressing Publish.** The owner had agreed to one temporary World at the phone's position, to be deleted straight after unlocking it. The agent's attempt to tick "This place is public and safe to reach" was blocked by its permission system. The World "Device check" was nevertheless published at 11:46:49 UTC, in the same seconds as an agent tap meant for the editor's "3. Place" step, which cannot publish; the owner was also using the phone around then. Which of the two published it is not established. When asked, the owner chose to delete it personally; the agent stopped sending input. Its deletion is recorded below.

Not done on the phone: unlocking and playing a World on site; saving, reporting, a creator page; refusing or blocking location, location turned off; Android's "Remove animations"; a slow or missing connection; TalkBack spoken aloud; any frame-rate measurement (a debug build says nothing about smoothness, and no profile build was installed); the moderation runbook. The full list still to do is below.

What has to be done on a phone before any tester is invited, in one pass:

1. **Install and start** (Checkpoint 1): `flutter run --dart-define-from-file=.env`; the app opens on Explore, not on "This build is not configured".
2. **Accounts** (Checkpoint 2): register, sign out, sign in, close and reopen (still signed in), edit the profile. With email confirmation back on and custom SMTP, the confirmation email arrives.
3. **Explore** (Checkpoint 3): the map draws and its attribution shows; moving the map searches; a marker opens the card; the list shows the same Worlds. "Find Worlds near me": allow, refuse, block in Settings and return, and with the phone's location turned off.
4. **Create** (Checkpoint 4): all five steps; the place picker on the real map; the photo picker; publish; edit a published World; unpublish.
5. **Unlock and play** (Checkpoint 5), as a second account, at the place: too far away; indoors with a poor reading; unlocked on site; play to the end; leave the app in the middle and come back; play again.
6. **Saved, reports, profiles** (Checkpoint 6): save and remove; report a World; open a creator's page. Then run the moderation runbook once on a test World in the dashboard.
7. **This checkpoint:** Android's font size at its largest on every screen above; TalkBack through Explore, details and the player; the dark theme; "Remove animations" on and off; the motion watched for dropped frames in a profile build (`flutter run --profile` with the performance overlay) on the slowest phone available, above all the card rising over the live map; a slow connection and none; and afterwards `select * from private.pilot_funnel();` showing the session.

### Known issues
- Nothing in Checkpoints 5, 6 or 7 has run on a phone. Whether the new motion is smooth on a real device is not known: it was tested for behaviour (it happens, it ends, it disappears when animations are removed), not for frame rate.
- Anyone holding the app's public key can send product events. A flood can use up a day's 20,000 or inflate a day's launch counts, and a launch is not a person. The steps counted from other tables cannot be forged this way.
- No account is stored with an event, but a launch that unlocked a World can be matched to an account by time (D-039). The first description of D-039 claimed more than that and was corrected.
- Removing animations on the device stops the app's own animations only. Page transitions, button ripples, sheets and dialogs are drawn by Flutter and still move.
- Old events are cleared only when the app is in use; a pilot that stops leaves its last 90 days of events in place.
- Testers have not been told what is measured. A notice is needed before the pilot.
- No backups exist, the project pauses after a quiet week, no one is named to operate it, and there is no fallback map (see `supabase/README.md`).
- Crashes on testers' phones will not be reported to anyone.
- Large text: checked in widget tests with the test font. The editor's step names are shortened to numbers above 130%; other text that is cut short without overflowing would not have been caught.
- TalkBack has not been listened to. The guideline checks prove controls are large enough and named, not that the names and their order make sense. They are also not exhaustive on contrast: they did not flag Puzzle's name on a light card, which measures 4.2:1 by hand.
- A reading the phone hands back from its cache is not rejected by age. Each check asks for a new reading (`getCurrentPosition`), and whether Android ever answers that with an old one has to be seen on a device before a threshold is chosen.
- Contrast, light theme, measured by hand and not flagged by the automated walks: the "Published" label (4.2:1), the "Unpublished" label (4.1:1 on the canvas), the small note inside the amber "not there yet" panel (4.47:1), and the `outline` token as the only edge of an unselected category card. Not yet put to the owner (D-041).
- The marker of a selected World is drawn by the native map; no emphasis was added to it.
- The dry run before applying covered only the new test file; the five older files ran after applying.
- Open from earlier checkpoints: the moderation and privacy review of Checkpoint 6; the device checks of Checkpoints 4 and 5; the proposed unlock thresholds (D-033); `world_visits` timestamps against the privacy document; the pilot area (D-021); the application ID; custom SMTP and email confirmation; leaked-password protection; share links and unlisted Worlds; account deletion and retention periods.

### Approval status
The owner replied "yes move forward" to the Checkpoint 7 report on 2026-11-21. Taken as approval of the checkpoint and of the next step that report proposed: no new feature work, the device pass, then choosing the pilot area and seeding Worlds. It does not answer the five decisions the report listed (product events and what testers are told; the three colour values and the dark-theme change; backups and who operates the project; the unanswered Checkpoint 6 review; the pilot area, application ID and email set-up), and it is not approval of wider release. The pilot has not been run.

**Asked directly afterwards, the same day** (four questions, answered by choosing options):
- Pilot area: "Not decided yet". No default map centre and no seeding.
- A phone for the device pass: "Yes, connecting it now". See "Manual device verification" for what has and has not been checked since.
- The two proposed text colours: "Apply both". Done (D-041).
- What the pilot runs on: "Stay on Free for now". Recorded as an accepted risk (D-042).

## Update protocol
For each checkpoint record date, commit SHA, summary, tests and results, manual device verification, known issues and approval status. Never mark a checkpoint complete without evidence.


## Documentation and repository review — 2026-11-20

### New product-direction documents
- `docs/UI_UX_SPECIFICATION.md` — current screen behavior, proposed visual direction, navigation, accessibility, motion and screen-state requirements.
- `docs/USER_JOURNEYS.md` — anonymous discovery, location, identity, create/publish, unlock/play, save and report journeys.
- `docs/FEATURE_ACCEPTANCE_CRITERIA.md` — global definition of done and measurable acceptance criteria for Checkpoints 0–7.

The new docs were written against the merged implementation, not the original greenfield assumptions. The “living atlas / field journal” visual direction is explicitly a proposal and is not an owner-approved brand decision.

### Current repository review
Reviewed the latest `main` tree, recent commit history, Checkpoint 3 merge/PR, app feature tree, theme, app shell, Explore screen and messages, preview/list, Saved/Create/Profile screens, package manifest, test tree, Supabase migration tree and the latest Checkpoint 3 progress record.

Confirmed from repository evidence:
- Checkpoints 0–3 are merged into `main`; latest merge commit: `832babf7bbea33909efa4983c6a245ac1a0431cb`.
- Current stack includes Flutter/Dart, Riverpod 3, go_router, Supabase Flutter, MapLibre `maplibre_gl` 0.27.1 and geolocator 14.1.2.
- Existing implementation has auth/profile, Explore map/list, title search, category filters, nearby PostGIS RPC, selected marker preview, foreground one-shot location flow and explicit location explanation.
- The four-tab shell exists. Saved and Create remain honest placeholders for signed-in users; profile is implemented.
- Three SQL migrations exist for PostGIS, profiles and Worlds. Database test files exist for profiles and Worlds.
- Latest recorded Flutter suite: 138 passing tests; latest recorded analyzer: no issues; latest recorded debug APK build: passed. These are historical results from the checkpoint report, not a fresh execution in this review.

### Important gaps and risks found
1. **Real-device Explore verification remains open.** The app was installed/launched, but the actual screen was not successfully inspected. Map tiles, attribution placement, markers, camera gestures and the location flow are not visually verified.
2. **Checkpoint 1/2 device gates remain open.** Real Supabase sign-up/sign-in/session restore/profile edit/sign-out need device verification; owner security review is pending.
3. **Create and World details are not implemented.** The current Create tab is a placeholder. World preview is only a map summary; there is no complete details/editor/publish path.
4. **Player and persisted progress are not implemented.** The core MVP creator-to-explorer loop is not complete.
5. **Saved is not implemented for signed-in users.** The current tab intentionally states that it is not built.
6. **Brand/design system is not settled.** Theme seed `#1F6F5B` is explicitly a placeholder. Current Material 3 styling is functional baseline, not a polished final visual identity.
7. **Operational decisions remain.** Pilot area/default centre, final Android application ID, Supabase region/plan and email confirmation/SMTP setup remain unresolved. Map tile provider has no SLA.
8. **Nearby result pagination is not implemented.** The current request is capped at 50 results, so dense areas may omit farther Worlds.

### Immediate next actions (recommended order)
1. Owner performs/approves the pending physical-device and security checks recorded above.
2. Owner confirms the pilot area/default map centre and the open Checkpoint 4 decisions (including direct-link visibility for unlisted Worlds).
3. Owner approves Checkpoint 4.
4. Implement World details and the complete creator flow in small reviewable increments, using the new journeys and acceptance criteria. Do not start the player before a real published World can be created and fetched by a second account.
5. Before public pilot, complete the creator-to-explorer-to-completion loop, saved/reporting requirements, operations and beta gates.

**Review scope limitation:** this was a GitHub source/document review. No local checkout was available in this session, so no Flutter command was executed here and no physical device was controlled. The 138-test/analyzer/build results are reported from the repository's latest progress record only.
