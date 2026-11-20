# WORLDS — Implementation progress

**Phase:** Discovery  
**Current checkpoint:** 3 — Explore map (implemented; real-device map verification is its gate)  
**Product direction:** Approved  
**Documentation handoff:** Published to GitHub  
**App implementation:** Foundation, email/password accounts and profiles, and the Explore map of nearby published Worlds; no World creation or playing yet

| Checkpoint | Status | Evidence |
|---|---|---|
| Documentation handoff | Complete | README, AGENTS.md and 12 supporting files committed to main |
| 0. Repository audit | Audit delivered. Owner answered D1 and D3 and asked for the scaffold; ten decisions remain open | `docs/REPOSITORY_AUDIT.md`, commit `f1b92f1`, 2026-11-19 |
| 1. Project foundation | Implemented; device test deferred by owner; continued to Checkpoint 2 at owner's request | See "Checkpoint 1 record" below |
| 2. Backend and identity | Implemented; device test and security review pending | See "Checkpoint 2 record" below |
| 3. Explore map | Implemented; real-device map check pending | See "Checkpoint 3 record" below |
| 4. World details and creator | Not started | — |
| 5. Experience player | Not started | — |
| 6. Saved/profile/moderation | Not started | — |
| 7. Beta and pilot | Not started | — |

## Current blockers

- On-device: the app has been installed and launched on the owner's phone and runs without crashing, but its screen has not been seen. Sign-up through real Supabase Auth, sign-in, sign-out, session restore and the map are untested on a device.
- Sign-up with email confirmation on (Supabase's default) only works for project team members' addresses until custom SMTP is set up. For development, turn off *Confirm email* in the dashboard (see `supabase/README.md`).
- The Checkpoint 2 gate is a security review by the owner.
- The Checkpoint 2 security review has not been explicitly given.
- Checkpoint 3's map package and tile provider were adopted on recommendation when the owner said "continue" (D-016, D-017); the owner has not chosen them explicitly.
- The pilot area, and so the Explore default centre, is undecided (D-021).
- Checkpoint 4 needs product-owner approval to start, and gap G1 (unlisted Worlds by direct link) decided.
- The application ID is the placeholder `com.example.worlds`. It must be replaced before any release build.
- Supabase region and plan are unverified. Verified: Postgres 17.12; sign-up enabled; email confirmation **on** (`mailer_autoconfirm: false` from the public auth settings).

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

## Update protocol
For each checkpoint record date, commit SHA, summary, tests and results, manual device verification, known issues and approval status. Never mark a checkpoint complete without evidence.
