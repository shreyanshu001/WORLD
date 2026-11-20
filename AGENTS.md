# Coding-agent operating instructions

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
- No AR, AI generation, chat, followers, feed, payments or monetization in MVP.

## Before coding
Checkpoint 0 (repository audit), Checkpoint 1 (foundation), Checkpoint 2 (identity/profile) and Checkpoint 3 (Explore map) are already implemented and merged into `main`. Do not redo them. First inspect the current `main` tree and `docs/PROGRESS.md`, verify the working tree and latest tests locally, then propose the next approved checkpoint. The immediate product work is Checkpoint 4 (World details and creator), but do not begin it until the product owner explicitly approves it and resolves the listed gate decisions. Do not assume versions or overwrite existing work.

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
- Do not invent a brand system or perform a wholesale visual redesign. The living-atlas/field-journal direction in `docs/UI_UX_SPECIFICATION.md` is proposed, not approved; keep existing Material 3 behavior until the owner approves visual tokens.
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
