# WORLDS — Product specification

**Version:** 1.0 · **Status:** Approved product direction; technical choices remain subject to audit.

## 1. Product definition
WORLDS lets people create and discover digital experiences attached to real-world places. A World is a structured user-created experience associated with a geographic point and a proximity rule. The map is the primary discovery surface. People can preview a World remotely, visit its location, unlock it and experience its content.

WORLDS is not initially an AR platform, generic social network, map clone or chatbot wrapper.

**Promise:** “Discover what people have created in the places around you.”

## 2. Users and outcomes
- **Explorer:** finds an interesting nearby World and completes a first experience without confusion.
- **Creator:** publishes a meaningful story, puzzle, artwork or experience without technical skills.
- **Contributor:** collaborative authoring is a possible later capability, not MVP.

## 3. MVP scope
Included:
- Public map discovery, title search and category filters.
- World preview and details.
- Foreground location permission and proximity eligibility.
- Four categories: Story, Puzzle, Art and Experience.
- Structured content-block editor; draft, preview, publish, edit and unpublish.
- Experience player and persisted progress.
- Profiles, saved Worlds, reporting and a basic manual moderation path.
- Privacy-conscious product analytics.

Excluded: AR/3D/spatial anchors, AI generation, chat/comments/followers/feed, payments, background GPS, leaderboards, offline map downloads and web authoring.

## 4. World model
A World has an ID, creator, title, description, cover, category (`story | puzzle | art | experience`), public geographic point, unlock radius (default 50m; creator range 25–150m), status (`draft | published | hidden | deleted`), visibility (`public | unlisted`), ordered content blocks and timestamps.

Public is default. Unlisted Worlds are accessible by direct link but excluded from map discovery. Draft, hidden and deleted Worlds are never publicly discoverable.

## 5. Content block contract
Finite, versioned block types only; never arbitrary executable content:
- `text`: required bounded text.
- `image`: asset ID and optional caption; use storage object key, not arbitrary URL.
- `story_choice`: prompt and 2–4 options, each with stable option ID and destination block ID. Destinations must belong to same World.
- `question`: public prompt, optional hint and success message. Accepted answer stored separately in a private structure.
- `artwork`: asset ID, title and description.
- `completion`: title, message and optional asset ID.

Every block has UUID, type, position, schema version and validated payload. Bound text, media, block count and payload sizes. No HTML, scripts or arbitrary external URLs.

## 6. Explorer journey
1. Open app; skip or complete brief onboarding.
2. Explore map without mandatory account.
3. Request foreground location only when user chooses locate/unlock.
4. Browse published Worlds, filter and select a marker.
5. Preview details remotely; travel to location.
6. Request a fresh location sample and attempt unlock.
7. Start, progress through blocks, pause/resume and complete.

## 7. Creator journey
1. Tap Create; authenticate.
2. Choose category/template.
3. Enter title, description and cover.
4. Pick a public location on map or use current location.
5. Set unlock radius.
6. Add/reorder typed blocks.
7. Preview as explorer.
8. Save draft or publish.
9. See published World on Explore.

Creator can edit only their own Worlds. Publishing is atomic and server-validated. Unpublish removes it from public discovery. Deletion is soft-delete.

## 8. Screens
- **App shell:** Explore, Saved, Create, Profile.
- **Explore:** full-screen map, search, category chips, recenter, markers, selected-marker preview, map/list switch and permission/empty/error states.
- **World details:** cover, title, description, category, creator, approximate distance, unlock status, preview, save/share/report and start/continue CTA.
- **Player:** one block at a time, progress, navigation, branching, answer submission, resume and completion.
- **Create:** category, details, location picker, radius, block editor, reorder, preview, draft and publish.
- **Saved:** saved list, empty state, remove.
- **Profile:** public fields, created/discovered/completed counts, own Worlds, settings and sign out.

## 9. Discovery and proximity
Default discovery radius 5km; category optional; distance sorting; bounded pagination. Server returns only published public Worlds. Do not expose exact user location.

Unlock radius defaults to 50m; creator chooses 25–150m. Request foreground permission only when needed. Approximate location may browse but may be insufficient to unlock. Recheck a fresh sample on unlock and show uncertainty/retry. GPS can be inaccurate or spoofed; it is a lightweight experience gate, not proof of presence. Remote previews remain available.

## 10. Safety and moderation
Only place experiences where visitors can lawfully and safely access them. Do not encourage trespassing, restricted access or unsafe travel. Provide reporting, rate limits and admin hide/unpublish. Do not seed private residences, schools or sensitive facilities. Never display live user locations.

## 11. Product events and pilot
Events: `explore_opened`, `world_marker_selected`, `world_details_opened`, `world_unlock_attempted`, `world_started`, `world_completed`, `world_saved`, `world_created`, `world_published`, `world_shared`, `world_reported`. No continuous location trails.

Pilot: one compact walkable area, 15–20 curated Worlds across categories, 30–100 testers. Measure map-to-details, details-to-start, start-to-completion, second-World discovery, creator activation/repeat publishing and 7-day return. Downloads alone are not success; independent creation and repeat discovery are stronger signals.
