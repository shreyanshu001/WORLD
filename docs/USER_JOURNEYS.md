# WORLDS — User journeys and interaction flows

**Status:** Functional journey contract for MVP. Account requirement for unlocking/playing remains a product decision (see D-019 and audit gap G3).

## 1. Actors and rules

- **Visitor:** can open Explore and browse public published Worlds without an account.
- **Signed-in explorer:** can use account-bound features such as saving, subject to final play/unlock decision.
- **Creator:** any authenticated user can create and publish Worlds, subject to validation, rate limits and moderation.
- **Moderator/admin:** trusted server-side role only; never inferred from editable profile metadata.

Global rules:
- Map is the discovery home.
- Only published, public Worlds appear in normal map discovery.
- Location is requested only after an explicit user action; foreground one-shot reading only.
- Exact coordinates and puzzle secrets are not exposed in public preview responses.
- Every network-backed flow has loading, success, empty and recoverable failure behavior.
- Preserve drafts, text and progress across recoverable interruptions.

## 2. Journey A — First visit and anonymous discovery

**Goal:** understand the product and find an interesting World without being forced to register.

1. User opens app.
2. Startup gate validates public Supabase configuration and initializes the app.
3. App opens Explore.
4. If a pilot centre is configured, map opens there; otherwise it opens zoomed out without requesting location.
5. User can pan/zoom the map or use title search and category filters.
6. When map camera becomes idle, app requests a bounded nearby result page for the visible search centre.
7. User taps a marker or list result.
8. Compact preview shows title, category, creator and distance reference.
9. User can clear selection, change filters, search another title or switch between map and list.

Success: visitor discovers a World and understands that it is attached to a real place.

Failure/edge cases:
- No results: explain that the area has no matching Worlds and offer another area/filter.
- Network failure: preserve usable map and last safe results, show retry.
- Map tiles fail: do not trap user in a blank screen; retain list/results if possible.
- Slow query: stale older responses must not replace newer search/filter state.
- User denies location: continue browsing by map movement; do not repeatedly prompt.
- App resumes after Settings: recheck permission state only; do not silently read location.

## 3. Journey B — Find Worlds near me

**Goal:** use the user's current location only when requested.

1. User taps “Find Worlds near you”.
2. If the explanation has not been shown for this permission decision, show a short explanation: location is used only on tap, not tracked in background and not shown to others.
3. “Not now” closes the dialog and must not trigger permission prompt or position read.
4. “Continue” requests foreground permission if needed.
5. If granted and location services are enabled, request one location sample with a bounded timeout.
6. Query nearby Worlds using the sample; display distance as “away”.
7. If denied, blocked, disabled or unavailable, show the relevant explanation/action. Map movement remains available.

Success: nearby Worlds load and the UI clearly indicates distance is based on user location.

Privacy invariants:
- No background permission.
- No continuous location stream.
- No user position broadcast.
- No location history/trail.
- Do not request location on launch, on tab change or from map rendering.

## 4. Journey C — Account creation and sign-in

**Goal:** create an account without losing the intended destination.

1. User taps Create, Saved or Profile while signed out.
2. App shows a contextual sign-in prompt explaining why an account is needed.
3. User chooses sign-in or registration.
4. Registration collects email, password and requested username.
5. Validate username format and password rules before sending.
6. Server creates Auth user and profile; if username is invalid/taken at creation, follow the documented generated-username fallback and explain the result.
7. Handle email confirmation according to actual Supabase settings; do not claim account is ready if confirmation is pending.
8. On successful authenticated session, return to the original safe in-app destination.
9. User can sign out from Profile; clear account-bound UI state and refresh auth-gated screens.

Failure/edge cases:
- Duplicate email, invalid credentials, weak password, username collision, offline/network failure, email confirmation pending and profile bootstrap failure.
- Never show stale username collision notices on a different account.
- Do not discard typed form data on recoverable failures.

## 5. Journey D — Create and publish a World

**Goal:** a first-time creator publishes a complete, safe experience.

Precondition: authenticated user. The user may create any of the four categories.

1. User opens Create.
2. If signed out, complete Journey C and return to Create.
3. Choose Story, Puzzle, Art or Experience. Show a concise explanation and example for each.
4. Enter title and description; optionally add a cover.
5. Pick a location on a map or explicitly use current location. Location must be a public, safe, lawful place.
6. Set unlock radius within the allowed range; default 50m. Explain that GPS can be imprecise.
7. Add typed blocks:
   - Story: text/image blocks and optional branching choices.
   - Puzzle: clue/prompt/hint plus answer configured into a private server-only secret.
   - Art: artwork and descriptive context.
   - Experience: ordered combination of supported blocks.
