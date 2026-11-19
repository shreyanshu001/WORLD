# WORLDS — Implementation progress

**Phase:** Identity  
**Current checkpoint:** 2 — Backend and identity (implemented; awaiting device verification and security review)  
**Product direction:** Approved  
**Documentation handoff:** Published to GitHub  
**App implementation:** Foundation plus email/password accounts and profiles backed by Supabase; no World features yet

| Checkpoint | Status | Evidence |
|---|---|---|
| Documentation handoff | Complete | README, AGENTS.md and 12 supporting files committed to main |
| 0. Repository audit | Audit delivered. Owner answered D1 and D3 and asked for the scaffold; ten decisions remain open | `docs/REPOSITORY_AUDIT.md`, commit `f1b92f1`, 2026-11-19 |
| 1. Project foundation | Implemented; device test deferred by owner; continued to Checkpoint 2 at owner's request | See "Checkpoint 1 record" below |
| 2. Backend and identity | Implemented; device test and security review pending | See "Checkpoint 2 record" below |
| 3. Explore map | Not started | — |
| 4. World details and creator | Not started | — |
| 5. Experience player | Not started | — |
| 6. Saved/profile/moderation | Not started | — |
| 7. Beta and pilot | Not started | — |

## Current blockers

- On-device verification of Checkpoints 1 and 2 is deferred by the owner. Sign-up through real Supabase Auth, sign-in, sign-out and session restore have not been exercised on a device.
- Sign-up with email confirmation on (Supabase's default) only works for project team members' addresses until custom SMTP is set up. For development, turn off *Confirm email* in the dashboard (see `supabase/README.md`).
- The Checkpoint 2 gate is a security review by the owner.
- Checkpoint 3 needs product-owner approval to start, plus decisions D4 (map package), D5 (tile provider) and gap G3 (how far signed-out users can go) from `docs/REPOSITORY_AUDIT.md`.
- The application ID is the placeholder `com.example.worlds`. It must be replaced before any release build.
- Supabase region, plan and Auth settings are unverified (Postgres 17.12 is verified).

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
- **Branch:** `checkpoint-1-app-foundation` (local only, not pushed). Commit: recorded in the commit that follows this entry.
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
- **Branch:** `checkpoint-2-backend-identity` (local only, not pushed). Commit: the commit that adds this entry.
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
  - `flutter test --timeout 60s` — 99 of 99 passed. These caught two bugs, both fixed: pages opened with `push` were not left after sign-in, because go_router's redirect only sees the page underneath; and a test awaited a fake timer outside the test clock.
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

## Update protocol
For each checkpoint record date, commit SHA, summary, tests and results, manual device verification, known issues and approval status. Never mark a checkpoint complete without evidence.
