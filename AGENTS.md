# Coding-agent operating instructions

You are implementing WORLDS. These rules are mandatory.

## Source of truth
Read README.md and all documents in docs/ before implementation. If they conflict, stop and report the conflict.

## Locked product direction
- Map-first discovery.
- Story, Puzzle, Art and Experience categories at launch.
- Any authenticated user may create and publish, subject to validation and moderation.
- Flutter Android-first.
- Supabase, PostgreSQL and PostGIS.
- Foreground location only.
- No AR, AI generation, chat, followers, feed, payments or monetization in MVP.

## Before coding
Complete Checkpoint 0 in docs/IMPLEMENTATION_PLAN.md. Inspect the actual repository, SDK, conventions, Android configuration, dependencies, existing backend and design system. Do not assume versions or overwrite existing work.

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

## First task
Repository reconnaissance only. Do not implement app features. Complete the audit in Checkpoint 0 and return the evidence-based report.
