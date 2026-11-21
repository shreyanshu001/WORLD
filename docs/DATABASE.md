# WORLDS — Database design

PostgreSQL + PostGIS. All schema changes must be committed migrations.

## Tables
- **profiles**: `id uuid PK references auth.users`, unique username, display_name, bio, avatar_path, created_at, updated_at. Expose only approved public fields; owner updates own profile.
  Implemented in Checkpoint 2 (`supabase/migrations/20261119190424_create_profiles.sql`):
  - username: 3–20 characters, `[a-z0-9_]`, stored lower-case, unique.
  - display_name: optional, trimmed, 1–50 characters. bio: optional, at most 280 characters.
  - Every column is public. Private data stays in `auth.users`.
  - Clients may update only `username`, `display_name` and `bio`, on their own row. `avatar_path` stays server-managed until storage ownership rules exist.
  - A trigger on `auth.users` creates the profile at sign-up. It uses the requested username if valid and free, otherwise a generated `user_` name; it never fails sign-up over the username.
- **worlds**: `id uuid PK`, creator_id FK, title, description, cover_asset_id, category check (story/puzzle/art/experience), `location geography(point,4326)`, unlock_radius_meters default 50 check 25–150, visibility public/unlisted, status draft/published/hidden/deleted, published_at, timestamps.
  Implemented in Checkpoint 3 (`supabase/migrations/20261120050626_create_worlds.sql`), read-only for clients so far:
  - `creator_id` references `profiles`. Title 3–80 characters, trimmed; description at most 2,000 (proposed limits, D-020). A published World must have `published_at`.
  - One select policy: published public Worlds for everyone, plus creators' own non-deleted Worlds. Unlisted Worlds are not readable yet (gap G1, Checkpoint 4).
  - `cover_asset_id` has no foreign key until `world_assets` exists (Checkpoint 4).
  Changed in Checkpoint 4 (`supabase/migrations/20261120090000_create_world_authoring.sql`): `location` may be empty while the World is a draft (or deleted); `cover_asset_id` references `world_assets`. Clients still cannot write the table; all changes go through the functions below.
- **world_assets**: id, world_id, owner_id, unique storage_path, mime_type, size_bytes, created_at.
  Implemented in Checkpoint 4. Paths are `<owner>/<world>/<asset>.<jpg|png|webp>` in the private `world-media` bucket (5 MB, JPEG/PNG/WebP). Readable by the owner, and by anyone for the cover of a published public World. Rows are created only by `register_world_asset`, after the stored object is checked.
  Changed in Checkpoint 5: an account that unlocked a published public World can also read the images its parts use (a second select policy that calls `is_unlocked_world_image`). Images no part uses stay with their owner.
- **world_content_blocks**: id, world_id, block_type, position, schema_version, content jsonb, timestamps; unique(world_id, position). Never put question answers in content.
  Implemented in Checkpoint 4. Position 0–29; schema version 1; the unique position constraint is deferred so a reorder can happen in one transaction. Readable by the World's creator only (D-024). Content keys are whitelisted per type by `save_world`, so an `answer` key is rejected.
- **world_question_secrets**: block_id PK/FK, answer_hash, normalization_version. No direct client SELECT; only trusted validation function can access.
  Implemented in Checkpoint 4 as `private.world_question_secrets`: in the schema the Data API does not expose, with row level security on and no policies or grants. bcrypt hash of the answer normalised by `private.normalize_answer` (version 1, D-026).
- **world_visits**: world_id, user_id, first/last visited timestamps, visit_count; composite PK.
  Implemented in Checkpoint 5 (`supabase/migrations/20261121051737_create_world_play.sql`): one row per account and World, counting successful on-site unlock checks. No positions are stored. Readable by its owner only; written only by `unlock_world`.
- **world_progress**: world_id, user_id, current_block_id, status in_progress/completed, validated progress jsonb, started_at/completed_at/updated_at; composite PK.
  Implemented in Checkpoint 5 with two validated arrays instead of one jsonb value: `path` (parts visited, at most 300) and `answered` (questions answered correctly), plus `completion_count`. Created by a successful unlock; changed only by the play functions; readable by its owner only; signed-out users have no access. Answer attempts live in `private.world_answer_attempts` for the attempt limit, with no API access.
- **saved_worlds**: world_id, user_id, created_at; composite PK.
  Implemented in Checkpoint 6 (`supabase/migrations/20261121060535_create_saved_reports_moderation.sql`). Readable by its owner only; written only by `set_world_saved`. Rules in D-034.
- **world_reports**: id, world_id, reporter_id, reason, description, status pending/reviewed/actioned/dismissed, created_at. Prevent duplicate pending reports per reporter/World.
  Implemented in Checkpoint 6, with `resolved_at`. A partial unique index allows one pending report per reporter and World. A reporter can read their own rows but not `status` or `resolved_at` (column grants); nobody else can read any. Written only by `report_world` and the moderation functions. `reporter_id` becomes null if the account is removed. Rules in D-035.
