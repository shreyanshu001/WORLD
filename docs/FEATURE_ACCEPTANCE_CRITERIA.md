# WORLDS — Feature acceptance criteria

**Rule:** a feature is complete only when the user-visible behavior, backend contract, security, tests and manual verification all pass. A screen existing is not acceptance.

## 1. Global definition of done

Every feature must satisfy all relevant items:
- Real user action, not a decorative or dead control.
- Correct loading, empty, error, retry and success states.
- Data persisted to the authoritative backend when persistence is promised.
- Authorization enforced server-side with RLS/RPC/validated function.
- Input validation on client for usability and server for trust.
- No secrets in client, logs, repository or error messages.
- Unit tests for business rules; widget tests for meaningful UI states/interactions; backend tests for policies/functions; integration tests for critical journeys.
- Formatting and static analysis clean.
- Manual verification on a physical Android device for native map, permission, media and navigation behavior.
- Accessibility: semantics, TalkBack, large text, contrast and adequate touch targets.
- Docs/PROGRESS.md updated with commit, evidence, tests, manual verification and known gaps.
- No checkpoint marked complete while a required gate is open.

## 2. Checkpoint status at document creation

- Checkpoint 0 audit and app scaffold: delivered/merged; audit and owner decisions recorded.
- Checkpoint 1 foundation: implemented/merged; device test deferred.
- Checkpoint 2 identity/profile: implemented/merged; device auth verification and owner security review pending.
- Checkpoint 3 Explore: implemented/merged; 138 Flutter tests recorded passing; actual map rendering/tiles/attribution/markers/location flow on device remain unverified.
- Checkpoint 4 World details and creation: not started.
- Checkpoint 5 player: not started.
- Checkpoint 6 saved/profile/moderation completion: not started.
- Checkpoint 7 beta/pilot: not started.

The latest recorded test count is not proof of the latest repository still passes. Re-run commands on the current checkout before relying on it.

## 3. Platform and foundation

### Startup/configuration
- Valid public Supabase URL and publishable key initialize the app.
- Missing/malformed configuration shows an actionable configuration screen; no crash loop.
- Secret/service-role keys are rejected by client configuration validation.
- Startup loading/failure/retry states work.
- Fresh clone can resolve dependencies and build Android debug APK using documented toolchain.

### Navigation
- Four top-level tabs: Explore, Saved, Create, Profile.
- Tab state preserved when switching.
- Re-tapping current tab returns to its root.
- Auth prompts preserve and restore safe in-app destination.
- Back behavior is correct for nested flows and keyboard.
- No dead-end routes.

## 4. Authentication and profile

- Register with email/password/username; client validation matches server rules.
- Sign-up success/pending email confirmation is accurately represented.
- Profile bootstrap occurs exactly once and does not allow client profile impersonation.
- Sign-in, sign-out and session restore work against real Supabase Auth.
- Profile reads approved public fields only; owner can edit only permitted fields.
- User A cannot read/write private data belonging to User B.
- Duplicate/invalid username behavior matches documented fallback.
- Network/auth/database failures map to understandable messages.
- Password reset/email change are not shown as working until implemented.
- Device verification includes real sign-up (where SMTP/settings allow), sign-in, process restart/session restore, profile edit and sign-out.

## 5. Explore and map (Checkpoint 3)

### Data and query
- Nearby search uses PostGIS RPC; no all-World download or client-side geo filtering.
- Only published public Worlds appear in discovery.
- Search text/category/radius/coordinates validated and bounded server-side.
- Coordinates are sent in request body, not query URL.
- Response contains only preview fields needed by map/list; no secrets or exact user position.
- Query ordering and distance are correct; result count/page limits are explicit.
- Stale search responses cannot overwrite newer filter/search state.

### UI and native behavior
- Map opens at configured pilot centre or safe zoomed-out view without requesting location.
- Map panning/zooming and camera idle update search appropriately.
- Markers use category color plus non-color category cues.
- Marker tap selects; empty-map tap clears selection.
- Preview does not cover required map attribution.
- Map/list toggle works; list remains useful if map tiles fail.
- Location is read only after explicit tap, one-shot, foreground and bounded by timeout.
- Explanation appears before OS prompt; “Not now” does not request permission or position.
- Denied, permanently denied, service disabled and unavailable states have actionable messages.
- Physical-device gate: real tiles/labels, attribution, marker rendering, camera gestures, permission flow and actual location query visually inspected and recorded.

