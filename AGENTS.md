# Coding-agent operating instructions

> **Current direction:** Read [`docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md`](docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md) first. It supersedes the older statements below that AR is excluded, Checkpoint 4 is next, or the current task is only the pre-Checkpoint-4 audit. WORLDS is now moving toward shared, camera-based, location-anchored 3D experiences. Preserve the existing Flutter/map/World/player foundation. The first task is Phase 0 (repository truth and handoff reconciliation), then stop for owner review. Do not implement production AR in Phase 0.

You are implementing WORLDS. These rules are mandatory.

## Source of truth
Read README.md and **all** documents in docs/ before implementation. In particular, use `docs/USER_JOURNEYS.md` for end-to-end behavior, `docs/UI_UX_SPECIFICATION.md` for screen/interaction/accessibility requirements, and `docs/FEATURE_ACCEPTANCE_CRITERIA.md` for measurable completion gates. `docs/PROGRESS.md` and the merged code are the current implementation baseline; older planning documents may describe work that is already complete. If documents or code conflict, stop, identify the exact conflict and propose a correction before proceeding. Never blindly replay a completed checkpoint.

## Locked product direction
- Map-first discovery.
- Story, Puzzle, Art and Experience categories at launch.
- Any authenticated user may create and publish, subject to validation and moderation.
- Flutter Android-first.
- Supabase, PostgreSQL and PostGIS.
- Foreground location only.
- Shared camera-based AR is now the approved product direction for the next phase. See the handoff for scope, proof-of-concept gates and non-goals. AI generation, chat, followers, feed, payments and monetization remain out of scope.

## Before coding
Checkpoints 0–7 have been merged into `main` according to the reviewed 2026-11-23 GitHub history; the pilot and several device gates remain incomplete. Do not replay completed checkpoints. Follow Phase 0 of `docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md` first. Do not begin production AR implementation until the two-device shared-anchor proof of concept is accepted by the owner.

## Engineering rules
- Feature-first architecture with presentation, application, domain and data boundaries.
- Riverpod 3, Freezed, json_serializable and go_router only after SDK compatibility is verified.
- Wrap map and location SDKs behind interfaces.
- Never ship Supabase service-role keys.
- Enable and test RLS on every exposed table.
- Use committed migrations under supabase/migrations; no undocumented dashboard-only schema changes.
- Validate content client-side for UX and server-side for trust.
- Puzzle answers must never be returned in public payloads.
- Nearby search must use PostGIS, not downloading all Worlds and filtering in Dart.
- Do not use public OSM tile servers as production infrastructure without checking their policy.
- Never add background location permission.
- Implement loading, empty, error, permission-denied and retry states.
- Do not perform a wholesale visual redesign during the AR foundation work. The existing UI specification remains relevant for existing screens; the AR experience must follow the approved visual-quality direction in `docs/PRODUCT_DIRECTION_AND_CLAUDE_HANDOFF.md`. Propose and validate new AR visual tokens before broad UI changes.
- Do not present placeholders, fake data, local-only persistence or inert buttons as completed product functionality.
- Preserve existing passing tests and add regression tests for every behavior change.
- No scope expansion without product-owner approval.
- Avoid unrelated refactors.

## Checkpoint protocol
At each checkpoint:
1. Format code.
2. Run static analysis.
3. Run relevant unit, widget and integration tests.
4. Report exact commands and results.
5. List files and migrations changed.
6. Record known issues.
7. Update docs/PROGRESS.md.
8. Stop for product-owner approval before the next checkpoint.

## Required report
### Checkpoint
### Implemented
### Files changed
### Database/API changes
### Tests run and results
### Manual device verification
### Known issues
### Decisions needed
### Next checkpoint proposal

## Current task
Review the latest merged implementation against the three UX/product documents and the open gates in `docs/PROGRESS.md`. Do not start a new feature until the owner approves Checkpoint 4. Return the required checkpoint report with exact evidence.