- **private.moderation_actions** (Checkpoint 6): one row per moderation action: World id and title, action (hide, restore, remove, dismiss_reports), who acted, why, status before and after, reports closed, time. No foreign key to the World, so the record outlives it. No API access.

## Indexes
GIST worlds.location; B-tree worlds(status,visibility,category); B-tree worlds(creator_id,created_at desc); unique world/position; primary keys for progress, visits and saves. Add others only with query-plan evidence.

## Nearby RPC
`get_nearby_worlds(user_lat,user_lon,radius_meters,category_filter,search_text,page_size,page_offset)`:

Implemented in Checkpoint 3 (`supabase/migrations/20261120050626_create_worlds.sql`). `limit` and `offset` became `page_size` and `page_offset` because they are SQL reserved words, and `search_text` was added for the MVP's title search (docs/DECISIONS.md, D-018). Clamps: radius 100–25,000 m (default 5,000), page size 1–100 (default 50), offset 0–1,000. Bad coordinates or an unknown category raise SQLSTATE 22023. Returns id, title, category, latitude, longitude, distance_meters, creator_username and creator_display_name. Callable signed out.

- Validate lat -90..90 and lon -180..180.
- Clamp radius and page size server-side.
- Build point with `ST_SetSRID(ST_MakePoint(user_lon,user_lat),4326)::geography`.
- Filter published + public only.
- Use `ST_DWithin`, return `ST_Distance`, order by distance.
- Return bounded safe preview fields; exclude drafts, hidden, deleted and unlisted.

## Publish RPC
Transactional operation verifies auth owner, required metadata/location, cover and asset ownership, block schema/size/count, story destinations in same World, at least one meaningful block and secret presence for question blocks. Then sets published status/time and returns safe public representation.

Implemented in Checkpoint 4 as a set of `security definer` functions, each checking `auth.uid()` itself and callable by signed-in users only:

