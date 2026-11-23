# WORLDS — Product Direction & Claude Code Handoff

**Status:** Owner-approved direction for the next product phase  
**Last reviewed against GitHub:** 2026-11-23  
**Repository:** `shreyanshu001/WORLD`  
**Baseline reviewed:** `main` at `a03209ebdfbb558a011966e31e218690413d174b`  
**Purpose:** This is the primary execution brief for Claude Code. Read it before making product, architecture, database, UI or implementation changes.

---

## 0. Read this first — authority and conflict rules

WORLDS has moved beyond its original map-and-content MVP direction. The owner has explicitly chosen to take the product toward **shared, camera-based, location-anchored 3D experiences**, with both realistic/cinematic and stylized visual treatments.

This document records that direction and governs the next phase.

The existing documents were written for the earlier MVP. They remain valuable for the working map, accounts, World creation, content, progress, moderation, privacy, accessibility and pilot foundations. However, statements in older documents that say AR is excluded, that AR is not part of the product, or that Checkpoint 4 is the next unimplemented feature are historical and are superseded for future planning by this handoff.

Do not silently rewrite history or delete old evidence. Reconcile contradictory current-state summaries in a dated, traceable way.

**Authority order for the next phase:**

1. Explicit product-owner decisions in this handoff and later owner messages.
2. This document for the shared-AR product direction and next-phase execution.
3. Existing approved product/UX/acceptance documents for behavior that this document does not replace.
4. Current code, migrations and tests as evidence of what actually exists.
5. Older progress summaries and plans as historical evidence, not automatic proof of current status.

If the code and documents disagree, inspect both, state the exact conflict and recommend a safe reconciliation. Do not guess.

### Owner decisions already made

- WORLDS should become a camera-based exploration experience, not just a map of text and image cards.
- The camera experience should support high-quality 3D graphics and real-world overlays.
- Both realistic/cinematic and stylized art directions should be supported.
- Spatial placement must be **shared**: different users visiting the same place should resolve the same authored scene at the same physical location. A per-device-only placement is not acceptable.
- The product and technical direction should be defined before broad implementation.

### Still-open owner decision

**Creator placement workflow:** choose whether creators initially place scenes on-site with the camera, remotely from a map, or through both. The recommended first release is on-site placement/calibration first, with remote placement deferred until accuracy is demonstrated. This is a recommendation, not an owner decision. Do not build both workflows or assume the final choice without recording approval.

---

## 1. Product destination

### 1.1 Product definition

**WORLDS is a map-discovered, camera-experienced platform for shared digital experiences anchored to real places.**

A creator builds a World and attaches a 3D scene or spatial experience to a real-world location. An explorer discovers that World on the map, visits the place, opens the camera, resolves the shared anchor and experiences the scene in the physical environment.

The map remains the discovery and navigation surface. The camera becomes the primary experience surface for AR-enabled Worlds.

This is not a generic camera filter app, a social feed, a game engine editor, or a collection of disconnected 3D demos. The location, authored scene, interaction and user progress must form one coherent product journey.

### 1.2 Core user promise

> Discover a World nearby. Go there. Open your camera. Experience something that exists in that place for everyone.

### 1.3 Core product loop

1. **Discover:** Explore map shows published Worlds and indicates which ones contain a camera/3D experience.
2. **Preview:** The explorer sees what the World is about, its creator, category, safety/accessibility information and whether AR is supported.
3. **Arrive:** The existing foreground location and unlock flow determines whether the explorer is close enough to start.
4. **Enter camera:** The user explicitly chooses to open the camera. Camera permission is requested in context.
5. **Localize:** The app checks AR capability, location quality and anchor availability, then resolves the World’s shared spatial anchor.
6. **Experience:** The same authored scene appears in the same physical place for different users. The explorer can look around, tap objects and complete supported interactions.
7. **Progress:** The backend records user-specific progress and completion. The shared scene itself is not modified by an explorer.
8. **Return/share:** The user returns to the map and can discover another World.

The product must always have an honest fallback. If AR is unavailable, localization fails, permissions are denied or tracking is poor, explain the issue and offer supported non-AR content where available. Never show a drifting or incorrectly positioned scene as if it were correctly anchored.

### 1.4 What a World becomes

A World continues to have its existing identity and content, but may additionally have a versioned spatial scene:

