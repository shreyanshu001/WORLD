# Repository audit — Checkpoint 0

| | |
| --- | --- |
| Audit date | 2026-11-19 |
| Repository state audited | `main` at `d31f872`, working tree clean at start |
| Status | **Delivered — awaiting product-owner approval** |
| Application source changed | None. This checkpoint changed documentation and one tooling config file only. |

Every finding below cites its evidence as **(E*n*)**; the commands and URLs are listed in [Evidence log](#evidence-log). Anything that could not be verified is marked **Not verified**.

## Summary

1. **The project is greenfield.** The repository holds 14 documentation and config files and no Flutter project. The product owner confirmed on 2026-11-19 that nothing else exists. There is no architecture, backend or design system to keep or replace.
2. **The installed toolchain works but is one year old.** Flutter 3.38.3 / Dart 3.10.1 (released 2025-11-21) is installed; current stable is Flutter 3.50.0 / Dart 3.14.0 (released 2026-11-11). On the installed SDK, 11 of the 17 recommended packages resolve below their latest release.
3. **The full candidate stack is verified on the installed SDK.** In a throwaway project outside the repository, every candidate resolved together, code generation ran, static analysis was clean, tests passed and a debug APK built — the APK only after the JDK problem in finding 4 was worked around.
4. **A machine setting breaks the Android build, and a project-level fix is verified.** A user-level Gradle setting forces JDK 20. The MapLibre plugin compiles for Java 21, so `flutter build apk` fails with `invalid source release: 21`. Committing one file, `android/gradle/gradle-daemon-jvm.properties`, makes Gradle use the JDK 21 that is already installed, without touching the machine-wide setting.
5. **Map recommendation:** `maplibre_gl` behind the planned `MapAdapter`, with OpenFreeMap as the pilot tile source and a paid provider as a pre-approved fallback. The public OpenStreetMap tile server is rejected for production.
6. **Backend:** a Supabase project now exists but has not been inspected. No Supabase CLI, Docker or `psql` is installed locally, which constrains how migrations and RLS tests can run at Checkpoint 2.
7. **Documentation:** no conflict blocks work. Four gaps between the documents need a product decision before the checkpoint that implements them.
8. **Twelve decisions are open.** Six gate Checkpoint 1 (D1, D2, D3, D9, D11, D12); the rest are needed by later checkpoints. See [Decisions needed](#decisions-needed).

## Environment

There is no `android/` directory in the repository. Android Gradle Plugin, Gradle, Kotlin and SDK levels below are therefore **what `flutter create` generates on the installed SDK**, not existing project configuration.

| Item | Value | Evidence |
| --- | --- | --- |
| Flutter | 3.38.3, stable channel, framework `19074d12f7`, at `C:\fluttersdk\flutter` | E2 |
| Dart | 3.10.1 (stable) | E2 |
| Android Gradle Plugin | 8.11.1 (generated) | E5, E6 |
| Gradle | 8.14 (generated wrapper) | E5, E6 |
| Kotlin | Kotlin Gradle Plugin 2.2.20 (generated) | E5, E6 |
| Android minSdk | 24 (`flutter.minSdkVersion`) | E5, E10 |
| Android targetSdk | 36 (`flutter.targetSdkVersion`) | E5, E10 |
| Android compileSdk | 36 | E5, E10 |
| NDK | 28.2.13676358 (installed) | E3, E5 |
| Java source/target in generated app | 17 | E6 |
| JDK configured in Flutter | OpenJDK 21.0.7 (Android Studio JBR) via `flutter config jdk-dir` | E3, E4 |
| JDK that Gradle actually uses | **JDK 20**, forced by `org.gradle.java.home` in the user-level `gradle.properties` | E9, E19 |
| `java` on PATH | Oracle Java 20 | E3 |
| Android SDK | Platforms 33–36; build-tools up to 36.0.0; platform-tools 36.0.0; command-line tools present | E3 |
| Android licenses | **Not all accepted** (`flutter doctor` warning) | E3 |
| Test device | One physical arm64 device on Android 16 (API 36); emulator images for API 34–36 installed | E3 |
| Machine | Windows 11, 7.3 GB RAM, 81 GB free disk, Windows long paths disabled | E19 |
| Other tools present | Node 24.19.0, npm, git | E3 |
| Tools missing | Supabase CLI, Docker, `psql`, `gh`, `sdkmanager` on PATH | E3 |

### How current the Flutter SDK is

| Flutter | Dart | Released |
| --- | --- | --- |
| **3.38.3 (installed)** | 3.10.1 | 2025-11-21 |
| 3.38.10 (last patch of the installed line) | 3.10.9 | 2026-02-11 |
| 3.41.9 | 3.11.5 | 2026-04-30 |
| 3.44.9 | 3.12.2 | 2026-08-06 |
| 3.47.9 | 3.13.7 | 2026-10-29 |
| **3.50.0 (current stable)** | 3.14.0 | 2026-11-11 |

Source: E12. Four stable lines have shipped since the installed version.

The Android templates also moved. Flutter 3.47.9 generates AGP 9.1.0 / Gradle 9.3.1 / Kotlin 2.4.0, and Flutter 3.50.0 generates AGP 9.3.1 / Gradle 9.5.0 / Kotlin 2.4.20. Both keep compileSdk 36, targetSdk 36, minSdk 24 and NDK 28.2.13676358 (E13).

## Existing project

- **Repository structure:** `README.md`, `AGENTS.md`, `.gitignore`, `.env.example`, nine files in `docs/` and `supabase/README.md`. 15 commits, all documentation (E1).
- **Current architecture:** none — greenfield, confirmed by the product owner.
- **State management:** none.
- **Routing:** none.
- **Theme/design system:** none. No design files, tokens or mock-ups exist in the repository.
- **Reusable components:** none.

`docs/PROGRESS.md` previously said the audit "must be run against the actual local Flutter codebase". That premise was wrong and is corrected in this checkpoint.

### What `flutter create` does to this repository

Tested on a copy of the repository outside the working tree (E14):

- `flutter create .` fails: `"WORLD" is not a valid Dart package name`. The directory name forces an explicit `--project-name`.
- `flutter create --org <org> --project-name worlds --platforms android .` succeeds and **does not modify** `README.md`, `.gitignore`, `AGENTS.md` or `.env.example` (checksums identical before and after).
- It adds `pubspec.yaml`, `analysis_options.yaml`, `.metadata`, `lib/main.dart`, `test/widget_test.dart`, `android/` and IDE files (`.idea/`, `*.iml`, already ignored).
- The existing `.gitignore` lacks several entries from Flutter's template, including `/android/app/debug`, `/android/app/profile`, `/android/app/release`, `*.log`, `.history`, `migrate_working_dir/`, `app.*.symbols` and `app.*.map.json`. They should be merged in at Checkpoint 1.

## Backend

- **Supabase configured?** A Supabase project exists; its project reference is recorded in `.mcp.json`, added during this checkpoint at the owner's request. The repository is not linked to it: there is no `supabase/config.toml` and no `supabase/migrations/` directory (E1).
- **Auth state:** **Not verified.** The Supabase MCP connection needs an interactive sign-in that the owner must complete.
- **Existing migrations:** none in the repository. Whether the remote project already has schema objects is **not verified**.
- **Storage buckets:** **Not verified.**
- **PostGIS enabled, region, plan:** **Not verified.**
- **Environment/secrets handling:** `.env.example` holds two empty variables, `SUPABASE_URL` and `SUPABASE_ANON_KEY`. `.gitignore` excludes `.env` and `.env.*`. No `.env` file exists. A scan of the repository for JWTs, Supabase keys, private keys and passwords found nothing (E17). No secret values were read or copied during this audit.

Platform facts that affect the plan (E16, retrieved 2026-11-19):

- **API keys are changing.** Supabase states it "is deprecating the `anon` and `service_role` keys by the end of 2026" in favour of publishable keys (`sb_publishable_...`) and secret keys (`sb_secret_...`). `supabase_flutter` 2.18.3 accepts `publishableKey` and marks `anonKey` deprecated. The variable `SUPABASE_ANON_KEY` in `.env.example` should become `SUPABASE_PUBLISHABLE_KEY`.
- **Free plan limits:** 500 MB database, 1 GB file storage, 5 GB egress, 50 MB maximum upload, two active projects, and projects are **paused after one week of inactivity**. A pause during the pilot would take the app down.
- **Image transformations are not included in the Free plan** (Pro: 100 origin images, then $5 per 1,000). This bears on the pending thumbnail decision.

## Map and location

- **Existing map package:** none.
- **Permission implementation:** none.

### Candidate compatibility

Two MapLibre packages exist for Flutter. Both are published by `maplibre.org` and both are pre-1.0 (E11, E18).

| | `maplibre_gl` | `maplibre` |
| --- | --- | --- |
| Version usable on installed SDK | 0.27.1 (2026-09-10) | 0.3.5 (2026-04-11) |
| Latest version and its requirement | 0.28.0 — Flutter ≥ 3.44, Dart ≥ 3.12 | 0.4.0 — Flutter ≥ 3.47, Dart ≥ 3.13 |
| Downloads, last 30 days | 186,161 | 16,858 |
| Android engine | MapLibre Native 13.5.0, pinned | MapLibre Native `13.0.+`, a floating version |
| Android integration | Platform channel plugin | JNI/FFI bindings |
| Plugin minSdk / compileSdk | 21 / 36 | 21 / 35 |
| Java level required to build | **21** | 11 |
| Static analysis on installed SDK | Clean | Clean |
| Debug APK on installed SDK | **Builds with JDK 21; fails with JDK 20** | Builds with the machine's default JDK 20 |

**Recommendation: `maplibre_gl`.** It has roughly eleven times the usage, pins its native engine so builds are reproducible, matches the template's compileSdk, and documents PMTiles support. Because both packages are pre-1.0 and their APIs still move, the `MapAdapter` interface already required by the architecture is essential, not optional.

`flutter_map` is not recommended: it is not MapLibre, so choosing it would contradict a locked product decision.

### Location

`geolocator` 14.1.2 is the latest release and resolves on the installed SDK (E7). It handles permission requests itself, so `permission_handler` is not needed.

The merged manifest of the test APK was inspected (E10):

| Permission in the built APK | Added by |
| --- | --- |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | MapLibre Native Android SDK |
| `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` | MapLibre Native Android SDK |
| `INTERNET` | MapLibre Native Android SDK, and Flutter's debug manifest |

- **No `ACCESS_BACKGROUND_LOCATION` and no foreground-service permission is present.**
- The location permissions arrive through the map SDK even though the app manifest did not declare them. The app should still declare them explicitly so the request is intentional and reviewable.
- `geolocator_android` declares a service with `foregroundServiceType="location"`. It cannot run as a foreground service without a permission the app will not declare, but it should be removed from the merged manifest so that "foreground only" is enforced by configuration.
- Flutter's template puts `INTERNET` only in the debug and profile manifests. The main manifest must declare it or release builds cannot reach Supabase.

### Tile provider

Terms and pricing were read from the providers' own pages on 2026-11-19 (E15).

| Provider | Cost | Commercial use | Limits and guarantees | Caching and offline | Notes |
| --- | --- | --- | --- | --- | --- |
| OpenStreetMap public tiles | Free | Not forbidden, but "access may be withdrawn at any point" | "no SLA or guarantee"; may be "blocked without prior notice" | Cache per HTTP headers, "or at least 7 days"; prefetching and offline use are prohibited | Requires a distinct app User-Agent and visible attribution. Raster only. |
| OpenFreeMap public instance | Free | Allowed | "no limits on the number of map views or requests"; no API key; **no SLA** | Offline downloads allowed if each is "at most 3,000 tiles or 50 MB" | Vector styles for MapLibre; attribution added automatically by MapLibre; self-hosting supported; run by one operator and funded by donations. |
| Stadia Maps | Free: 200,000 credits/month. Starter: $20/month for 1,000,000 credits | **Not allowed on Free**; allowed from Starter | Free tier allows no extra usage | Tile-caching terms are not on the pricing page — **not verified** | One vector tile = one credit. |
| MapTiler | Free: 100,000 requests or 5,000 sessions/month. Flex: $30/month for 500,000 requests or 25,000 sessions | Free is described as for "testing, PoC, prototyping, personal, or non-commercial use" | On Free the service pauses when the quota is used | Not on the pricing page — **not verified** | Logo required on Free. Whether a MapLibre Native app is billed per request or per session is **not verified**. |
| Self-hosted Protomaps (PMTiles) | Hosting cost only | Data is ODbL; attribution required | Under our control | MapLibre Native: "PMTiles sources do not support offline pack downloads or caching" | We would host the tile archive, style, fonts and sprites. MapLibre Native on Android supports `pmtiles://` sources. |

The MVP excludes offline map downloads, so the caching terms matter only for normal on-device tile caching, which every option above permits or leaves to HTTP headers.

**Pilot cost estimate.** This is an estimate from assumptions, not a measurement: 100 testers × 15 map sessions a month × about 150 vector tiles per session ≈ 225,000 tile requests a month, so a plausible range is 100,000–300,000.

- OpenFreeMap: $0.
- Stadia Maps: the free tier does not permit commercial use, so $20/month.
- MapTiler: the free tier is likely exceeded if billed per request, so $30/month.

**Recommendation:**

1. **Pilot on the OpenFreeMap public instance.** It permits commercial use, needs no key and costs nothing.
2. **Inject the style URL through configuration** so that changing provider is a config change, not a code change.
3. **Pre-approve Stadia Maps Starter ($20/month) as the fallback**, because OpenFreeMap offers no SLA and depends on one operator.
4. **Reject the public OpenStreetMap tile server** for anything beyond a developer's own testing: it has no SLA and can block the app without notice.
5. **Revisit self-hosted PMTiles before any public launch.** A single pilot area is a small extract and would remove the third-party dependency.

Attribution visibility and real tile behaviour must be confirmed on a device at the Checkpoint 3 gate.

## Dependency compatibility

A throwaway Flutter project was created outside the repository and all candidates were added at once (E6–E8).

| Check on installed SDK (Flutter 3.38.3) | Result |
| --- | --- |
| Joint version resolution of all candidates | Passed |
| `build_runner` with Freezed, json_serializable and riverpod_generator | Passed; 84 s for two small files |
| `flutter analyze` | No issues, after adding `invalid_annotation_target: ignore` (needed for `@JsonKey` on Freezed constructor parameters) |
| `flutter test` (Freezed/JSON round trip, generated Riverpod providers) | 2 of 2 passed |
| `flutter build apk --debug`, machine default | **Failed**: `:maplibre_gl:compileDebugJavaWithJavac` — `invalid source release: 21` |
| Same build with Gradle pointed at JDK 21 on the command line | **Passed** |
| `flutter build apk --debug` with `GRADLE_OPTS` pointing at JDK 21 | **Passed** |
| `flutter build apk --debug`, machine default, plus `android/gradle/gradle-daemon-jvm.properties` containing `toolchainVersion=21` | **Passed** |
| Highest plugin minSdk | 24, equal to the template's minSdk |

### Versions

"Resolved" is the version the solver chose on the installed SDK, read from `pubspec.lock`. "Latest" is from pub.dev on 2026-11-19 (E7, E11).

| Package | Resolved on 3.38.3 | Published | Latest | Latest requires |
| --- | --- | --- | --- | --- |
| `flutter_riverpod` | 3.1.0 | 2025-12-26 | 3.5.0 | Dart ≥ 3.12 |
| `riverpod_annotation` | 4.0.0 | 2025-12-28 | 4.0.8 | Dart ≥ 3.12 |
| `riverpod_generator` (dev) | 4.0.0+1 | 2025-12-28 | 4.0.10 | Dart ≥ 3.12 |
| `riverpod_lint` (dev) | 3.1.0 | 2025-12-26 | 3.2.0 | Dart ≥ 3.13 |
| `freezed` (dev) | 3.2.3 | 2025-09-10 | 4.0.3 | Dart ≥ 3.13 |
| `freezed_annotation` | 3.1.0 | 2025-07-02 | 3.1.0 | — |
| `json_serializable` (dev) | 6.11.2 | 2025-11-20 | 6.15.2 | Dart ≥ 3.12 |
| `json_annotation` | 4.9.0 | 2024-04-24 | 4.12.0 | Dart ≥ 3.9 (held back by `json_serializable` 6.11.2) |
| `build_runner` (dev) | 2.15.1 | 2026-07-08 | 2.17.1 | Dart ≥ 3.11 |
| `go_router` | 17.5.0 | 2026-08-10 | 18.1.4 | Flutter ≥ 3.44 |
| `supabase_flutter` | 2.18.3 | 2026-10-12 | 2.18.3 | — |
| `maplibre_gl` | 0.27.1 | 2026-09-10 | 0.28.0 | Flutter ≥ 3.44 |
| `geolocator` | 14.1.2 | 2026-10-19 | 14.1.2 | — |
| `image_picker` | 1.2.3 | 2026-06-30 | 1.2.4 | Flutter ≥ 3.41 |
| `flutter_image_compress` | 2.5.1 | 2026-07-25 | 2.5.1 | — |
| `mocktail` (dev) | 1.0.5 | 2026-04-10 | 1.0.5 | — |
| `flutter_lints` (dev) | 6.0.0 | 2025-05-27 | 6.0.0 | — |

Eleven of these seventeen packages resolve below their latest release. For ten of them the latest release requires a newer SDK outright; `json_annotation` is held back by the older `json_serializable`.

Riverpod stops at 3.1.0 although 3.3.2 supports Dart 3.10. Two checks show why (E7):

- The solver's own explanation for `riverpod_lint`: Flutter 3.38.3 pins `meta` to 1.17.0, newer `analyzer` versions need `meta` ≥ 1.18, and newer `riverpod_lint` needs those newer analyzers.
- Removing `riverpod_lint` alone changes nothing. Removing `riverpod_generator` and `riverpod_annotation` as well lets `flutter_riverpod` resolve to 3.3.2.

So Riverpod's code generation is what holds Riverpod back on this SDK. `freezed` and `json_serializable` stay at the versions in the table either way.

## Risks

### SDK/package conflicts

- **The installed SDK is at the trailing edge of package support.** `go_router` 17.5.0 already requires exactly this SDK as its minimum, and the latest release of ten packages requires a newer one. Staying here means no further fixes for Riverpod, Freezed, go_router or the map plugin.
- **The alternative is unverified.** Flutter 3.47 and 3.50 move the Android template to AGP 9 and Gradle 9. Whether every plugin builds there was **not verified** on this machine.
- **The Flutter SDK is shared with other projects on this machine.** A global `flutter upgrade` would change the toolchain for all of them.

### Android build risks

- **JDK mismatch (would block Checkpoint 3 if left alone).** The user-level `gradle.properties` sets `org.gradle.java.home` to JDK 20. This overrides the JDK configured in Flutter: `gradlew --version` reports `Daemon JVM: ...\jdk-20 (from org.gradle.java.home)`. `maplibre_gl` targets Java 21, so the build fails (E9). Its changelog documents the requirement: "the Android build targets Java 21".
- **The fix should stay inside the project.** A `gradle-daemon-jvm.properties` file in the project takes precedence over the user-level setting and was verified to fix the build (E9). Changing the machine-wide setting instead has side effects: the Gradle cache shows other projects on this machine using Gradle wrappers older than 8.5, and Gradle's compatibility matrix lists 8.5 as the first release that can run on Java 21 (E20), so those projects could break.
- **That fix is verified on Gradle 8.14 only.** Whether it behaves the same on the Gradle 9 wrapper that newer Flutter versions generate is **not verified**.
- **Low memory.** The machine has 7.3 GB of RAM and Gradle is capped at 2 GB. The first test build ran for about five and a half minutes and a trivial code-generation run took 84 seconds. Slow feedback loops are likely.
- **Unaccepted Android SDK licenses** can stop Gradle from installing a missing SDK component mid-build.
- **`flutter config android-studio-dir` points at an incomplete Android Studio install.** Builds work because `jdk-dir` is set separately, but `flutter doctor` cannot detect the Studio version (E9).
- **Windows long paths are disabled.** The repository path is short, so this is unlikely to bite, but deeply nested build output can exceed 260 characters.
- **One test device.** A single Android 16 device cannot cover the low and mid-range matrix that Checkpoint 7 requires, nor minSdk 24 behaviour.
- **Release signing.** Flutter's template signs release builds with the debug key. A real keystore is needed before any distribution.

### Architectural conflicts

None with existing code, because there is none. Two constraints follow from the findings:

- Both MapLibre packages are pre-1.0, so no map SDK type may leak outside `core/maps`.
- Riverpod code generation holds Riverpod at 3.1.0 on the installed SDK. If the project stays on Flutter 3.38.3, hand-written providers would allow 3.3.2 (verified by resolution only, E7).

### Security gaps

- **`.mcp.json` grants broad access.** The Supabase MCP URL enables database, functions, branching and account tools without `read_only=true`. An agent signed in through it could change the schema directly, which would breach the rule that every schema change is a committed migration. Supabase documents the parameter as "Execute all queries as a read-only Postgres user" (E16). Recommended: add `read_only=true` now, and after Checkpoint 2 begins, write the migration file first and apply only that.
- **Legacy key naming.** `.env.example` names the legacy anon key that Supabase is deprecating.
- **No automated guard on permissions.** Nothing yet fails a build if a dependency update introduces background location.
- **Admin role mechanism is undefined.** `DATABASE.md` requires that the admin role "comes from trusted process" but does not say which. This must be settled before the moderation checkpoint.
- **Free-plan pausing** would make the pilot backend unavailable after a quiet week.

## Documentation consistency

`AGENTS.md` requires stopping if the documents conflict. No conflict blocks Checkpoint 1. These gaps need a decision before the checkpoint that implements them:

| # | Gap | Documents | Needed by |
| --- | --- | --- | --- |
| G1 | Unlisted Worlds must be "accessible by direct link", but the RLS contract allows public read of published **and public** Worlds only. Unlisted Worlds would be unreadable. | `PRODUCT_SPEC.md` §4, `DATABASE.md` RLS | Checkpoint 4 |
| G2 | MVP scope includes "title search", but `get_nearby_worlds` has no search parameter. | `PRODUCT_SPEC.md` §3 and §8, `DATABASE.md` | Checkpoint 3 |
| G3 | Explorers may use the map "without mandatory account", but progress, visits and saves are keyed by user ID. The point at which sign-in becomes mandatory is not stated. It also means the nearby RPC must be callable by the anonymous role. | `PRODUCT_SPEC.md` §6, `DATABASE.md` | Checkpoint 3 |
| G4 | "Compress and thumbnail" is required, but the thumbnail method is undecided and Supabase image transformations are a paid feature. | `TECHNICAL_ARCHITECTURE.md`, `DECISIONS.md` | Checkpoint 4 |

`docs/PROGRESS.md` assumed an existing Flutter codebase; corrected in this checkpoint.

## Recommendation

- **Keep:** all locked product decisions; the documented feature-first structure; the `MapAdapter` and `LocationService` interfaces; SQL-first backend with committed migrations.
- **Replace:** `SUPABASE_ANON_KEY` with `SUPABASE_PUBLISHABLE_KEY` in `.env.example`. No machine-wide setting needs replacing.
- **Add:**
  - A per-project Flutter SDK pin (decision D1).
  - `android/gradle/gradle-daemon-jvm.properties` with `toolchainVersion=21`, which overrides the JDK 20 setting for this project only (decision D2).
  - `maplibre_gl` and `geolocator` at Checkpoint 3; `image_picker` and `flutter_image_compress` at Checkpoint 4.
  - `MAP_STYLE_URL` as a configuration value.
  - Configuration through `--dart-define-from-file=.env`, which the installed SDK supports and which reads the existing `.env` format, so no dotenv package is needed (E8).
  - A check that fails if the merged Android manifest contains background-location or foreground-service-location permissions.
  - `read_only=true` on the Supabase MCP URL until Checkpoint 2.
- **Defer:**
  - `maplibre` (the newer package) — revisit after it reaches 1.0.
  - `permission_handler` — not needed; `geolocator` covers it.
  - Analytics and crash-reporting vendor — Checkpoint 7.
  - Self-hosted tiles — before public launch.
  - iOS, deep links, offline maps.

### Recommended dependency versions

The right set depends on decision D1.

- **If the project stays on Flutter 3.38.3:** use the "Resolved on 3.38.3" column above. That exact set is verified on this machine.
- **If the project pins a newer Flutter (recommended):** use the "Latest" column as the target, then re-run the same spike (resolve, generate, analyze, test, build) as the first step of Checkpoint 1 and record the resulting `pubspec.lock` versions. That set is **not verified** today.

Either way, use caret constraints in `pubspec.yaml` and commit `pubspec.lock`.

## Decisions needed

| # | Decision | Recommendation | Needed by |
| --- | --- | --- | --- |
| D1 | **Flutter SDK strategy.** (a) Stay on 3.38.3. (b) Pin a newer SDK for this project only. (c) Upgrade the shared SDK. | **(b)**, pinned to current stable 3.50.x, falling back to 3.47.9 if the Checkpoint 1 spike fails. The pin needs a version manager such as FVM or a second SDK directory; FVM is not installed here and was not tested. (a) is the only option verified today but leaves eleven packages below their latest release. (c) changes every other project on the machine. | Checkpoint 1 |
| D2 | **Gradle JDK.** The user-level setting forces JDK 20; the map plugin needs 21. (a) Commit a project file that pins Gradle to Java 21. (b) Change the machine-wide setting. (c) Set `GRADLE_OPTS` in every shell. | **(a)**. It is verified, is committed with the project and leaves other projects alone. It relies on a JDK 21 being installed on the building machine, which is the case here. (b) risks breaking older projects on this machine. (c) works but is easy to forget. | Checkpoint 1 |
| D3 | **Application ID and organisation**, e.g. `com.<your-domain>.worlds`. It is permanent once published. Dart package name would be `worlds`. | Owner to supply. | Checkpoint 1 |
| D4 | **Map package.** | `maplibre_gl`. | Checkpoint 3 |
| D5 | **Tile provider for development and pilot.** | OpenFreeMap, with Stadia Maps Starter pre-approved as fallback. | Checkpoint 3 |
| D6 | **Supabase project.** Confirm that the project referenced in `.mcp.json` is the WORLDS development project, and its region and plan. | Confirm; plan to move to Pro for the pilot to avoid pausing. | Checkpoint 2 |
| D7 | **Migration and test workflow.** No Docker or CLI is installed, and 7.3 GB of RAM makes a local Supabase stack doubtful. | Use the remote project for development, apply only committed migration files, and run RLS tests against it with two test accounts. Whether the Supabase CLI runs here through `npx` is **not verified**. | Checkpoint 2 |
| D8 | **Supabase MCP access level.** | Add `read_only=true` until Checkpoint 2. | Now |
| D9 | **Rename `SUPABASE_ANON_KEY` to `SUPABASE_PUBLISHABLE_KEY`.** | Yes. | Checkpoint 1 |
| D10 | **Documentation gaps G1–G4.** | Decide each before its checkpoint. G3 is the most urgent because it shapes the Checkpoint 3 RPC grants. | Checkpoints 3 and 4 |
| D11 | **Generated code** (`*.g.dart`, `*.freezed.dart`): commit or ignore. | Commit, so a fresh clone builds without an 84-second generation step and without CI. | Checkpoint 1 |
| D12 | **Accept Android SDK licenses** (`flutter doctor --android-licenses`). | Owner to run; it is interactive. | Checkpoint 1 |

Decisions already listed as pending in `DECISIONS.md` (image thumbnails, username policy, Supabase region) remain pending.

### Owner decisions recorded after delivery

On 2026-11-19 the product owner answered two of these, and both are logged in `docs/DECISIONS.md`:

- **D1:** start on the installed Flutter 3.38.3 (option a), not the recommended per-project pin. The "Resolved on 3.38.3" versions therefore apply.
- **D3:** use the placeholder `com.example.worlds` for now. A real application ID is required before any release build.

The other ten decisions remain open.

## Proposed sequence

Each checkpoint ends with format, analyze, tests, a progress update and a stop for approval, as `AGENTS.md` requires.

### Before Checkpoint 1 — environment (owner-approved actions only)

1. Apply decision D1. If a per-project pin is chosen: install FVM, pin the version, commit the pin file.
2. Accept Android licenses (D12).
3. Complete the Supabase MCP sign-in from a regular terminal.

### Checkpoint 1 — App foundation

1. Run `flutter create --org <org> --project-name worlds --platforms android .` — verified not to overwrite existing files.
2. Merge the missing Flutter template entries into `.gitignore`.
3. Repeat the compatibility spike inside the real project: resolve, generate, analyze, test, build a debug APK.
4. Dependencies: `flutter_riverpod`, `riverpod_annotation`, `freezed_annotation`, `json_annotation`, `go_router`, `supabase_flutter`. Dev: `build_runner`, `freezed`, `json_serializable`, `riverpod_generator`, `riverpod_lint`, `mocktail`, `flutter_lints`. No map, location or media packages yet.
5. `analysis_options.yaml`: `flutter_lints`, `invalid_annotation_target: ignore`, generated files excluded.
6. Files:
   - `lib/main.dart` — bootstrap and Supabase initialisation with the publishable key.
   - `lib/app/app.dart`, `lib/app/router/app_router.dart` (shell route with Explore, Saved, Create, Profile), `lib/app/theme/app_theme.dart`, `lib/app/config/env.dart`.
   - `lib/core/errors/app_failure.dart` — the typed error model from the architecture document.
   - `lib/core/network/supabase_provider.dart`.
   - `lib/core/widgets/` — loading, empty and error views with retry.
   - `lib/features/{explore,saved,world_creation,profile}/presentation/` — placeholder screens.
7. Android: application ID, app label, `INTERNET` in the main manifest, and `android/gradle/gradle-daemon-jvm.properties` pinning Java 21 (decision D2).
8. `.env.example`: publishable-key rename and `MAP_STYLE_URL`.
9. Tests: shell navigation widget test, shared-state widget tests, configuration unit test including the missing-configuration case.

### Checkpoint 2 — Backend and identity

1. Confirm the project, region and PostGIS; link the repository.
2. Migrations in `supabase/migrations/`: extensions (PostGIS), `profiles` with RLS, profile bootstrap trigger, username rules.
3. RLS tests in `supabase/tests/`: owner can update own profile; user A cannot update user B; public read exposes approved fields only.
4. `lib/features/auth/` — `domain` (repository interface, user model), `data` (Supabase implementation), `application` (session and auth controllers), `presentation` (sign-in, register).
5. `lib/features/profile/` — same four layers; read and edit own profile.
6. Router redirect on auth state; session restore.

### Checkpoint 3 — Explore map

1. Add `maplibre_gl` and `geolocator`.
2. `lib/core/maps/` — `map_adapter.dart` (interface), SDK-free map types, `maplibre_map_adapter.dart`, map widget.
3. `lib/core/location/` — `location_service.dart` (interface), `geolocator_location_service.dart`, permission status type.
4. Android manifest: declare fine and coarse location explicitly; remove the geolocator foreground service; add the merged-manifest permission check.
5. Migrations: `worlds` with GIST index and RLS; `get_nearby_worlds` RPC with clamping and grants per decision G3; development seed data.
6. `lib/features/explore/` — four layers: preview model, repository, controller with debounced queries and category filter, map screen, preview sheet, accessible list view, all required states.
7. Tests: SQL tests for the RPC (published and public only, distance ordering, clamping); controller and widget tests.
8. Gate: real-device check of rendering, attribution and tile behaviour.

### Checkpoint 4 — Details and creator

1. Add `image_picker` and `flutter_image_compress`.
2. Migrations: `world_assets`, `world_content_blocks`, `world_question_secrets`, storage bucket and policies, publish and unpublish RPCs with server-side validation.
3. `lib/shared/models/` — versioned content-block union.
4. `lib/features/worlds/` (details) and `lib/features/world_creation/` (draft, metadata, location picker reusing `MapAdapter`, block editor, preview, publish).
5. Tests: publish validation SQL tests; ownership tests with two accounts.

### Checkpoint 5 — Experience player

1. Migrations: `world_visits`, `world_progress`; RPCs for start with proximity check, block transition, answer submission with rate limit, idempotent completion.
2. `lib/features/world_player/` — four layers; block renderer, branching, question UI, resume.
3. Tests: answer never present in public payloads; invalid transitions rejected; completion idempotent.

### Checkpoint 6 — Saved, profile and moderation

1. Migrations: `saved_worlds`, `world_reports`, the admin mechanism, rate limits, hide and unpublish.
2. `lib/features/saved/`, public profile in `lib/features/profile/`, `lib/features/moderation/`.

### Checkpoint 7 — Beta and pilot

Device matrix, release keystore and signing, privacy-reviewed crash and analytics vendor decision, seeded pilot content, tile-provider review against real usage.

## Evidence log

Nothing here was run inside the repository except E1 and E17. Spike projects lived in a temporary directory outside the working tree.

| ID | Command or source |
| --- | --- |
| E1 | `git status`, `git log --oneline`, `git ls-files`, `git remote -v` |
| E2 | `flutter --version --machine`, `dart --version` |
| E3 | `flutter doctor -v`, `java -version`, `adb version`, directory listing of the Android SDK |
| E4 | `flutter config --list` |
| E5 | Installed Flutter SDK source: `packages/flutter_tools/lib/src/android/gradle_utils.dart`, `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt` and `DependencyVersionChecker.kt` |
| E6 | `flutter create --org dev.worlds.spike --project-name worlds_spike --platforms android`, then the generated `android/settings.gradle.kts`, `gradle-wrapper.properties` and `app/build.gradle.kts` |
| E7 | `flutter pub add` of all candidates; `pubspec.lock`; `flutter pub deps`; `flutter pub outdated`; `flutter pub upgrade`; `flutter pub add flutter_riverpod:^3.3.2 --dry-run` for the solver explanation; `flutter pub remove riverpod_lint`, then also `riverpod_generator` and `riverpod_annotation`, each followed by `flutter pub upgrade` |
| E8 | `dart run build_runner build --delete-conflicting-outputs`; `flutter analyze`; `flutter test`; `flutter run -h` for `--dart-define-from-file` |
| E9 | `flutter build apk --debug -v` (failed; log shows `jvmCriteria=...jdk-20 (from org.gradle.java.home)`); `gradlew assembleDebug -Dorg.gradle.java.home=<JDK 21>` (succeeded); `flutter build apk --debug` with `GRADLE_OPTS` set to the same value (succeeded); `flutter build apk --debug` with `gradle-daemon-jvm.properties` and no other change (succeeded); `gradlew --version` in each configuration; `maplibre_gl` 0.27.1 `android/build.gradle` and `CHANGELOG.md` |
| E10 | `aapt2 dump permissions` and `aapt2 dump badging` on the built APK; `manifest-merger-debug-report.txt`; plugin `android/build.gradle` files for minSdk |
| E11 | `https://pub.dev/api/packages/<name>` and `https://pub.dev/api/packages/<name>/score`, retrieved 2026-11-19 |
| E12 | `https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json`, retrieved 2026-11-19 |
| E13 | `gradle_utils.dart` at Flutter tags `3.47.9` and `3.50.0` on `raw.githubusercontent.com/flutter/flutter` |
| E14 | Copy of the repository in a temporary directory; `flutter create` with and without `--project-name`; `md5sum` before and after |
| E15 | `https://operations.osmfoundation.org/policies/tiles/`, `https://openfreemap.org/`, `https://stadiamaps.com/pricing/`, `https://www.maptiler.com/cloud/pricing/`, `https://docs.protomaps.com/basemaps/downloads`, `https://maplibre.org/maplibre-native/android/examples/data/PMTiles/`, retrieved 2026-11-19 |
| E16 | `https://supabase.com/docs/guides/api/api-keys`, `https://supabase.com/pricing`, `https://supabase.com/docs/guides/getting-started/mcp`, retrieved 2026-11-19; `supabase_flutter` 2.18.3 `lib/src/supabase.dart` |
| E17 | `grep` across the repository for JWT, Supabase key, private-key and password patterns: no matches |
| E18 | Second spike: `flutter pub add maplibre geolocator`; `flutter analyze`; `flutter build apk --debug`; `maplibre_android` 0.3.5 `android/build.gradle` |
| E19 | User-level `gradle.properties` (JDK path and memory settings only); `Win32_ComputerSystem` for RAM; registry `LongPathsEnabled`; free disk space |
| E20 | Gradle Java compatibility table, `https://docs.gradle.org/current/userguide/compatibility.html`, retrieved 2026-11-19: Java 21 is supported for running Gradle from 8.5 |

## Approval

- **Audit complete:** Yes — 2026-11-19, with the items marked **Not verified** outstanding.
- **Product owner approved:** Pending.
