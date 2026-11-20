# WORLDS — UI/UX specification

**Status:** Interaction requirements are the implementation baseline. Visual identity below is a proposed direction, not a final brand approval.  
**Repository baseline reviewed:** `main` after Checkpoint 3 merge, 2026-11-20.

## 1. Purpose and product experience

WORLDS should feel like an invitation to explore the real world, not a conventional social feed with a map bolted on. The map is the home surface; each World should feel like a small, intentional experience worth travelling to.

Design priorities, in order:
1. Make discovery immediately understandable.
2. Make a World feel intriguing before a user visits it.
3. Make proximity and permission behavior transparent, never creepy.
4. Make creating a World approachable for a first-time creator.
5. Keep the experience player focused and distraction free.
6. Keep every screen useful on small Android phones and imperfect networks.

## 2. Current implementation baseline (do not accidentally regress)

The repository already contains:
- Material 3 light/dark ThemeData with a placeholder forest-green seed `#1F6F5B`; the code explicitly says this is not a brand decision.
- Four-tab NavigationBar: Explore, Saved, Create, Profile.
- Email/password sign-in and registration, profile view/edit, sign-out and auth prompts.
- Explore map with title search, four category chips, locate button, map/list switch, map markers, selected World preview, attribution and location/search state messages.
- MapLibre behind `MapAdapter`; geolocator behind `LocationService`.
- Category icon/color mapping in `lib/shared/components/category_style.dart`.

Preserve working behavior and tests. This document does not authorize a wholesale rewrite of existing screens.

## 3. Proposed visual direction — “living atlas”

The recommended direction is a contemporary field journal combined with a living atlas:
- Map-led, editorial and calm; the real-world map remains visually dominant.
- Strong typography and generous but disciplined spacing.
- Surface hierarchy should distinguish map controls, previews, content and navigation without excessive cards.
- Use imagery as evidence of what a World contains, not decoration.
- Use subtle topographic/atlas cues only where they improve orientation; do not put decorative textures over map labels.
- Avoid generic social-app patterns: infinite feed, engagement counters, follower counts, floating reaction buttons and noisy gradients.

### Theme and tokens

Keep Material 3 and the existing ThemeData architecture. Create named semantic tokens rather than scattering hex values through widgets.

Proposed token roles (exact values require owner review):
- `canvas`: warm neutral background for non-map screens.
- `surface`: clean elevated content surface.
- `surfaceSubtle`: secondary panels and input backgrounds.
- `ink`: high-contrast primary text.
- `muted`: supporting text and metadata.
- `primary`: deep botanical green, building from the current placeholder seed if owner approves.
- `outline`: quiet separators and field borders.
- `danger`: destructive/error actions.
- `success`: completion and validated states.

Keep the existing category colors paired with icons and labels unless contrast testing shows a problem:
- Story: purple `#6A3FB5`
- Puzzle: amber `#B26A00`
- Art: magenta `#C2185B`
- Experience: teal `#00796B`

Color must never be the only category cue. Verify category colors in light/dark surfaces and map markers.

Typography:
- Use the platform/system sans family initially; no remote font dependency.
- Establish a small type scale for display, screen title, section title, body, supporting metadata and compact labels.
- Avoid using large display typography for ordinary card headings.
- Support Android system font scaling; never clip essential labels.

Shape and spacing:
- Use a consistent 4dp spacing base and a small named spacing scale.
- Use one consistent control height and corner-radius family.
- Prefer a few clear surfaces over nested Card-in-Card layouts.
- Tap targets should be at least 48dp wherever practical.

### Motion

Motion should communicate state, not entertain:
- Marker selection: short emphasis and preview reveal.
- Bottom-sheet transitions: one coherent motion, no stacked competing animations.
- Player block transition: calm directional transition; preserve reading position.
- Publish/completion: clear success feedback, no confetti by default.
- Respect Android reduced-motion/animation settings where available.
- Avoid long splash animations and animations that delay access to the map.

## 4. Navigation model

The current four destinations remain:
- **Explore:** discover Worlds. Default and primary destination.
- **Saved:** privately bookmarked Worlds.
- **Create:** creation entry point and drafts.
- **Profile:** account and creator identity.

Behavior:
- Preserve each tab's navigation state when switching tabs.
- Tapping the active tab returns to that tab's root, matching current behavior.
- Auth gates must preserve the requested destination and return after successful sign-in.
- Back navigation must not unexpectedly exit a nested creation/player flow.
- Do not add more bottom tabs for secondary tasks; use contextual routes or sheets.

## 5. Screen specifications

### 5.1 Explore (implemented; improve incrementally)

Layout:
1. Search field: title search, clear affordance and accessible label.
2. Foreground locate action: clearly separate from map gestures.
3. Map/list switch.
4. Horizontally scrollable category filters: All, Story, Puzzle, Art, Experience.
5. Map or accessible result list occupies remaining space.
6. Selected World preview overlays the lower map, above always-visible attribution.

Interactions:
- Initial camera uses configured pilot centre when available; otherwise show a zoomed-out world view. Do not silently infer or upload device location.
- Panning/zooming triggers a debounced nearby query after camera idle.
- Selecting a marker highlights it and shows a compact preview with title, category, creator and distance reference.
- Tapping empty map clears selection.
- Selecting a result from list returns to map and selects/centres the World.
- Locate requests a single foreground position only after the user taps. Explain the purpose before the Android permission prompt. Never enable continuous/background location.
- Search and category changes update real backend results; stale responses must not overwrite newer filters/search.
- Attribution must remain visible and unobstructed by cards or controls.

