# WORLDS — Decision log

## Accepted
- **D-001 Map-first discovery:** location is the product differentiator.
- **D-002 Four launch categories:** Story, Puzzle, Art, Experience.
- **D-003 Open creation:** any authenticated user can create/publish subject to validation, rate limits and moderation.
- **D-004 No AR in MVP:** GPS-based experiences first; prove demand before device-specific complexity.
- **D-005 Supabase/Postgres/PostGIS:** minimize solo-operator burden while supporting spatial queries.
- **D-006 Foreground location only:** privacy, battery and permission simplicity.
- **D-007 Structured blocks:** safe rendering and schema evolution.

## Pending; require evidence and rationale
- Map package/version after SDK audit.
- Production tile provider and its terms.
- Flutter/Dart and dependency versions.
- Supabase region/configuration.
- Image transform/thumbnail strategy.
- Username uniqueness/case-folding policy.

Do not silently resolve pending decisions. Record evidence, alternatives and trade-offs.