Known remaining gate from latest progress: the app was installed/launched but the screen was not successfully captured/visually inspected. Do not describe map as device-verified.

## 6. World details and creation (Checkpoint 4)

### Details
- Published public World opens from marker/list.
- Shows title, category, creator, description, cover/fallback and approximate distance.
- Locked/unlocked state is based on current policy and fresh eligibility; no false Start CTA.
- Puzzle answers and hidden branches are never exposed in preview.
- Save/share/report actions are real or clearly disabled until implemented.
- Hidden/unpublished/deleted Worlds are not accessible through normal discovery.

### Creation
- Any authenticated user can create draft for all four categories.
- Creator can set title, description, category, location and unlock radius (25–150m, default 50m).
- Location selection never silently requests device location.
- Typed block editor supports only documented block schemas.
- Reordering works by drag and accessible alternative.
- Story branch references are valid block IDs in same World.
- Puzzle secret is stored server-side and never returned in public API.
- Uploads enforce owner, MIME, size and association; failed uploads can retry.
- Draft persists across navigation/restart according to documented save strategy.
- Preview matches player rendering.
- Publish is atomic and server-validates all required fields/assets/blocks/secrets.
- Only owner can edit/unpublish; other authenticated users cannot mutate.
- Published World appears in another account's map query.
- Publish retry after timeout does not create duplicate World or inconsistent status.
- Unpublish removes World from discovery.
- Safety warning addresses public access/trespass.

## 7. Player (Checkpoint 5)

- Player loads only server-authorized World content.
- Versioned block renderer supports text, image, story choice, question, artwork and completion.
- Valid story choice advances to the intended block; invalid/cross-World target rejected.
- Puzzle answer validation happens server-side; attempts rate-limited; secret never in client payload/log.
- Proximity is rechecked using a fresh foreground sample at unlock; uncertainty and retry are explicit.
- Account requirement is decided and documented before implementation.
- Progress is server-confirmed and resumes after app kill/reinstall/sign-in.
- Duplicate transitions/completion are idempotent.
- Unpublished/hidden World behavior is consistent and tested.
- Complete flow works for creator account A and explorer account B.

## 8. Saved, profile and moderation (Checkpoint 6)

- Save/remove persists; optimistic UI rolls back on failure.
- Saved list is private to current user and paginated.
- Profile shows real data only; created/discovered/completed counts only when backed by real queries.
- Creator's drafts/published Worlds are separated.
- Report flow validates reason/details and rate limits submissions.
- Reporter identity/details are not exposed to creator or public.
- Trusted moderator role is server-controlled.
- Hide/unpublish removes content from discovery promptly.
- Moderation action is auditable and cannot be bypassed by creator.
- Deletion/retention behavior documented.

## 9. Beta and pilot (Checkpoint 7)

- Physical-device testing on low/mid-range Android and varied network conditions.
- Permission denial, GPS accuracy, location services disabled and stale readings tested.
- Map tile provider terms, attribution, request volume and fallback costs rechecked.
- Supabase free-tier pause/storage/egress limits understood; backup/restore and operational owner identified.
- Crash/error reporting reviewed for PII and location leakage.
- Text scaling, TalkBack and contrast verified.
- 15–20 curated Worlds in one walkable pilot area, avoiding private/restricted/sensitive locations.
- Testers complete creator-to-explorer flow independently.
- Funnel measured: map → details → start → completion; first publish; second discovery; repeat creator activity.
- No critical crash, authorization flaw or unsafe seeded content.
- Product owner explicitly approves wider release.

## 10. Evidence format

For each feature/checkpoint, record:
- Commit SHA and changed files.
- Exact commands, test totals and failures.
- Backend migration/RPC/RLS tests and environment.
- Device model/Android version and manual steps performed.
- Screenshot/video evidence where available (do not claim visual verification without it).
- Known limitations and decisions still open.
- Approval status.