States:
- Initial/no area selected.
- Loading with previous results retained where safe.
- Results.
- No Worlds in the selected area.
- No results for current filters/search.
- Search/network error with retry.
- Permission denied (map remains usable).
- Permission permanently denied (Settings action).
- Device location services disabled.
- Location unavailable/timeout.
- Map SDK/tile failure (list/results should remain usable if data is available).
- No selected marker.

The current map device gate is still open: verify real tiles, labels, attribution, markers, camera gestures, permission explanation and location behavior on the owner's Android device before calling Explore visually complete.

### 5.2 World preview and details (preview exists; details are next)

Preview should answer: “What is this, who made it, and why might I care?” Keep it compact enough not to hide the map. It must not imply the user has unlocked the World.

World details page:
- Cover image or deliberate category fallback.
- Title, category, creator, concise description.
- Approximate distance and clear locked/unlocked state.
- Short content preview that does not leak puzzle answers or hidden branches.
- Primary action: “Go to location”, “Unlock”, “Start” or “Continue”, based on actual state.
- Secondary actions: Save, Share, Report.
- Show accessibility/safety context where the creator supplies it.
- Do not reveal a user's precise location or exact coordinates.

### 5.3 World player (future)

- Full-screen, reading-first content; keep app chrome minimal.
- Show World title and unobtrusive progress.
- Render only supported, versioned block types.
- One primary action per step; clear Back/Continue behavior.
- Story choices show only valid available branches.
- Puzzle answers are submitted to the server; the client never receives accepted answers.
- Preserve progress after each validated transition.
- Resume at the last server-confirmed block.
- Completion screen summarizes the experience and offers return-to-map/share actions.
- Locked/low-accuracy states explain what is required and provide retry; do not imply location spoofing detection.

### 5.4 Create entry and editor (entry placeholder exists; editor is future)

Creation should feel like composing a small experience, not filling a database form.

Recommended staged flow:
1. Choose category and see a one-sentence explanation/example.
2. Add title, short description and cover.
3. Choose location on map or use current location after an explicit tap.
4. Set unlock radius with a plain-language explanation.
5. Add content blocks using a constrained block picker.
6. Reorder and preview blocks as an explorer.
7. Save draft or publish after validation.

Editor requirements:
- Draft autosave or explicit save with clear unsaved-change state.
- Reorder controls accessible without drag-only interaction.
- Validate fields inline and preserve entered data on errors.
- Show the user how the experience will look before publish.
- Warn about public-place safety and trespassing before publish.
- Clearly distinguish Draft, Published, Hidden and Unpublished states.
- Upload progress, retry and orphan cleanup for images.
- Do not expose arbitrary HTML, scripts or untrusted external embeds.

### 5.5 Saved

- Signed-out: existing sign-in prompt.
- Signed-in empty state: explain that saved Worlds appear here and link back to Explore.
- Populated: compact list with cover/icon, title, category, creator and optional distance.
- Remove save with immediate UI feedback and reliable rollback on failure.
- Saved state is private to the account.

### 5.6 Profile

- Signed-out: existing sign-in prompt.
- Signed-in: avatar/initial, display name, username and optional bio.
- Edit profile with inline validation and save/cancel.
- Future creator section: own published Worlds and drafts, clearly separated.
- Sign-out requires no unnecessary confirmation but must handle pending requests.
- Do not show fabricated follower, reputation or activity metrics.

### 5.7 Authentication

- Sign-in and registration should be simple, keyboard-safe and accessible.
- Preserve return destination.
- Explain email confirmation accurately based on the live Supabase setting.
- Show field-level validation and mapped network/auth errors.
- Disable duplicate submissions while loading.
- Password visibility toggle and sensible autofill/keyboard configuration.
- Password reset is not currently implemented; do not display a nonfunctional link.

## 6. Responsive behavior and accessibility

- Target small Android phones first; support larger phones and tablets without stretching text into excessively wide lines.
- Respect safe areas, keyboard insets, display cutouts and system text scaling.
- All icon-only actions need tooltips/semantics.
- Provide a list alternative to map-only discovery.
- Announce loading/error updates with live-region semantics where appropriate.
- Keep text contrast WCAG AA target (4.5:1 normal text, 3:1 large text/UI boundaries).
- Do not use color alone for status/category.
- Ensure focus order and TalkBack labels are meaningful.
- Never rely on drag gestures as the only way to reorder or navigate.

## 7. UX quality gates

A screen is not done because it renders. It must:
- Explain its purpose without a tutorial.
- Have real actions for every enabled control.
- Cover loading, empty, error, permission and success states relevant to it.
- Preserve user input on recoverable failure.
- Work with keyboard and larger text.
- Avoid blocking the primary journey with unnecessary dialogs.
- Be manually reviewed on a physical Android device.
- Match the accepted design direction and current component tokens.

## 8. Decisions requiring owner review

Before a broad visual redesign, ask the owner to approve:
- The “living atlas / field journal” direction.
- Exact global palette and typography.
- Whether the map preview should remain an overlay card or become a draggable bottom sheet.
- Final app icon/brand mark and launch treatment.

Until then, implement the interaction and accessibility requirements while keeping the current Material 3 theme and avoiding speculative brand-heavy changes.