- World metadata: title, description, category, creator, cover, location, visibility and publication state.
- Existing structured content: story, puzzle, art or experience blocks.
- Optional spatial scene: one or more 3D assets, transforms, interaction definitions, visual style, anchor configuration and scene version.
- Explorer state: unlocked/started/completed state and interaction progress, scoped to the user.

Do not replace the existing World model with a completely new AR-only model. Extend it compatibly.

### 1.5 Visual direction

Support two art treatments through one scene/interaction system:

**Realistic / cinematic**
- Physically based materials and believable scale.
- Intentional lighting, shadows and atmospheric composition.
- Environmental storytelling and objects that feel situated in the real place.
- Restrained cinematic effects; effects must not obscure the environment, safety cues or interaction affordances.

**Stylized**
- Deliberate art direction, coherent silhouettes, color, materials and animation.
- Readable shapes and clear interaction states.
- Stylized lighting and effects that remain legible in outdoor daylight.

Both styles use the same scene manifest, anchor model, interaction contracts and progress APIs. Style is scene metadata and asset content, not a separate app architecture.

**Visual quality is a product requirement, not decoration.** Do not ship primitive cubes, placeholder models, flat debug materials or generic particle effects as the final experience. Temporary debug geometry is acceptable only in development and must be visibly identified as debug content.

---

## 2. Current project position — what exists today

The repository was reviewed against GitHub on 2026-11-23. The latest main commit visible during that review was:

`a03209ebdfbb558a011966e31e218690413d174b` — merge of PR #10, recording the first device pass.

### 2.1 Existing application foundation

The repository is an Android-first Flutter application with:

- Flutter/Dart app at the repository root.
- Riverpod-based state management, go_router navigation and the existing feature-first/layered architecture.
- Supabase Auth, PostgreSQL/PostGIS, Storage/RPC and committed SQL migrations.
- MapLibre-backed Explore map and foreground location flows.
- Existing World categories: Story, Puzzle, Art and Experience.
- Existing World metadata/content creation, publishing and player/progress flows.
- Saved Worlds, reporting, creator pages and profile counts.
- Product event/analytics groundwork, accessibility/text-scaling work, motion and operations documentation.

The current product is therefore not a blank canvas. Preserve the working map, account, creator, player and backend foundations unless an evidence-based reason requires a change.

### 2.2 Checkpoint history

The latest main history contains the merges for Checkpoints 6, 7 and the first device-pass record. The earlier progress text and README contain stale statements that Checkpoint 7 is still only on a branch and that Checkpoint 4 is next. Those statements do not match the reviewed merge history.

The current main baseline includes the work recorded for Checkpoints 0–7. This does **not** mean the pilot or all real-device acceptance gates are complete.

### 2.3 Verification evidence already recorded

The latest progress record reports the following results on 2026-11-21:

- Dart formatting: 181 files, no formatting changes required.
- `flutter analyze`: no issues.
- `flutter test --timeout 90s`: 337/337 passed.
- Live backend test suite: 4/4 passed.
- Screen golden tests: 12/12 passed.
- Debug APK build: passed.
- Six database test files: 259 SQL checks in total.
- A first manual device pass on a Realme RMX5110, Android 16, 360 × 797 dp.

These are **repository-recorded historical results**, not fresh test executions by the author of this handoff. Claude Code must rerun relevant commands on its actual checkout before relying on them.

> **Phase 0 correction, 2026-11-23:** a later record (`f26bb8e`, on `checkpoint-7-pilot-readiness`, not on `main` at the time of review) re-ran at `93aafa4`: 182 files, 0 changed; analyze clean; 341 of 341 (the 4 extra are the 360 dp regression tests). Phase 0 re-ran them again on 2026-11-23 with the same result and a passing debug APK build. See `docs/PHASE_0_AUDIT.md` §1.

### 2.4 What the first device pass did and did not prove

The recorded device pass confirmed that the app launched, the map rendered, the existing creator flow could save a draft, large text and dark theme were inspected, and screen-reader control names were inspected. Four narrow-phone issues were found and fixed in commit `f57b9d8`.

It did **not** complete the full creator-to-explorer journey. In particular, on-device unlocking and playing, permission denial, GPS edge cases, TalkBack spoken flow, slow/offline network behavior, profile-build frame-rate measurement and several Checkpoint 4–6 flows remain unverified.

