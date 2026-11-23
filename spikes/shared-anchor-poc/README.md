# Shared-anchor proof of concept (Phase 1)

A standalone native Android app that answers one question before WORLDS builds any AR product:

> Can two different phones, with no shared session, rebuild the same anchor from a stored pose and show it at the same physical spot? How far off is each, and how far apart are they?

**Status:** written and built on 2026-11-23. **Not yet tested on any phone or at any site.** Google Cloud is ready (owner confirmed: ARCore API enabled, Android client matches, no billing account). It still needs two ARCore-certified phones and a site.

| | |
|---|---|
| Plan | `docs/PHASE_0_AUDIT.md` section 6 |
| Approval | D-044 |
| Branch | In `main` since 2026-11-23 (owner merged pull request #14). Field-test work: `phase-1-field-test`. Still a separate app; the Flutter app does not use it |
| Relationship to WORLDS | None at runtime. It does not touch the Flutter app, its tests or the database. Poses move between phones as files, not through Supabase. |

## What it does

1. **Shows Google's required notice and the safety prompt.** Testers must acknowledge Google processing camera and location data (accepted for the PoC only, D-044).
2. **Checks ARCore availability.** An unsupported phone is told so and the result is logged. This is the AR-001/AR-009 test for the realme P4 5G.
3. **Asks for the camera and precise location,** in the foreground only.
4. **Runs an ARCore session with Geospatial,** showing the state (`CHECKING`, `LOCALIZING`, `LOCALIZED` (no anchor yet), `RESOLVING`, `TRACKING`, `DEGRADED`, `TEMPORARILY_UNAVAILABLE`, `FAILED`) and the horizontal, vertical and yaw accuracy.
5. **Capture:** aim the cross-hair at a ground mark and press Capture. This turns the hit point into latitude, longitude, WGS84 altitude, an offset above terrain (0) and an upright rotation facing the person capturing. The pose is saved as a JSON file and placed at once as a WGS84 anchor.
6. **Terrain / WGS84:** rebuilds the anchor from the loaded pose.
   - Terrain: resolved by Google's service, altitude from Google Maps.
   - WGS84: created on the phone from the stored altitude.
7. **Quality gate (AR-004):** the pin is drawn only while accuracy is within the gate (default 10 m / 15°, hysteresis 5 m / 5°, adjustable on screen). Otherwise it is hidden, never left to drift.
8. **VPS check:** type a candidate site's coordinates to ask Google whether VPS covers it. This works from anywhere, so sites can be surveyed before going.
9. **Measurement log:** one JSON object per line.
   - Recorded: state changes, Earth state, first localization, resolve times and results, camera-tracking failures, pauses and resumes; every 5 s the camera frame rate, the worst frame, memory, battery and thermal status.
   - Never recorded: the phone's own position.

What is drawn is a **DEBUG measurement pin**, labelled DEBUG on screen:
- a 0.30 m disc on the ground at the anchor point,
- a 1.2 m magenta mast with a ball on top,
- a cyan arm pointing along the direction the pose faces.

It is not product content. A GLB is drawn with it only if the owner imports a licensed one ("Import GLB"; binary glTF up to 50 MB, its SHA-256 is logged).

Not in the spike: Flutter, Supabase, creator UI, several objects, interactions, Cloud Anchors, iOS.

## Versions and why

| Item | Version | Reason |
|---|---|---|
| Gradle / AGP / Kotlin / JDK | 8.14 / 8.11.1 / 2.2.20 / 21 (target 17) | Same as `android/` in WORLDS, so whatever builds here can be added to the app in Phase 2 |
| SceneView `arsceneview` | 2.3.4 (2026-10-10, Apache-2.0) | Built with Kotlin 2.2.21 and builds with the WORLDS toolchain. The 4.x line (4.72.0 on 2026-11-23, about 50 releases since May 2026) was build-tested once: Gradle's AAR-metadata check fails because it needs compileSdk 37 and AGP 9.1+. Its POM also names Kotlin 2.4.21. |
| ARCore SDK `com.google.ar:core` | 1.52.0 | What SceneView 2.3.4 was built against (latest is 1.57.0, 2026-10-15) |
| Filament | 1.68.2 | Through SceneView |
| `play-services-location` / `-auth` | 21.3.0 / 21.3.0 | Geospatial needs fused location; keyless authorization needs auth |
| Compose | activity-compose 1.11.0, material3 1.4.0, lifecycle 2.9.4 | Same period as SceneView's Compose 1.10 |

SceneView 2.3.4 also pulls `fuel` 3.0.0-alpha04, an HTTP library for loading remote models. The spike does not use it. It is an alpha dependency, which matters for Phase 2.

## Build

Needs JDK 21 (Android Studio's), the Android SDK with platform 36, and `local.properties` with `sdk.dir=...` (gitignored; copy the line from `android/local.properties`).

```sh
cd spikes/shared-anchor-poc
./gradlew testDebugUnitTest assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Before the field day

1. **Two phones on Google's ARCore list** (https://developers.google.com/ar/devices), ideally different makers, e.g. a Galaxy A35/A55 and a Pixel 8a/9a. Each needs "Google Play Services for AR" from Play, mobile data, battery at 80% or more, and USB debugging. Optionally the realme P4 5G too, for the unsupported-phone result.
2. **A Google Cloud project with keyless authorization** (https://developers.google.com/ar/develop/authorization?platform=android):
   - Enable the **ARCore API**.
   - Create an **OAuth client ID** of type Android with package name `com.example.worlds.arspike` and the SHA-1 of the signing key. Debug keystores differ per computer, so either build every test APK on one computer, or register each computer's SHA-1. Get it with `./gradlew signingReport`.
   - Nothing is put in the app or the repository: no API key, no secret.
   - Without this, Earth reports `ERROR_NOT_AUTHORIZED` and the spike shows `FAILED`.
3. **Candidate sites.** Check each with "VPS check" before going. Each site needs to be:
   - public, safe and lawful, with no traffic;
   - marked by something fixed and exact, e.g. a paving-slab corner or a bollard's base;
   - with a clear facing direction to note down.
4. A tape measure, a compass reference (or the HUD heading), and a way to take a photo from a fixed spot.

## Field protocol

Do it at one site, on at least two visits at different times of day (e.g. midday and late afternoon).

**Per visit:**
1. Both phones: open the app and pan slowly across buildings until the state changes from `LOCALIZING` to `LOCALIZED` (accuracy inside the gate). The log records the time as `first_localized`.
2. **Phone A captures:** stand back about 3 m from the mark, aim the cross-hair at it, press Capture. Export the pose ("Export pose") and send it to phone B by Quick Share. `adb push` into `Android/data/com.example.worlds.arspike/files/poses/` also works.
3. **Phone B, from a cold start** (swipe the app away first): Import pose, then **Terrain**. Measure as below. Then **Clear**, then **WGS84**, and measure again.
4. **Swap roles** (B captures, A resolves).
5. **Repeat** so that each phone resolves at least 5 times per visit, from different standing points 3-10 m away.
6. **Loss and recovery,** once per phone: cover the camera for 5 s, then uncover it. Record what the pin did; it must hide, not drift.
7. Optionally, **a map-typed pose:** write a pose JSON by hand with the mark's coordinates from a map, `"source": "map_coordinates"`, `"altitude_wgs84_m": null`. Resolve it with Terrain and measure. This is the evidence for on-site versus remote placement.
8. **Export the log** from each phone afterwards ("Export log" or `adb pull`).

**Measuring one resolve:**
- Tape the horizontal distance from the physical mark to where the pin's disc centre appears on screen, and estimate the height of the disc above or below the ground.
- Note the angle between the cyan arm and the noted facing direction.
- Photograph phone A's and phone B's screens from the same spot when both show the pin.

**Measurement sheet** (one row per resolve):

| visit | time | site | phone | role (capture/resolve) | anchor (terrain/wgs84) | pose source | time to localize (s) | resolve time (ms) | reported h / v / yaw at resolve | offset to mark (m) | height error (m) | heading error (°) | A-vs-B offset (m) | after 5 s cover | fps / thermal | notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

**Pass (from the handoff):** two different certified phones independently rebuild the same stored pose and show the pin at the same mark, with the error measured and recorded, and failure states shown honestly. One phone, or a shared session, does not pass. Google quotes VPS at about 5 m and 5° in typical conditions. The decision record reports median and worst-case figures; it does not invent a pass threshold.

## Pose file (schema 1)

```json
{
  "schema_version": 1,
  "label": "Capture 14:02:11",
  "latitude": 0.0,
  "longitude": 0.0,
  "altitude_wgs84_m": 0.0,
  "altitude_above_terrain_m": 0,
  "eus_quaternion_xyzw": [0, 0, 0, 1],
  "source": "on_site_capture",
  "captured_at_epoch_ms": 0,
  "captured_by": "maker model",
  "capture_accuracy": { "horizontal_m": 0, "vertical_m": 0, "yaw_deg": 0 }
}
```

- Frame: East-Up-South.
- Latitude -90..90; longitude -180..180.
- `altitude_wgs84_m`: -500..9000, or `null` when typed from a map (then only Terrain works).
- `altitude_above_terrain_m`: -10..100.
- The quaternion is normalized on load.
- A file that fails these checks is refused with a reason.

## Known limits of the spike

- **Not run on a phone yet.** Everything about real behaviour, including the facing direction a capture produces, is to be confirmed in the field.
- **Heading:** derived from the camera's East-Up-South quaternion (unit-tested maths). Whether Earth's camera pose follows the display-oriented camera convention in every orientation is to be confirmed in the field.
- **Terrain offset:** the capture stores 0 m above terrain for a ground mark. If Google's terrain model is off at the site, the Terrain result shows it; that is a finding, not a bug.
- **Performance:** the frame rate is the camera frame rate from ARCore timestamps, not a GPU profile. Memory is the app's Java and native heap, not total PSS.
- **Notice text:** the Google notice is worded from Google's privacy-requirements page as read on 2026-11-23. Recheck it against that page before testers outside the team see it.