8. Reorder blocks, validate branch destinations and preview the experience as an explorer.
9. Save draft at any point; draft is private to creator.
10. Publish. Server validates ownership, required metadata, location, asset ownership, block schema, bounds and puzzle secrets atomically.
11. On success, show Published state and offer “View on map”.
12. Creator returns to Explore and sees the published World when its area is queried.

Failure/edge cases:
- Auth expires: preserve local draft and ask user to sign in again.
- Upload fails: retry without losing text or block order.
- Invalid branch or missing puzzle answer: identify exact block and keep draft.
- Publish request times out: query authoritative status before retrying to avoid duplicate publication.
- World hidden by moderation: explain state to creator without exposing reporter identity.
- User abandons flow: warn about unsaved changes only if there are changes not persisted.

## 6. Journey E — Preview, travel and unlock

**Goal:** know what to expect and unlock only when within the configured radius.

1. User opens World details from marker/list/share link.
2. Details show preview, category, creator, approximate distance and locked/unlocked state.
3. If outside radius, show “Go to location” with clear distance context; do not falsely offer Start.
4. User travels to a lawful public location.
5. User explicitly taps Unlock/Check location.
6. Request a fresh foreground position (do not reuse an old reading indefinitely).
7. Compare to radius on trusted backend logic where possible; account/play gate remains subject to D-022 decision.
8. If outside or accuracy is insufficient, explain and allow retry.
9. If eligible, allow Start/Continue.

GPS is not anti-cheat. Do not claim that this proves physical presence or detects spoofing. Do not encourage entering restricted/private property.

## 7. Journey F — Play, branch, resume and complete

**Goal:** complete a World and persist progress reliably.

1. User starts a World.
2. Server validates access and returns safe ordered content (no question answers).
3. Player renders the current block using a versioned renderer.
4. User moves through text, image and artwork blocks.
5. Story choice submits a stable option ID; server validates destination belongs to this World.
6. Puzzle response is submitted to server; server normalizes and validates against private secret, applies attempt limits and returns only success/failure plus safe feedback.
7. Server persists each accepted transition.
8. If app closes or network drops, user can resume from last server-confirmed state.
9. On final block, server marks completion idempotently and returns completion summary.
10. Offer return to map, save/share or discover another World.

Failure/edge cases:
- Duplicate tap/request: idempotent transition; do not double-count completion.
- Stale client block: server returns authoritative current progress.
- Invalid branch or answer: do not advance.
- Offline: do not show unconfirmed progress as completed; retain retryable local intent only if designed and safe.
- World unpublished while playing: handle according to a documented policy; never expose hidden content to new sessions.
- App killed: resume from backend progress.

## 8. Journey G — Save and revisit

1. User taps Save on World details.
2. If account is required, show contextual sign-in and return to World details after success.
3. Save is persisted to the signed-in user's account.
4. Saved list shows current saved Worlds.
5. User opens a saved World or removes it.
6. Failed save/remove rolls back optimistic UI and shows retry.

Privacy: one user's saved list is never readable by another user.

## 9. Journey H — Report a World

1. User opens World details and taps Report.
2. Select reason and optionally enter concise details.
3. Confirm submission.
4. Server checks authentication, bounds and rate limits; prevent duplicate pending reports.
5. Show confirmation without revealing moderation internals.
6. Trusted moderator reviews and may dismiss, hide or remove the World.
7. Creator sees only the resulting content state and appropriate guidance, never reporter identity.

## 10. Journey I — Creator lifecycle

- Draft: private; creator can edit/delete.
- Published: discoverable if public; creator can edit/unpublish.
- Unpublished: removed from discovery; can be republished after validation.
- Hidden: removed from discovery by moderation; creator cannot override.
- Deleted: soft-deleted and not discoverable; retention/deletion policy applies.

Every state transition must be authorized server-side and reflected consistently in map/details/creator views.

## 11. Cross-journey quality requirements

- Every CTA has a real destination/action or is visibly disabled with explanation.
- Loading never blocks unrelated navigation unnecessarily.
- Retry is safe and idempotent where a mutation may have reached the server.
- Errors are translated into actionable plain language, not raw backend text.
- Preserve user input and draft content on failure.
- Track only product events needed for funnel analysis; never continuous GPS trails.
- Screen readers, keyboard, large text and small screens are supported.
- No fake data or local-only persistence presented as a completed production feature.