| Function | Purpose |
| --- | --- |
| `save_world(world jsonb, question_answers jsonb)` | Creates or replaces the World and its whole block list in one transaction. App-chosen ids make retries safe; block ids belonging to another World are refused. Answers are hashed and never returned. A published World must stay publishable. 20 new Worlds per account per day. |
| `get_world_draft(world_id)` | The creator's editable copy: fields, blocks with `has_answer`, assets. |
| `publish_world(world_id)` | Publishes, or returns `problems` (codes such as `location_required`, `answer_required`, `choice_destination_invalid`) and changes nothing. Publishing again succeeds, so a retry is safe. |
| `unpublish_world(world_id)` | Back to draft; the publish date is kept ("Unpublished"). |
| `delete_world(world_id)` | Soft delete. |
| `register_world_asset(asset_id, world_id, storage_path)` | Records an uploaded file after checking owner, folder, declared type, extension and size. Repeatable. |
| `forget_world_asset(asset_id)` | Releases an unused asset and returns its path for deletion from storage. |
| `get_world_details(world_id, from_lat, from_lon)` | Callable signed out. Safe details of a published public World (or the caller's own): no blocks, only a count; distance computed by the server. |

Errors: 42501 not allowed (signed out, or hidden by moderation); P0002 not found, also for other people's Worlds; 22023 invalid content; WR429 a creation limit.

## Play RPCs
Implemented in Checkpoint 5, all `security definer`, signed-in users only (D-032), rules in D-033:

| Function | Purpose |
| --- | --- |
| `unlock_world(world_id, latitude, longitude, accuracy_meters)` | Checks one fresh reading: `unlocked` (creates progress, counts a visit), `too_far` or `inaccurate`. |
| `get_world_play(world_id)` | Parts in order without answers or success messages, the images they use, and progress. WR403 before unlocking. |
| `advance_world(world_id, from_block_id, option_id)` | One validated step; `stale` when the player had already moved on; completion counted once. |
| `answer_question(world_id, block_id, answer)` | Checks the normalised answer against the stored hash; five wrong per ten minutes, then `rate_limited`. Never returns the answer. |
| `restart_world(world_id)` | Back to the first part; questions must be answered again. |

`get_world_details` also returns `play_status` (`locked`, `in_progress`, `completed`; null when signed out).

`is_unlocked_world_image(asset_id)` answers whether the caller may see an image as a player: a part of a published public World they unlocked uses it. It exists for the `world_assets` policy, because players cannot read parts directly; it reveals only what `get_world_play` already lists for that caller. Storage objects follow `world_assets`, so signed image addresses work for exactly those images.

Errors: 42501 not signed in; P0002 not found, unpublished, hidden or deleted; WR403 not unlocked yet; 22023 an invalid step or position.

## Saved, report and profile RPCs
Implemented in Checkpoint 6, all `security definer`:

| Function | Purpose |
| --- | --- |
| `set_world_saved(world_id, saved)` | Signed-in only. Saves a published public World or removes any saved World; repeating either changes nothing. WR429 at 500 saved. |
| `get_saved_worlds(page_size, page_offset, from_lat, from_lon)` | Signed-in only. The caller's saved Worlds that are published now, newest save first, with `has_more` and the number that are `unavailable`. Page size 1 to 50 (default 20). |
| `report_world(world_id, reason, details)` | Signed-in only. Returns `already_reported` for a second report while the first is pending. 22023 for an unknown reason, long details or one's own World; P0002 if the World is not published; WR429 after ten reports in a day. |
| `get_profile_page(profile_username, page_size, page_offset)` | Callable signed out. Username, display name, bio, `published_count` and published Worlds, newest first. `draft_count`, `discovered_count` and `completed_count` are null unless the caller owns the profile. P0002 for an unknown username. |

`get_world_details` also returns `is_saved` (null when signed out).

## Moderation (no API)
Functions in the `private` schema, which the Data API does not expose and API roles cannot use. The project owner runs them in the SQL editor (D-036; runbook in `supabase/README.md`):

| Function | Effect |
| --- | --- |
| `private.moderation_queue()` | Pending reports, oldest first, with reason, details, reporter, World, its state and its creator. |
| `private.hide_world(world, moderator, note)` | Published or draft becomes hidden; pending reports become actioned. |
| `private.restore_world(world, moderator, note)` | Hidden becomes published if it was published when hidden and is still complete, otherwise a draft. |
| `private.remove_world(world, moderator, note)` | Soft delete; pending reports become actioned. |
| `private.dismiss_reports(world, moderator, note)` | Pending reports become dismissed; the World is untouched. |

Each needs a moderator name (2 to 80 characters) and a note (3 to 1,000) and writes one row to `private.moderation_actions`; without them nothing changes.

## Deletion and retention (as implemented, 2026-11-21)
What happens today. No retention periods have been decided; that is an open owner decision before public launch.

- **A creator deletes a World, or a moderator removes one:** soft delete. The row, its parts, its answer hashes, its image records and its files stay. It disappears from discovery, details, play, saved lists and profile pages, and its creator can no longer open it. Nothing restores it through the app.
- **A World is unpublished or hidden:** nothing is deleted. Players' progress, saves and reports of it stay and apply again if it comes back.
- **Images:** an image the creator replaces or removes from a World is released and its file deleted. Files of deleted Worlds, and files whose release failed, stay in storage; there is no clean-up job.
- **Saved Worlds:** a row is deleted when its owner removes it, and with the World or the account if either is ever hard-deleted.
- **Reports:** never deleted by the app. They keep their text and reason after the World is soft-deleted and after moderation closes them. If the reporter's account is removed the report stays without the reporter.
- **Moderation log:** never deleted, and kept even if the World's row is.
- **Play records:** progress, visits and answer attempts are kept indefinitely. No coordinates are stored.
- **Accounts:** the app has no "delete my account". Removing a user in the Supabase dashboard cascades through their profile to their Worlds (with parts, answers, image records, others' saves, progress and reports of those Worlds), their own saves, progress, visits and answer attempts. Their image files in storage are not removed by that cascade.

## RLS
Enable RLS on every exposed table:
- Profiles: safe public read; owner update.
- Worlds: public read published/public; creator manages own.
- Blocks: readable only if parent accessible; creator writes own. (Checkpoint 4: creator-only reads until the player exists, D-024; writes only through `save_world`.)
- Assets: owner-scoped writes; read only when referenced by accessible World. (Checkpoint 4: owner, plus the cover of a published public World; storage objects follow the same rule. Checkpoint 5: plus, for accounts that unlocked the World, the images its parts use while it is published.)
- Question secrets: no client access.
- Visits/progress/saves: user-scoped. (Checkpoint 5: visits and progress are readable by their owner only and written only by the play functions. Checkpoint 6: saves likewise, written only by `set_world_saved`.)
- Reports: authenticated insert; reporter reads own; trusted admin reads/modifies. (Checkpoint 6: inserted only through `report_world`; the reporter reads their own rows without the moderation status; there is no admin role in the API, moderation runs in the dashboard, D-036.)
Admin role comes from trusted process, never client-editable profile metadata.

## Important
This is the schema contract, not a substitute for SQL migrations, RLS policies, RPC implementation and tests. Do not trust arbitrary client progress JSON; validate transitions server-side. Normalize answer input consistently and test Unicode/case/whitespace behavior.
