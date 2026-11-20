# WORLDS — Decision log

## Accepted
- **D-001 Map-first discovery:** location is the product differentiator.
- **D-002 Four launch categories:** Story, Puzzle, Art, Experience.
- **D-003 Open creation:** any authenticated user can create/publish subject to validation, rate limits and moderation.
- **D-004 No AR in MVP:** GPS-based experiences first; prove demand before device-specific complexity.
- **D-005 Supabase/Postgres/PostGIS:** minimize solo-operator burden while supporting spatial queries.
- **D-006 Foreground location only:** privacy, battery and permission simplicity.
- **D-007 Structured blocks:** safe rendering and schema evolution.
- **D-008 Start on the installed Flutter 3.38.3 / Dart 3.10.1:** product-owner decision, 2026-11-19. This SDK is verified on the development machine. Alternatives were a per-project pin to Flutter 3.50.x (latest packages, not verified on this machine) and a global upgrade (changes other projects on the machine). Trade-off: 11 of 17 recommended packages resolve below their latest release. Revisit when a required package needs a newer SDK. Evidence: `docs/REPOSITORY_AUDIT.md`.
- **D-009 Placeholder application ID `com.example.worlds`:** product-owner decision, 2026-11-19. Google Play rejects `com.example`, so a real application ID must replace it before any release build.

The next four were adopted on the audit's recommendation when the product owner said to go ahead with Checkpoint 1 (2026-11-20). The owner did not choose them individually.

- **D-010 Gradle pinned to Java 21 per project:** `android/gradle/gradle-daemon-jvm.properties` contains `toolchainVersion=21`. It overrides the machine's user-level JDK 20 setting for this project only. Alternatives: change the machine-wide setting (could break older projects on the machine) or set `GRADLE_OPTS` in every shell (easy to forget). Requires a JDK 21 on the building machine. Audit decision D2.
- **D-011 Publishable Supabase key:** configuration uses `SUPABASE_PUBLISHABLE_KEY`, because Supabase is deprecating legacy anon and service-role keys by the end of 2026. The app refuses to start with a secret or service-role key. Audit decision D9.
- **D-012 Generated code is committed:** `*.freezed.dart` and `*.g.dart` are committed so a fresh clone builds without running `build_runner`. Audit decision D11.
- **D-013 Hand-written Riverpod providers:** `riverpod_generator`, `riverpod_annotation` and `riverpod_lint` are not used. On Flutter 3.38.3 the generator holds Riverpod at 3.1.0; without it Riverpod resolves to 3.3.2, and the slow `build_runner` step stays limited to Freezed and json_serializable. Revisit if the project moves to a newer Flutter.

## Pending; require evidence and rationale
- Map package/version after SDK audit. Recommendation recorded in `docs/REPOSITORY_AUDIT.md` (D4); not yet approved.
- Production tile provider and its terms. Recommendation recorded in `docs/REPOSITORY_AUDIT.md` (D5); not yet approved.
- Dependency versions for later checkpoints (Flutter/Dart settled by D-008; Checkpoint 1 packages recorded in `docs/DEPENDENCY_DECISIONS.md`).
- Final application ID (placeholder in use, see D-009).
- Supabase region/configuration.
- Image transform/thumbnail strategy.
- Username uniqueness/case-folding policy.

Do not silently resolve pending decisions. Record evidence, alternatives and trade-offs.
