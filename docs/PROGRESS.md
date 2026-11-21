# WORLDS — Implementation progress

**Phase:** MVP implementation  
**Current checkpoint:** 4 (World details and creator) in progress, approved by the owner on 2026-11-20  
**Product direction:** Approved  
**Documentation handoff:** Core product, journey, UX and acceptance specifications published to GitHub  
**App implementation:** Foundation, accounts and profiles, the Explore map, World details and the World creator. Playing Worlds is not built yet. The Checkpoint 4 database migration is applied to the development project and verified.

| Checkpoint | Status | Evidence |
|---|---|---|
| Documentation handoff | Complete | Product/technical docs plus `UI_UX_SPECIFICATION.md`, `USER_JOURNEYS.md`, `FEATURE_ACCEPTANCE_CRITERIA.md` |
| 0. Repository audit | Audit delivered. Owner answered D1 and D3 and asked for the scaffold; ten decisions remain open | `docs/REPOSITORY_AUDIT.md`, commit `f1b92f1`, 2026-11-19 |
| 1. Project foundation | Implemented; device test deferred by owner; continued to Checkpoint 2 at owner's request | See "Checkpoint 1 record" below |
| 2. Backend and identity | Implemented; device test and security review pending | See "Checkpoint 2 record" below |
| 3. Explore map | Implemented; real-device map check pending | See "Checkpoint 3 record" below |
| 4. World details and creator | Implemented (4A–4G); migration applied and tested; two-account API check passed; owner device check pending | See "Checkpoint 4 record" below |
| 5. Experience player | Not started | — |
| 6. Saved/profile/moderation | Not started | — |
| 7. Beta and pilot | Not started | — |

## Current blockers

- On-device: the app has been installed and launched on the owner's phone and runs without crashing, but its screen has not been seen. Sign-up through real Supabase Auth, sign-in, sign-out, session restore and the map are untested on a device.
- Email confirmation was turned off in the dashboard by the owner on 2026-11-20 for development, so new accounts are signed in at once and any address can register, including ones the user does not own. Before the pilot: set up custom SMTP and turn confirmation back on (see `supabase/README.md`).
- The Checkpoint 2 gate is a security review by the owner.
- The Checkpoint 2 security review has not been explicitly given.
- Checkpoint 3's map package and tile provider were adopted on recommendation when the owner said "continue" (D-016, D-017); the owner has not chosen them explicitly.
- The pilot area, and so the Explore default centre, is undecided (D-021).
- Data-changing SQL through the Supabase connection needs an approval prompt that this editor declines automatically, so schema changes are run by the owner in the Supabase SQL editor from prepared files (see `supabase/README.md`).
- Checkpoint 4 has not been checked on a phone by the owner: the creator, place picker, photo picker and details screen are unseen on a real screen.
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
- Unlisted Worlds (G1) and the play-account decision (D-022) remain open.
- The visual design is still the Material 3 baseline; the "living atlas" direction is not approved.

### Approval status
Pending the owner's device check and approval. The Checkpoint 4 gate (publish with account A, verify as account B) passed at the API level with the real backend.

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
