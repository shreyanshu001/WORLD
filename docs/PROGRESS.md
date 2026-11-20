# WORLDS — Implementation progress

**Phase:** Foundation  
**Current checkpoint:** 1 — App foundation (implemented; awaiting device verification and approval)  
**Product direction:** Approved  
**Documentation handoff:** Published to GitHub  
**App implementation:** Startup, configuration checks, theme, four-tab shell and shared state views; no product features

| Checkpoint | Status | Evidence |
|---|---|---|
| Documentation handoff | Complete | README, AGENTS.md and 12 supporting files committed to main |
| 0. Repository audit | Audit delivered. Owner answered D1 and D3 and asked for the scaffold; ten decisions remain open | `docs/REPOSITORY_AUDIT.md`, commit `f1b92f1`, 2026-11-19 |
| 1. Project foundation | Implemented; launch on a device not yet verified; awaiting approval | See "Checkpoint 1 record" below |
| 2. Backend and identity | Not started | — |
| 3. Explore map | Not started | — |
| 4. World details and creator | Not started | — |
| 5. Experience player | Not started | — |
| 6. Saved/profile/moderation | Not started | — |
| 7. Beta and pilot | Not started | — |

## Current blockers

- Checkpoint 1 acceptance requires the app to launch on Android. That is not yet verified because no device is connected.
- Checkpoint 2 needs product-owner approval to start.
- Six decisions from `docs/REPOSITORY_AUDIT.md` are still open: D4–D8 and D10. D12 (Android licenses) is an owner action. D2, D9 and D11 were adopted on recommendation at the start of Checkpoint 1 (`docs/DECISIONS.md`, D-010 to D-012).
- The application ID is the placeholder `com.example.worlds`. It must be replaced before any release build.
- The Supabase project has been inspected read-only and is empty: no tables, migrations, users, buckets or functions. PostGIS is available but not installed. Region, plan, Postgres version and Auth settings are still unverified.
- Map package and tile provider are recommended in the audit but not yet approved.

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

## Update protocol
For each checkpoint record date, commit SHA, summary, tests and results, manual device verification, known issues and approval status. Never mark a checkpoint complete without evidence.
