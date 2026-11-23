# Phase 0 — Current-state audit and shared-anchor proof-of-concept plan

**Date:** 2026-11-23
**Phase:** 0 of `docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md` (repository truth and handoff reconciliation)
**Status:** Delivered for owner review. Not approved. Phase 1 has not started.
**Scope kept:** documentation only. No app code, dependencies, migrations, AR code or live data changed.

---

## 1. Baseline

| Item | Value |
|---|---|
| `main` | `a03209e` (merge of PR #10) |
| Handoff | Only on `origin/docs/shared-ar-product-direction-handoff` (`8516512`, `510e276`, `bb0050c` on top of `a03209e`). **Not on `main`.** |
| Newer record not on `main` | `f26bb8e` on `checkpoint-7-pilot-readiness` ("Device check" still published; re-run 341/341). Pushed to its branch, not merged. |
| This work | Local branch `phase-0-shared-ar-audit` = handoff branch + `f26bb8e` cherry-picked (clean) + this audit. Not pushed. |
| Working tree before work | Clean |
| Toolchain | Flutter 3.38.3 / Dart 3.10.1 (D-008), AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, JDK 21 toolchain, Java/Kotlin target 17, `minSdk`/`targetSdk` from Flutter (24 / 36 per earlier APK inspection), application ID placeholder `com.example.worlds` (D-009) |
| Native Android code | `MainActivity : FlutterActivity()` only. No platform channels, no PlatformViews of our own. |

### Fresh results (2026-11-23, at `f26bb8e`; its code is identical to `main`, it differs only in `README.md` and `docs/PROGRESS.md`)

| Command | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 182 files, 0 changed |
| `flutter analyze` | No issues |
| `flutter test --timeout 90s` | 341 of 341 passed (1 min 31 s) |
| `flutter build apk --debug --dart-define-from-file=.env` | Built `build/app/outputs/flutter-apk/app-debug.apk` |

Not re-run, deliberately:
- `flutter test test_live` — publishes and soft-deletes `[e2e]` Worlds and files a report on the live development project; handoff rule 13 forbids publishing live content without explicit authorization.
- `flutter test test_screens --update-goldens` — rewrites image files; without the flag it is not a test (PROGRESS, Checkpoint 5).
- The six SQL test files — they run through the write-capable Supabase connection; not needed for a documentation phase.
- APK permission list — not re-inspected; last recorded at `b8389c0`.

### Live development database (read-only queries, 2026-11-23)

- Applied migrations: the same seven as `supabase/migrations/` (`20261119190312` … `20261121081022`). No drift.
- Tables: 9 in `public`, 4 in `private`; RLS enabled on all 13.
- Policies: 10 table policies (all `SELECT` except the profile `UPDATE`) and 3 on `storage.objects` (`world-media` insert/select/delete).
- API functions (`public`): 20, all `security definer` except `get_nearby_worlds` (invoker).
- Storage: one private bucket `world-media`, 5 MB, `image/jpeg`, `image/png`, `image/webp`.
- Worlds: 2 published, 25 soft-deleted.
- **"Device check" is still `published` and `public`**, `updated_at` 2026-11-21 11:46:49 UTC — unchanged. (Coordinates deliberately not queried.)

---

## 2. What is implemented on `main` (answers Q1)

Evidence is code, migrations and tests. "Device" means seen on a physical phone.

| Area | Implemented | Tested | On a device |
|---|---|---|---|
| Startup, config, 4-tab shell, theme tokens (D-031), motion (D-040) | Yes | Widget | Launch, tabs, dark theme, 200% text seen (2026-11-21) |
| Email/password auth, profiles, edit | Yes (`features/auth`, `features/profile`) | Widget + 32 SQL checks | Existing session only; sign-up/in/out not on a device |
| Explore: MapLibre map, PostGIS nearby RPC, search, filters, list, preview | Yes (`features/explore`, `core/maps`) | Widget + SQL | Map, tiles, attribution, one nearby search |
| World details | Yes (`features/worlds`) | Widget + live | Partly |
| Creator: 5-step editor, place picker, images, blocks, publish/unpublish/delete | Yes (`features/world_creation`, `save_world`, `publish_world`…) | Widget + 74 SQL + live | Editor steps, place picker; photo picker/edit-published/unpublish not |
| Unlock (server distance check) and player (story/puzzle/art/experience blocks) | Yes (`features/world_player`, `unlock_world`, `get_world_play`, `advance_world`, `answer_question`, `restart_world`) | Widget + 52 SQL + live | Only the creator's own unobserved unlock of "Device check" |
| Saved, reports, creator pages, profile counts | Yes (`features/saved`, `features/moderation`, `get_profile_page`) | Widget + 47 SQL + live | Saved/Profile screens only |
| Moderation | Dashboard-only SQL functions (D-036) | SQL (rolled back) | Never run for real |
| Product events | 4 events via `log_event` (D-039) | 18 SQL + live | — |
| Anything AR, camera, 3D, scene, anchor | **No code, no schema, no dependency, no doc beyond the handoff** | — | — |

Partially implemented / only documented: share links and unlisted Worlds (D-038, G1), account deletion and retention, custom SMTP/email confirmation, crash reporting, fallback map, pilot area (D-021), final application ID (D-009).

---

## 3. What can be reused for shared AR (answers Q2)

| Existing piece | Reuse for AR | Change it would need later (not now) |
|---|---|---|
| `public.worlds` (id, creator, category, `geography(point)`, unlock radius, status, visibility) | The canonical World an optional scene attaches to; publication and moderation state | None to the table itself; a scene table references it |
| `unlock_world` + `world_visits` | The "close enough to enter" gate before camera entry (handoff §4.1) | See conflict C6 below |
| `world_progress` (per user, server-validated) | Explorer progress (AR-007) | Needs a scene version reference and interaction state |
| `world_assets` + `world-media` bucket + `register_world_asset` (owner path, MIME/size check, signed URLs, unlocked-reader policy) | The pattern for scene assets (AR-016) | New MIME (`model/gltf-binary`), larger size limit, hash; probably a separate bucket |
| `world_content_blocks` + allowlisted block types + server validation | The model for an allowlisted interaction set (AR-006) and "no scripts" rule | — |
| `private.world_question_secrets` | Puzzle secrets stay server-side if AR interactions include answers | — |
| Moderation functions (`hide_world` etc.) and `moderation_actions` | Hiding a World hides its scene too | Scene-level audit rows |
| `get_world_details` | Details screen; add "has camera experience" | One more field |
| `MapAdapter` / `LocationService` / `ImagePickerService` interfaces + `test/architecture/import_boundaries_test.dart` | Same pattern for an `ArSession` interface with the SDK confined to one folder | New boundary rule |
| `AppFailure` typed errors, loading/empty/error views, `LocationExplanationDialog` | AR failure states and permission education (AR-001, AR-009) | New failure kinds |
| Routes `/play/:id`, `leave_guard`, details CTA | Camera entry from an eligible World (AR-002) | One route |
| `Motion` tokens with reduced-motion, accessibility and large-text tests | AR overlay UI outside the native view | — |
| `test_live` harness (two labelled accounts) | Account A publishes / account B resolves (Phase 3) | — |

---

## 4. Existing contracts that collide with AR

Each needs an explicit owner-approved change in a later phase; none is changed now.

- **C1 Camera permission.** `test/architecture/android_manifest_test.dart` asserts "needs no photo, storage or camera permission". AR needs `CAMERA`.
- **C2 Location model.** D-021 and `LocationService` allow one reading per tap. An ARCore Geospatial session uses fine location continuously while the session is in the foreground. Still foreground-only (no background permission), but "one-shot only" no longer holds. `SECURITY_AND_PRIVACY.md` says "stream only while visible and explicitly needed", which fits if bounded to the camera screen.
- **C3 Data leaving the device.** Geospatial/VPS sends camera-derived visual data and location to Google for localization. The privacy docs have no such third party today (only the tile provider, D-017). Needs owner acceptance and a disclosure.
- **C4 Assets.** `world_assets` and `world-media` accept only JPEG/PNG/WebP ≤ 5 MB. GLB is excluded.
- **C5 Versioning.** `save_world` edits a published World in place (D-027). The handoff requires immutable scene versions; progress has no version column.
- **C6 Unlock persistence.** D-033: once unlocked, a World stays unlocked anywhere. Camera entry needs a fresh on-site check or the AR gate itself, otherwise users can open the camera kilometres away.
- **C7 Dependency/SDK age.** Flutter 3.38.3 (D-008) with Kotlin 2.2.20/AGP 8.11.1. An AR renderer's Kotlin/AGP/minSdk needs are unverified against this.
- **C8 Application ID.** ARCore keyless auth binds to package name + signing SHA-1; the app's ID is still `com.example.worlds`.

---

## 5. Stale or contradictory documentation (answers Q3)

Reconciled on this branch with dated notes; no historical record deleted.

| Where | Statement | Reality | Action on this branch |
|---|---|---|---|
| `AGENTS.md` "Current task" (still on the handoff branch) | Review before Checkpoint 4; "do not start … until the owner approves Checkpoint 4" | Checkpoints 0–7 merged; Phase 0 is the task | Replaced with the Phase 0/Phase 1 gate |
| Handoff §2.3 | 337 tests, 181 files | 341 tests, 182 files (re-run at `93aafa4` and again today) | Dated correction note |
| Handoff §2.4 | "Device check" deletion "not verified" | Verified 2026-11-23: still published and public | Dated correction note |
| Handoff §2.5 | `PROGRESS.md`/README say Checkpoint 7 is on its branch | Already fixed in `f26bb8e`, which was not on `main` | Brought in by cherry-pick |
| Handoff §6 | `disposeSession)` | Typo | Left (owner's text); noted here |
| `README.md` | "does not require AR"; table "AR — Out of MVP" | Superseded by the handoff | Dated note |
| `docs/PRODUCT_SPEC.md` §1, §3 | "not initially an AR platform"; AR/3D/spatial anchors excluded | Superseded for the next phase | Dated note |
| `docs/TECHNICAL_ARCHITECTURE.md` | No native AR module, no camera | Handoff §6 adds a Flutter/native boundary | Dated note |
| `docs/DECISIONS.md` D-004 | "No AR in MVP" | Superseded by the owner's direction | D-004 marked superseded; D-043 added |
| `docs/USER_JOURNEYS.md` header and Journey E step 7 | Account requirement for play "remains a product decision (D-022)" | Settled by D-032 (account needed); D-022 unused | Dated note |
| `docs/UI_UX_SPECIFICATION.md` header, §3, §5.2–5.4, §8 | Visual direction "proposed"; details "next"; player/editor "future" | D-031 adopted the direction (values open); details, editor and player exist | Dated note |
| `docs/FEATURE_ACCEPTANCE_CRITERIA.md` §2 | Checkpoints 4–7 "not started" | Labelled "at document creation"; historical | Pointer to PROGRESS added |
| DB comment on `world_content_blocks` | "Readable by its creator only until the player exists" | The player exists; still creator-only by design (D-024) | Not changed (needs a migration); noted |

---

## 6. Phase 1 plan — two-device shared-anchor proof of concept

### 6.1 What "shared" means with Geospatial anchors

A Geospatial anchor is **not hosted** by Google. There is no anchor ID to share. Each device creates a local anchor from the same stored pose (latitude, longitude, altitude or terrain/rooftop offset, orientation quaternion), and "the same place" is only as good as each device's own VPS localization. So the PoC must measure:

1. how far each device's rendered object lands from a physical ground-truth mark; and
2. how far the two devices land from each other.

That makes the server's stored pose (Phase 3) the "shared anchor identity" for AR-003. Persistent Cloud Anchors work differently (hosted, with a TTL, and visual scanning by the creator). Under the handoff they are only a comparison, evaluated only if Geospatial fails the use case.

### 6.2 Candidates and what decides (answers Q5)

**Anchor provider: ARCore Geospatial API (`com.google.ar:core`) — the only provider in the first PoC.**
- Variable inside it: Terrain anchor (altitude relative to terrain) as the primary candidate for ground-level scenes; WGS84 (absolute altitude) as the comparison. Rooftop anchors only if a site needs them.
- Decides: localization success rate and time; reported horizontal and yaw accuracy; measured offset to the mark per device and between devices; repeatability across sessions and days; behaviour on tracking loss.
- Fallback trigger: if VPS is unavailable at every candidate site, or measured offsets are too large for any useful scene scale, propose a Cloud Anchors comparison to the owner. Do not build it unasked.

**Renderer, in order:**
1. **SceneView `arsceneview`** (Filament + ARCore, Kotlin, Apache-2.0). Its GitHub README shows 4.31.0, while Maven Central and the docs site show older versions; the current version is unverified. Check before use: release cadence; access to the underlying ARCore `Session`/`Earth`; GLB/PBR loading; lifecycle; 16 KB page-size alignment; minSdk, Kotlin and AGP needs against the app's toolchain (C7); APK size.
2. **Fallback:** Google's official Geospatial sample (its own GL renderer) plus Filament `gltfio` for the GLB. More code, fewer unknown layers.
3. **Watch, do not adopt:** Jetpack XR ARCore (`androidx.xr.arcore`, 1.0.0-rc02, 2026-10-07) has Geospatial pieces, but is aimed at Android XR. Its phone support is unverified.
4. **Not candidates:** Flutter AR plugins, including the old `flutter_sceneview` bridge (handoff §6). The PoC is native-only.

Renderer evidence: GLB loads with PBR; frame time; memory; scene-load time; lifecycle (background/foreground, screen off, permission revoked) with no camera leak; build compatibility with AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 / JDK 21.

### 6.3 Requirements (answers Q4)

**Devices**
- **At least 2 ARCore-certified phones that support Geospatial, from different makers.** For example, one mid-range Samsung (Galaxy A35 5G / A55 5G) and one Pixel (7a / 8a / 9a). All are on Google's list with "Supports Depth API".
- The owner's phone (realme RMX5110 = **realme P4 5G**) is **not on Google's ARCore supported-devices list**, checked 2026-11-23 (the P4 Pro, P4 Power and P4s are). A realme support statement says the same, reported secondhand. It must be confirmed on the phone (`ArCoreApk.checkAvailability`, or whether Play offers "Google Play Services for AR"). If confirmed, it is still useful as the **unsupported-device** test for AR-001/AR-009, but it cannot be one of the two devices.
- So **no qualifying device is known to be available today.**
- Each device: "Google Play Services for AR" installed and current, mobile data, battery ≥ 80% at start, USB debugging for logs.

**Location**
- A public, lawful, safe outdoor spot with no traffic. Ideally a candidate for the undecided pilot area (D-021).
- It must have VPS coverage. **Unknown until surveyed.** The first PoC step calls `Session.checkVpsAvailabilityAsync` for 3–5 candidate sites the owner proposes.
- A fixed, unambiguous physical mark (e.g. a paving-slab corner, a bollard base) with a clear facing direction; a tape measure; optional photos for heading reference.
- Visits at two different times or days (e.g. midday and late afternoon) for repeatability.

**Credentials and accounts**
- A Google Cloud project owned by the owner with the **ARCore API** enabled.
- **Keyless authorization (recommended by Google):** an Android OAuth client per spike package name + signing-certificate SHA-1. Debug keystores differ per machine, so use one dedicated spike keystore, never committed, or register each SHA-1.
- API-key auth exists but Google says it is less secure; avoid it.
- Quota: 1,000 sessions/min or 100,000 requests/min per project (Google page, updated 2026-04-28). **Pricing is not verified.** Confirm in the Cloud console before enabling billing, if billing is needed at all.
- No Supabase credentials are needed for Phase 1 (see 6.4). No secrets in the repository.

### 6.4 The smallest demo that proves shared placement (answers Q6)

A standalone native Android (Kotlin) spike app with its own application ID, e.g. `<owner-domain>.worlds.spike`. It is not wired into the Flutter app, so no Flutter code, tests or manifest contracts change.

1. **Survey:** check VPS availability at the candidate sites; pick one.
2. **Author (device A, on site):** localize until accuracy passes the gate. Place the object's base pivot on the physical mark, facing the chosen direction. Save the pose as a small JSON file (`lat`, `lng`, `altitude`/terrain offset, quaternion, anchor type, device, accuracy at capture).
3. **Hand-over without the backend:** move the JSON to device B out of band (Quick Share or `adb push`). Devices share no session, cloud call or memory.
   - Optional: a second pose typed from map coordinates of the same mark, with no on-site capture. Its measured error is the evidence for the open on-site vs remote placement decision.
4. **Resolve (device B, cold start):** localize, resolve the anchor, render the same GLB. Repeat with roles swapped.
5. **Measure** per device, per session:
   - time to localize and to resolve;
   - reported horizontal, vertical and yaw accuracy;
   - tape-measured offset of the base pivot from the mark, and heading error;
   - A-vs-B offset in side-by-side photos;
   - behaviour after the camera is covered for 5 s (hide, re-show, drift?);
   - frame time, memory, battery drop over 10 min, Android thermal status.
   - Minimum: 5 sessions per device per visit, 2 visits.
6. **Quality gate (AR-004):** the object stays hidden until reported accuracy is under a threshold. Start from Google's sample values and tune from data. When quality degrades, hide the object and show a "localizing" state; never let it drift silently.
7. **Asset:** one optimized, licensed GLB (owner picks the art direction or the source), plus a clearly labelled DEBUG measurement pin at the pivot.
8. **Deliverable:** a decision record with device matrix, tables of measurements (median and worst case, no invented thresholds), screen recordings and photos, selected anchor type and renderer, the realme result, and a recommended creator placement workflow.

**Pass:** two different certified devices independently resolve the same stored pose and show the same object at the same mark, with measured error recorded and failure states honest. One device, or a shared session, does not pass.

Explicitly not in the PoC: Flutter integration, Supabase tables, creator UI, multiple objects, interactions beyond a debug tap, iOS, Cloud Anchors.

### 6.5 Risks and owner decisions blocking Phase 1 (answers Q7)

**Blocking:**
1. **Devices:** two ARCore Geospatial-capable phones (see 6.3). The realme P4 5G appears unsupported.
2. **Google Cloud project** with the ARCore API, and the owner's choice of spike application ID and keystore handling.
3. **Test site candidates** (and whether they double as the pilot area, D-021).
4. **Privacy acceptance (C3):** VPS sends visual and location data to Google during the PoC. Testers are the owner and team only.
5. **Where the spike lives:** recommended `spikes/shared-anchor-poc/` on its own branch, never merged to `main` without approval. The alternative is a separate repository.
6. **Asset:** which licensed GLB and which style (cinematic or stylized) for the first object.

**Not blocking Phase 1, but open:**
- **"Device check" is still public at the owner's phone position from 2026-11-21** (privacy). Authorize the agent to unpublish it through the app's own `unpublish_world` as its creator, or delete it yourself.
- Creator placement workflow (on-site / remote / both). Phase 1 produces the evidence; recommendation stays on-site first.
- Final application ID (D-009, C8). Changing it later means a new OAuth client, so it is cheap for the spike and needed before Phase 2.
- Whether to move off Flutter 3.38.3 if the chosen renderer needs a newer Kotlin/AGP (C7, D-008).
- Unanswered earlier gates still on record: Checkpoint 6 moderation/privacy review, D-034 to D-039, D-041 remainder, D-042 operator, email confirmation/SMTP.

**Technical risks:**
- VPS coverage may be absent or weak at the chosen site.
- Geospatial accuracy may be several metres, which limits scene design to landmark scale.
- Terrain altitude at a site may be wrong.
- Renderer and ARCore version coupling.
- Thermal and battery cost on mid-range phones.
- Free-plan Supabase storage and egress for GLB delivery (Phase 3; unverified).

### 6.6 Sources checked 2026-11-23

- ARCore supported devices: https://developers.google.com/ar/devices
- Geospatial API usage quota: https://developers.google.com/ar/develop/java/geospatial/api-usage-quota
- ARCore authorization (keyless / API key): https://developers.google.com/ar/develop/authorization?platform=android
- ARCore what's new: https://developers.google.com/ar/whatsnew-arcore
- Jetpack XR ARCore releases: https://developer.android.com/jetpack/androidx/releases/xr-arcore
- SceneView: https://github.com/sceneview/sceneview and https://central.sonatype.com/artifact/io.github.sceneview/arsceneview
- realme P4 5G ARCore status (secondhand): https://www.change.org/p/demand-realme-to-enable-arcore-support-on-realme-p4-5g-rmx5110