The progress record also says a temporary test World named “Device check” was published without the agent pressing Publish. The owner chose to delete it personally, but the deletion was not verified by the agent against the live database. Treat this as an unresolved verification item until checked safely.

> **Phase 0 correction, 2026-11-23:** checked read-only against the live development database. "Device check" was **not** deleted: it is still `published` and `public`, unchanged since 11:46:49 UTC on 2026-11-21. It is an open owner decision in `docs/PHASE_0_AUDIT.md` §6.5.

### 2.5 Known documentation conflicts to reconcile

At the time of review:

- `AGENTS.md` still says AR is excluded, Checkpoint 4 is the next task and the current task is to review the pre-Checkpoint-4 implementation.
- `README.md` still says AR is out of MVP and that Checkpoint 7 is on its branch.
- `docs/PROGRESS.md` contains an older top-level status that says Checkpoint 7 is on its branch and main contains only Checkpoints 0–6, despite the later PR #9 and #10 merge history.
- `docs/PRODUCT_SPEC.md` and `docs/TECHNICAL_ARCHITECTURE.md` describe the original non-AR MVP.
- `docs/USER_JOURNEYS.md` contains an older unresolved account requirement for unlocking/playing, while later product decisions may have settled parts of that flow.

Claude Code must reconcile these contradictions with a dated addendum or focused edits. Do not erase the historical checkpoint records.

### 2.6 Current-state rule

Before implementing anything, inspect the actual checked-out `main` and report:

- Current branch and commit SHA.
- Git working-tree status.
- Actual feature folders, routes and existing World/scene-related models.
- Existing database tables, migrations, RLS policies, RPCs and storage buckets.
- Current package versions and Android Gradle/Kotlin/SDK configuration.
- Current test counts and fresh results.
- What is implemented, partially implemented, missing and only documented.

Do not infer implementation from a progress paragraph. Code, migrations and tests are the evidence.

---

## 3. Product requirements for shared AR

Use these IDs in implementation plans, PR descriptions and acceptance reports.

### P0 — required for the first shared-AR vertical slice

**AR-001 — AR capability check**  
Before entering the camera experience, check device support, Google Play Services for AR availability, camera permission and required location permission. Explain unsupported states and provide a fallback.

**AR-002 — Explicit camera entry**  
The camera opens only after a user action from an eligible World. Do not start camera capture in the background or merely because the map screen is visible.

**AR-003 — Shared anchor identity**  
A published World scene has one authoritative shared anchor configuration/identity. Every explorer resolves that same published anchor. Never create a separate permanent anchor per explorer.

**AR-004 — Anchor quality gate**  
Do not display precision-dependent scene content until localization/tracking meets a measured quality threshold. If quality degrades, hide, freeze or clearly degrade the scene rather than allowing it to drift.

**AR-005 — Scene rendering**  
Render at least one production-format 3D asset in the correct shared anchor frame, with stable scale and orientation. Debug geometry does not satisfy this requirement.

**AR-006 — Scene interaction**  
Support at least one allowlisted interaction, such as tapping an object to reveal a caption, play a supported animation or advance a story step. No arbitrary scripts.

**AR-007 — User-specific progress**  
Persist the explorer’s progress against the World and published scene version. One user’s progress must not mutate the shared scene or another user’s progress.

**AR-008 — Lifecycle safety**  
Camera and AR session must pause/resume/dispose correctly across app backgrounding, route changes, permission changes and system interruptions.

**AR-009 — Honest fallback**  
If camera, ARCore, location, network or anchor resolution is unavailable, show a useful explanation and the existing supported non-AR World experience when possible.

**AR-010 — Cross-device validation**  
At least two supported physical devices must resolve the same published scene at the same physical location. A one-device demo is not proof of shared AR.

### P1 — required before a public pilot

**AR-011 — Creator scene publishing**  
Creators can attach validated assets and scene metadata to a World, preview the scene and publish an immutable scene version.

**AR-012 — Anchor calibration and diagnostics**  
Creator/admin tooling can inspect anchor status, localization quality, placement metadata and failure reasons without exposing sensitive user traces.

**AR-013 — Scene updates and rollback**  
Editing a published scene creates a new version. Existing explorer sessions remain internally consistent; rollback/unpublish is possible.

**AR-014 — Multiple scene objects**  
A scene supports multiple nodes with stable transforms and deterministic ordering.

