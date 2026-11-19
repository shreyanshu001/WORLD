# Dependency selection checklist

Do not copy package versions from stale examples. Verify current stable releases against installed Flutter/Dart and Android toolchain.

| Capability | Candidate | Verification |
|---|---|---|
| State | Riverpod 3 | SDK compatibility and provider style |
| Models | Freezed | build_runner compatibility |
| JSON | json_serializable | generator compatibility |
| Routing | go_router | Flutter SDK constraints |
| Backend | supabase_flutter | auth persistence/API compatibility |
| Maps | MapLibre Flutter | maintenance, Android support, SDK constraints |
| Location | geolocator | target SDK and permission behavior |
| Media | image compression package | Android support and output size |

## Map provider gate
Read provider terms; confirm attribution, rate limits, caching, commercial use and expected pilot costs. Public OSM tile endpoint is not assumed to be a free production CDN.

## Acceptance
Commit selected versions only after Checkpoint 0. Record rejected options and rationale in this document.

## Checkpoint 0 findings — proposed, pending product-owner approval

Recorded 2026-11-19. Nothing below is selected until the product owner approves it. Evidence, commands and sources are in `docs/REPOSITORY_AUDIT.md`.

### What was checked

Installed toolchain: Flutter 3.38.3 / Dart 3.10.1. Current stable is Flutter 3.50.0 / Dart 3.14.0. All candidates were added together to a throwaway project outside the repository.

| Capability | Proposed package | Resolved on Flutter 3.38.3 | Latest on pub.dev | Verified | Not yet verified |
| --- | --- | --- | --- | --- | --- |
| State | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint` | 3.1.0, 4.0.0, 4.0.0+1, 3.1.0 | 3.5.0, 4.0.8, 4.0.10, 3.2.0 | Resolution, code generation, analysis, unit test | Behaviour on a newer SDK |
| Models | `freezed`, `freezed_annotation` | 3.2.3, 3.1.0 | 4.0.3, 3.1.0 | `build_runner` run, JSON round-trip test | Freezed 4 migration |
| JSON | `json_serializable`, `json_annotation` | 6.11.2, 4.9.0 | 6.15.2, 4.12.0 | Generator runs alongside Freezed | — |
| Code generation | `build_runner` | 2.15.1 | 2.17.1 | All three generators in one run | — |
| Routing | `go_router` | 17.5.0 | 18.1.4 | Resolution, debug build | Shell-route behaviour |
| Backend | `supabase_flutter` | 2.18.3 | 2.18.3 | Resolution, debug build, `publishableKey` parameter present | Auth persistence at runtime |
| Maps | `maplibre_gl` | 0.27.1 | 0.28.0 | Analysis; debug build on JDK 21; merged permissions | Rendering and attribution on a device |
| Location | `geolocator` | 14.1.2 | 14.1.2 | Debug build at targetSdk 36; no background permission merged | Runtime permission behaviour |
| Media | `image_picker`, `flutter_image_compress` | 1.2.3, 2.5.1 | 1.2.4, 2.5.1 | Debug build | Output size and quality |
| Tests | `mocktail` | 1.0.5 | 1.0.5 | Resolution | — |
| Lints | `flutter_lints` | 6.0.0 | 6.0.0 | Analysis clean | — |

### Version policy (decision D1 in the audit)

**Decided 2026-11-19:** the product owner chose to start on the installed Flutter 3.38.3 (`docs/DECISIONS.md`, D-008). The "Resolved" column therefore applies; that exact set is verified. The packages themselves are still proposals until approved, and none has been added to `pubspec.yaml` yet.

If the project later moves to a newer Flutter, target the "Latest" column, repeat the spike before changing anything else, and record the resulting `pubspec.lock` versions here.

### Build requirement

`maplibre_gl` 0.27.1 compiles for Java 21. This machine's user-level Gradle setting forces JDK 20, which fails the build. Proposed fix: commit `android/gradle/gradle-daemon-jvm.properties` containing `toolchainVersion=21`. Verified on Gradle 8.14.

### Rejected or deferred options

| Option | Outcome | Rationale |
| --- | --- | --- |
| `maplibre` (the newer MapLibre package) | Deferred | Builds, but has about one eleventh of the usage of `maplibre_gl`, is at 0.3.5 on the installed SDK, and depends on a floating MapLibre Native version (`13.0.+`), which makes builds non-reproducible. Revisit after 1.0. |
| `flutter_map` | Rejected | Not MapLibre; choosing it would contradict a locked product decision. |
| `permission_handler` | Rejected | `geolocator` already requests and reports location permission; a second permission package adds surface without need. |
| `flutter_dotenv`, `envied` | Rejected | `--dart-define-from-file=.env` is built into the installed SDK and reads the existing `.env` format, so no package and no bundled asset is needed. |
| `very_good_analysis` | Deferred | Latest release needs Dart 3.13. `flutter_lints` 6.0.0 is current and sufficient to start. |
| Global `flutter upgrade` | Rejected | The SDK is shared with other projects on this machine. Pin per project instead. |

### Map provider gate — result

Terms were read on 2026-11-19; see the audit for quotations and the cost estimate.

| Provider | Outcome | Rationale |
| --- | --- | --- |
| OpenFreeMap public instance | **Proposed for development and pilot** | Commercial use allowed, no key, no request limit, attribution added by MapLibre. No SLA. |
| Stadia Maps Starter ($20/month) | **Proposed as fallback** | Commercial use allowed from this tier; 1,000,000 credits a month covers the pilot estimate. |
| MapTiler Flex ($30/month) | Alternative fallback | Free tier is described as non-commercial and pauses at quota. |
| Self-hosted Protomaps (PMTiles) | Deferred to before public launch | Removes the third-party dependency but adds hosting work. |
| Public OpenStreetMap tile server | **Rejected for production** | No SLA; access can be blocked without notice; offline use prohibited. |
