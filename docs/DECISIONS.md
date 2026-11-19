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

## Pending; require evidence and rationale
- Map package/version after SDK audit. Recommendation recorded in `docs/REPOSITORY_AUDIT.md` (D4); not yet approved.
- Production tile provider and its terms. Recommendation recorded in `docs/REPOSITORY_AUDIT.md` (D5); not yet approved.
- Dependency versions (Flutter/Dart settled by D-008).
- Final application ID (placeholder in use, see D-009).
- Supabase region/configuration.
- Image transform/thumbnail strategy.
- Username uniqueness/case-folding policy.

Do not silently resolve pending decisions. Record evidence, alternatives and trade-offs.