**AR-015 — Safety and accessibility**  
The experience warns users not to walk while looking through the camera, supports accessible non-AR descriptions/instructions, and avoids placing content where visitors must trespass or enter unsafe/restricted areas.

**AR-016 — Asset pipeline**  
Validate, optimize, store and deliver scene assets with predictable size, format, dimensions, ownership and cache behavior.

### P2 — later capabilities, not first-slice scope

- Multi-step spatial stories and puzzles.
- Multiple scenes/chapters within a World.
- More complex animation, audio, particles, occlusion and lighting effects.
- Remote creator placement.
- Collaborative creator workflows.
- Social reactions, leaderboards, monetization, AI-generated assets or AI scene authoring.

Do not pull P2 work into the first AR proof of concept.

---

## 4. Anchor and spatial architecture

### 4.1 The essential distinction

The existing GPS unlock radius answers: **“Is the explorer close enough to enter this World?”**

The AR anchor answers: **“Where exactly should this 3D scene appear in the physical environment?”**

These are different systems with different accuracy requirements. Passing the existing proximity check does not prove that an object can be positioned precisely.

### 4.2 Candidate anchor strategy

For outdoor public locations, evaluate **ARCore Geospatial Anchors** as the leading candidate because the experience is tied to a real geographic location and should be shared across users and visits.

Evaluate Persistent Cloud Anchors only for environments where local visual scanning/hosting is appropriate and where their lifecycle/expiry behavior is acceptable. They are not an automatic fallback for Geospatial Anchors; they have a different creation and resolution workflow.

Do not implement two anchor providers at once. First run a controlled proof of concept and record:

- Device compatibility and ARCore availability.
- VPS availability and localization quality at the proposed test locations.
- Horizontal/vertical/orientation stability across at least two devices.
- Resolution time and failure rate.
- Behavior in different lighting, weather and network conditions.
- Repeatability across separate visits/sessions.
- Anchor persistence and lifecycle constraints.
- Battery, thermal behavior and rendering performance.

**Do not promise centimetre-level or sub-metre placement until measured on target devices and locations.** Geospatial positioning can be several metres off in some conditions. That may be acceptable for a large landmark-scale scene and unacceptable for a small object that must sit on a specific bench or sculpture. Scene design must respect measured anchor accuracy.

### 4.3 Shared scene coordinate model

Use a two-level spatial model:

1. **World anchor:** geographic/shared reference resolved by the anchor provider.
2. **Scene-local transforms:** each object is positioned relative to that anchor.

Each scene node should define a local position in metres, rotation (quaternion), scale and optional parent relationship. Use one documented coordinate convention throughout the app and backend. Do not mix latitude/longitude offsets with local object transforms.

The published anchor is shared and server-managed. The camera pose, tracking state and temporary render state are device-local. Explorer progress is user-specific.

### 4.4 Anchor lifecycle

Represent anchor/session states explicitly, for example:

- `unsupported`
- `permission_required`
- `checking`
- `localizing`
- `resolving`
- `tracking`
- `degraded`
- `temporarily_unavailable`
- `expired` (only for providers with expiry)
- `failed`

UI must not equate “GPS says nearby” with “AR anchor is tracking”.

### 4.5 Scene versioning

Published scene versions must be immutable. A scene update creates a new version with a new manifest revision. Every progress record/session should refer to the version it started with. Unpublishing prevents new sessions; the product must define how an already-running session is handled.

---

## 5. Scene data model — proposed, not yet migrated

Claude Code must inspect existing migrations and World/content models before designing or creating tables. Reuse existing World IDs, ownership, publication and progress structures wherever they fit. Do not create duplicate user, World or progress tables.

The following is a logical model, not permission to copy it blindly into SQL.

### 5.1 Logical entities

- **World:** existing canonical World record.
- **WorldScene:** optional spatial experience attached to a World.
- **WorldSceneVersion:** immutable published manifest version.
- **WorldSceneAnchor:** shared anchor provider/type and geographic calibration metadata for a version.
- **WorldSceneAsset:** validated asset records and storage object keys.
- **WorldSceneNode:** object graph nodes, local transforms and asset references.
- **WorldSceneInteraction:** allowlisted interaction definitions.
- **WorldProgress / SceneProgress:** reuse the existing progress model where possible; add scene-version/interaction state only where needed.

### 5.2 Example manifest shape

This is illustrative JSON, not a finalized API contract:

