# WORLDS — Step-by-step implementation plan

Build one complete vertical slice at a time. Do not combine checkpoints into one large coding task.

## Checkpoint 0 — Repository reconnaissance (no implementation)
Tasks:
- Inspect git status, tree, README, existing handoffs and design docs.
- Record `flutter --version`, `dart --version`, AGP, Gradle, Kotlin, min/target SDK.
- Inspect pubspec, routing, state management, architecture, theme and reusable widgets.
- Inspect Supabase config, migrations, auth, storage and secret handling without printing secret values.
- Check map packages against actual SDK; review tile provider attribution, rate limits, caching, commercial terms and pilot cost.
- Identify reusable code and risks.

Deliver: `docs/REPOSITORY_AUDIT.md`, updated dependency decisions and implementation sequence.
Acceptance: no source code changes; compatibility risks evidenced; map approach recommended; no secrets copied.
**Gate:** stop and request approval.

## Checkpoint 1 — App foundation
- Keep or establish feature-first structure; configure lint/format.
- Add compatible Riverpod, Freezed, json_serializable and go_router.
- Configure environment injection and Supabase initialization.
- Build theme, app shell, bottom navigation and shared loading/empty/error components.
Acceptance: app launches on Android, placeholder tabs navigate, analyze/tests pass, no fake functional features or committed secrets.
**Gate:** review shell and architecture.

## Checkpoint 2 — Backend and identity
- Create/link user-owned Supabase project; enable PostGIS.
- Add migrations, RLS and profile bootstrap.
- Implement email/password auth and profile read/update.
Acceptance: register/sign-in/sign-out/session restore; safe profile bootstrap; User A cannot update User B; fresh DB builds from migrations; no service key in app.
**Gate:** security review.

## Checkpoint 3 — Explore map
- Integrate selected SDK behind adapter; foreground permission and recenter.
- Nearby PostGIS query, category filters, markers, selected preview and accessible list alternative.
- Loading, no-results, denied, unavailable and retry states.
Acceptance: only published/public Worlds appear; server computes distance; attribution visible; app remains useful when permission denied; no background permission.
**Gate:** real-device map and tile-policy verification.

## Checkpoint 4 — Details and creator
- World details; create/edit draft; category/template; metadata/cover; map location picker/radius.
- Constrained image uploads; typed block editor, reorder and preview.
- Publish/unpublish RPC with server-side validation.
Acceptance: any authenticated user can draft; only owner edits; invalid publish rejected; published World discoverable; other users cannot modify; storage enforces ownership/MIME/size.
**Gate:** publish with account A and verify as account B.

## Checkpoint 5 — Experience player
- Typed block renderer; story branching; question UI with server-side answer validation.
- Fresh proximity check; start/resume/progress/completion APIs.
Acceptance: B can play A's World; locked state outside radius; puzzle answer absent from public payload; valid branches only; progress survives restart; completion is idempotent.
**Gate:** demonstrate creator-to-explorer vertical slice.

## Checkpoint 6 — Saved, profile and moderation
- Saved Worlds, public profile, creator Worlds, profile edit, report flow, admin hide/unpublish and rate limits; deep links only if low-risk.
Acceptance: saves private to owner; reports private to reporter/admin; rate limits work; hidden content leaves discovery; profile exposes approved fields only.
**Gate:** moderation/privacy review.

## Checkpoint 7 — Beta and pilot
- Low/mid-range Android tests, GPS accuracy, permission, network interruption, upload retry, accessibility/text scale.
- Privacy-reviewed crash/error logging and analytics.
- Seed 15–20 quality Worlds in one walkable pilot area; invite testers and observe sessions.
Acceptance: no known critical security issue/crash in core flow; map/publish/player work on target devices; safe pilot content; no location trail collection.
**Gate:** product owner chooses expand, iterate or stop.

## Definition of done for every checkpoint
Formatting, static analysis, relevant tests, manual verification, no secrets, updated docs/PROGRESS.md, known issues recorded and explicit approval before next checkpoint.