```json
{
  "schema_version": 1,
  "world_id": "world-uuid",
  "scene_id": "scene-uuid",
  "scene_version": 1,
  "visual_style": "cinematic",
  "renderer": "android_native",
  "anchor": {
    "provider": "geospatial",
    "anchor_type": "wgs84",
    "latitude": 0.0,
    "longitude": 0.0,
    "altitude_mode": "terrain_or_configured",
    "altitude_offset_m": 0.0,
    "heading_degrees": 0.0
  },
  "assets": [
    {
      "asset_id": "asset-uuid",
      "storage_key": "worlds/world-uuid/scenes/scene-uuid/model.glb",
      "format": "glb",
      "sha256": "content-hash"
    }
  ],
  "nodes": [
    {
      "node_id": "node-uuid",
      "parent_id": null,
      "asset_id": "asset-uuid",
      "position_m": [0.0, 0.0, 0.0],
      "rotation_xyzw": [0.0, 0.0, 0.0, 1.0],
      "scale": [1.0, 1.0, 1.0],
      "interaction_id": "interaction-uuid"
    }
  ],
  "interactions": [
    {
      "interaction_id": "interaction-uuid",
      "type": "show_info",
      "payload": {
        "title": "A story begins here",
        "body": "Example content"
      }
    }
  ]
}
```

The actual schema must define numeric ranges, coordinate conventions, required/optional fields, maximum node counts, asset limits and compatibility rules. Validate on the server before publish and again when parsing on the client.

### 5.3 Backend and security rules

- RLS must protect every exposed table.
- Only the World owner (and trusted server-side moderator/admin roles) can modify drafts and publish scene versions.
- Explorers receive only published, authorized scene manifests and assets.
- Scene manifests contain no executable code, arbitrary scripts, unbounded HTML or arbitrary external URLs.
- Interactions are a finite allowlist implemented by the app.
- Puzzle answers/secrets remain server-side, following the existing product rule.
- Validate asset owner, World association, MIME type, file size, dimensions, format and content hash.
- Use storage object keys and controlled delivery, not arbitrary user-supplied URLs.
- Rate-limit anchor creation, scene publishing and expensive asset operations.
- Keep an audit trail for publish, update, unpublish and moderation.
- Do not store continuous user camera/location traces. Store only the minimum data needed for scene publishing, session progress and reliability metrics.
- Use migrations as the source of truth. No undocumented dashboard-only schema changes.

---

## 6. Mobile architecture — proposed boundary

The current app is Flutter. Preserve Flutter as the product shell and do not rewrite the app in native Android.

### Flutter owns

- App navigation and the existing four-tab shell.
- Explore map, search, World details and creator journeys.
- Auth, Supabase repositories and published scene manifest retrieval.
- Camera-entry explanation, permission education and fallback UI.
- User progress, completion and non-AR content.
- Creator-facing forms and scene publishing workflow.
- Accessibility semantics outside the native render surface.

### Native Android AR module owns

- ARCore session lifecycle and camera frames.
- ARCore capability and tracking state.
- Geospatial/VPS setup and anchor resolution.
- Native 3D rendering, scene graph and render loop.
- Hit testing and low-level spatial gestures.
- Camera/AR resource cleanup and Android-specific interruptions.

### Flutter/native boundary

Expose a small typed interface through a PlatformView plus MethodChannel/EventChannel (or another justified platform integration). The interface should express product-level operations and state, not stream every camera frame into Dart.

Candidate operations:

- `checkArAvailability`
- `checkGeospatialAvailability`
- `startSession`
- `resolvePublishedAnchor`
- `loadSceneManifest`
- `getTrackingState`
- `pauseSession`
- `resumeSession`
- `disposeSession)

Events may include tracking-state changes, anchor-state changes, node interaction, scene load failure and session diagnostics. Define typed request/response models and error codes.

The native renderer must not independently fetch privileged backend data. Flutter/backend layers retrieve the authorized manifest; native code receives validated scene data/assets needed for rendering.

### Rendering technology decision

Evaluate ARCore with a native Android renderer such as Filament, potentially using the current Android SceneView ecosystem as an integration candidate. Do not adopt a Flutter AR rendering plugin without checking its current maintenance, Flutter/Android compatibility, lifecycle behavior and ability to support the selected shared anchor provider.

The old `flutter_sceneview` bridge is not the default choice. Verify current maintenance and compatibility before selecting any package. Keep renderer selection provisional until the two-device proof of concept works.

Do not replace MapLibre. The map and AR renderer solve different jobs.

---

## 7. Graphics and asset-quality direction

The product promise requires intentional 3D art, not merely a working AR camera.

### Asset contract

- Prefer glTF 2.0 / GLB for runtime scene assets unless the spike proves a better supported format.
- Use physically based material definitions where supported.
- Keep object scale in real-world metres and validate it before publish.
- Provide optimized textures, meshes and sensible levels of detail.
- Use compressed texture/mesh delivery where the chosen renderer and target devices support it.
- Include thumbnails/previews so map and details screens do not need to load the full 3D asset.
- Store source/creator assets separately from optimized runtime assets if the pipeline needs both.
- Validate file type, dimensions, polygon/mesh complexity, texture sizes and total scene budget.
- Use stable asset IDs and content hashes for cache invalidation.
- Avoid downloading full scene assets until the user enters an eligible experience.

### Runtime visual quality

- Scene composition must look intentional from the expected approach direction and at realistic viewing distances.
- Scale, ground contact and orientation must be consistent.
- Avoid obvious floating, clipping, z-fighting and uncontrolled brightness.
- Use real-time shadows, occlusion and post-processing only when device support and measured performance allow them. Provide baked or simpler alternatives.
- Outdoor daylight readability is mandatory; tiny labels and low-contrast controls are not acceptable.
- Motion must be purposeful, short and interruptible. Do not add endless decorative animations.
- Provide reduced-motion behavior and accessible non-AR descriptions.
- Never let cinematic effects obscure the real environment or encourage unsafe movement.

### Performance

Do not invent a performance claim. Establish a target-device matrix and measure frame time, scene-load time, memory, battery and thermal behavior during the spike. Set explicit budgets from those measurements before adding complex effects or multiple assets.

The first vertical slice should contain one optimized, visually intentional asset and one interaction. It should prove stability before it proves visual complexity.

---

## 8. Creator and explorer workflows

### Explorer workflow — intended

1. Open Explore and discover a World.
2. Open details and understand the experience, AR requirement, distance and safety notes.
3. Reach the existing unlock eligibility.
4. Tap **Open camera / Enter World**.
5. Grant camera/location permissions when explained and needed.
6. Wait for anchor localization with clear status and recovery guidance.
7. See the shared scene appear in the physical location.
8. Tap an object and complete an interaction.
9. Save progress and return to the map.

### Creator workflow — to be finalized

The placement workflow remains an owner decision. Recommended first implementation:

- Creator visits the intended public location.
- Creator opens a placement/calibration mode.
- App checks tracking quality and guides the creator to a suitable location.
- Creator places and adjusts a scene relative to the shared anchor.
- Creator previews from more than one viewing angle.
- Server validates the scene and stores a draft.
- Creator publishes an immutable scene version.
- A second device/account resolves the published scene independently.

Remote map placement can be considered later, once the team knows how to handle heading, altitude, terrain, visual localization and positioning error. A map pin alone must not be presented as precise 3D placement.

**Before implementing the creator workflow, ask the owner to confirm on-site, remote or both.** Until then, implement only the isolated technical spike and architecture interfaces needed to evaluate placement.

---

## 9. Implementation roadmap — strict sequence

Do not ask Claude Code to “build the whole AR system”. Work in small, reviewable phases with evidence and approval gates.

### Phase 0 — Repository truth and handoff reconciliation

**Goal:** Establish an accurate baseline before touching app behavior.

Tasks:
1. Read this handoff and every existing document in `docs/`.
2. Inspect current `main`, git status and recent history.
3. Inspect the actual Flutter features, routes, state providers, models, repositories, migrations, RLS policies, RPCs and storage buckets.
4. Identify the existing World creator/player/progress code that can be extended.
5. Compare current docs with code and merge history. Add dated corrections without deleting historical records.
6. Update stale instructions in `AGENTS.md` so future Claude Code sessions do not follow the old “AR excluded / Checkpoint 4 next” direction.
7. Rerun the current baseline format, analyze and test commands where the local environment permits. Record exact results and limitations.

**Deliverable:** A concise current-state audit with file paths, implementation status, existing contracts to preserve, documentation conflicts and a proposed AR spike plan.

**Acceptance:** No broad app refactor and no production AR implementation in this phase. Owner reviews the audit and spike plan.

### Phase 1 — Two-device shared-anchor proof of concept

**Goal:** Prove the most important technical risk before designing the whole system around it.

Tasks:
1. Create a minimal isolated Android AR prototype or isolated feature branch.
2. Test ARCore availability and Geospatial/VPS localization at a suitable public outdoor test location.
3. Publish/resolve one shared anchor across two physical devices.
4. Render one optimized GLB asset with stable real-world scale/orientation.
5. Test repeated sessions and tracking loss/recovery.
6. Record accuracy, resolution time, frame rate, memory, battery/thermal behavior and device compatibility.
7. Compare alternative anchor approach only if the leading approach fails the use case.

**Deliverable:** A short technical decision record with video/screenshots, device matrix, measured limitations, selected anchor provider, renderer choice and recommended creator placement workflow.

**Acceptance:** Two devices independently resolve the same shared scene at the same place, with documented positioning quality and honest failure behavior. A one-device local anchor demo does not pass.

**Gate:** Stop for owner review. Do not begin full product integration until the proof of concept is accepted.

### Phase 2 — Native AR foundation integrated with Flutter

**Goal:** Add a stable camera/AR session boundary to the existing Flutter app.

Tasks:
1. Add the native Android AR module with explicit lifecycle ownership.
2. Add the Flutter route/entry state and typed platform interface.
3. Implement capability checks, permission education, camera session start/pause/resume/dispose.
4. Load a development scene manifest and one optimized asset.
5. Surface tracking/anchor state and graceful fallback in Flutter.
6. Add tests for state transitions, errors and lifecycle.

**Acceptance:** The app opens and closes the AR view reliably; backgrounding and returning does not leak camera/session resources; unsupported/denied states are handled.

### Phase 3 — Shared scene backend and publishing contract

**Goal:** Persist and resolve the same scene for different users.

Tasks:
1. Finalize the logical schema based on existing migrations.
2. Add versioned scene/anchor/asset data through committed migrations.
3. Add RLS, ownership checks, server-side validation and storage policies.
4. Add read APIs/RPCs for published scene manifests.
5. Add publish/unpublish/version semantics and audit history.
6. Add tests proving owner-only mutation and explorer read-only access.

**Acceptance:** Account A publishes a scene; account B can read the published version and resolve its same anchor; B cannot modify A's scene; unpublished versions are not newly discoverable.

### Phase 4 — First creator workflow

**Goal:** Let a creator produce one valid shared scene.

Start only after the owner confirms the placement workflow.

Tasks:
1. Build the smallest scene authoring flow for one World and a limited set of supported asset/node types.
2. Add anchor calibration and placement preview appropriate to the approved workflow.
3. Validate scene transforms, asset limits and safety/location rules.
4. Save draft, preview, publish and unpublish.
5. Verify the scene from a second account/device.

**Acceptance:** A non-developer creator can publish one scene without editing JSON or using developer tools.

### Phase 5 — Visual quality and interaction system

**Goal:** Move from technical demo to a coherent product experience.

Tasks:
1. Define the first scene's visual style and asset-quality checklist.
2. Add the supported interaction types needed for the first World.
3. Add purposeful animation, lighting and effects within measured performance budgets.
4. Add loading/streaming, retry and asset-cache behavior.
5. Add accessible descriptions and reduced-motion handling.
6. Test on minimum and recommended Android devices.

**Acceptance:** One complete World looks intentional, is stable, is understandable and performs within the measured device budget.

### Phase 6 — End-to-end pilot readiness

**Goal:** Validate the complete product loop, not just the AR screen.

Test:
- Creator account A creates and publishes a World with a shared scene.
- Explorer account B discovers it on Explore.
- B reaches the unlock area and opens the camera.
- B resolves the same shared anchor and interacts with the scene.
- B's progress persists after leaving/reopening.
- A second explorer resolves the same scene.
- Unsupported device, denied permission, poor tracking, network failure and unpublish cases behave honestly.
- Existing non-AR Worlds continue to work.
- Physical safety, privacy, moderation, accessibility, map attribution, backups and operations are reviewed.

**Acceptance:** The complete flow passes on the agreed device matrix and the owner explicitly approves the pilot.

---

## 10. Non-goals and scope guardrails

Do not build these as part of the first shared-AR slice:

- iOS support before Android is validated.
- Background camera or background location.
- Continuous user tracking or public live user locations.
- A social feed, chat, followers, comments or leaderboards.
- Payments, subscriptions or monetization.
- AI asset generation or AI scene authoring.
- A full 3D editor/game engine inside the phone.
- Arbitrary uploaded scripts or executable scene behavior.
- Multiplayer avatars or real-time shared manipulation of scene objects.
- Cloud-anchor fallback and multiple providers before the first provider is proven.
- Remote creator placement before its workflow is approved and accuracy is validated.
- Wholesale rewrite of the current Flutter application.

Existing Story, Puzzle, Art and Experience content remains relevant. The first AR scene should complement the existing World/player model, not force every World to become AR.

---

## 11. Safety, privacy and trust

- Only allow scenes at places that are public and safe to access. Never encourage trespassing, entering private property, roads, railways, rooftops or restricted facilities.
- Do not ask users to walk while viewing the camera. Give a clear safety prompt and encourage stopping in a safe place before interacting.
- Camera permission is contextual and foreground-only. Do not record or upload camera frames by default.
- Do not store raw camera footage or continuous location trails.
- Request only the location precision needed by the selected anchor provider and explain why.
- Keep exact anchor coordinates and creator placement controls restricted where the product's safety model requires it; public previews should not leak private or sensitive locations.
- Add reporting and moderation for unsafe or abusive spatial content.
- Treat anchor spoofing, scene tampering, malicious assets and abusive publishing as threat-model items.
- Validate all scene data and assets server-side. Client validation is not a security boundary.

---

## 12. Engineering rules for Claude Code

These rules are mandatory:

1. **Audit before coding.** Never assume the repository matches an old handoff.
2. **Preserve working features.** Do not rewrite Explore, auth, World creation, player or progress to make AR easier.
3. **One vertical slice at a time.** Prefer a working end-to-end thin slice over a large collection of placeholders.
4. **No fake completion.** A mock camera, static 3D screenshot, local-only anchor, fake backend response or inert button is not a completed feature.
5. **No speculative dependencies.** Verify package maintenance, Flutter/Android/Kotlin compatibility, licenses and lifecycle behavior before adding a package.
6. **No secrets in client code.** Never put Supabase service-role keys or private provider credentials in Flutter or Android assets.
7. **Database migrations are authoritative.** RLS and backend validation are mandatory.
8. **Test failures and degraded states.** Include unsupported device, permission denial, poor localization, tracking loss, network interruption and lifecycle transitions.
9. **Protect existing tests.** Run format, analyze and relevant tests after each meaningful change. Add regression tests.
10. **Do not silently expand scope.** Ask for approval when product behavior, data collection, permissions, paid services or major architecture changes are needed.
11. **Keep documentation honest.** Distinguish implemented, tested, device-verified, proposed and not started.
12. **Do not claim a device test unless a physical device was actually used and the evidence is recorded.**
13. **Do not publish or delete live test content without explicit authorization.** Confirm the target account, World and action before irreversible or public operations.
14. **Stop at gates.** Present findings and ask for owner approval before proceeding to the next major phase.

### Required report after every phase

Use this structure:

- Phase and objective
- Baseline commit and working-tree status
- Product behavior implemented
- Architecture and data decisions
- Files changed
- Database migrations/RLS/RPC/storage changes
- Tests run — exact commands and results
- Physical-device verification — exact device, OS and scenario
- Performance/visual evidence where relevant
- Known limitations and risks
- Decisions needed from the owner
- Next phase proposal

Never mark a phase complete just because the code compiles.

---

## 13. First task for Claude Code

Start with **Phase 0 only**.

Read this document, inspect the real repository and reconcile the stale instructions. Produce the current-state audit and a focused Phase 1 two-device proof-of-concept plan.

Do not start implementing the production AR feature, do not redesign the existing app, do not create migrations and do not add AR dependencies during this first task.

The first output must answer:

1. What exactly is implemented on current `main`?
2. Which existing Flutter features and backend contracts can be reused?
3. Which documentation statements are stale or contradictory?
4. What devices, location and credentials are required for a valid shared-anchor spike?
5. Which anchor and renderer candidates should be tested, and what evidence will decide?
6. What is the smallest two-device demo that proves the shared-placement requirement?
7. What risks or owner decisions block Phase 1?

**The intended destination is a polished shared-AR World experience. The next step is not to code faster; it is to prove the spatial foundation, then build toward that destination without damaging the product that already exists.**
