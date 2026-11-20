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
- **world_assets**: id, world_id, owner_id, unique storage_path, mime_type, size_bytes, created_at.
- **world_content_blocks**: id, world_id, block_type, position, schema_version, content jsonb, timestamps; unique(world_id, position). Never put question answers in content.
- **world_question_secrets**: block_id PK/FK, answer_hash, normalization_version. No direct client SELECT; only trusted validation function can access.
- **world_visits**: world_id, user_id, first/last visited timestamps, visit_count; composite PK.
- **world_progress**: world_id, user_id, current_block_id, status in_progress/completed, validated progress jsonb, started_at/completed_at/updated_at; composite PK.
- **saved_worlds**: world_id, user_id, created_at; composite PK.
- **world_reports**: id, world_id, reporter_id, reason, description, status pending/reviewed/actioned/dismissed, created_at. Prevent duplicate pending reports per reporter/World.

## Indexes
GIST worlds.location; B-tree worlds(status,visibility,category); B-tree worlds(creator_id,created_at desc); unique world/position; primary keys for progress, visits and saves. Add others only with query-plan evidence.

## Nearby RPC
`get_nearby_worlds(user_lat,user_lon,radius_meters,category_filter,limit,offset)`:
- Validate lat -90..90 and lon -180..180.
- Clamp radius and page size server-side.
- Build point with `ST_SetSRID(ST_MakePoint(user_lon,user_lat),4326)::geography`.
- Filter published + public only.
- Use `ST_DWithin`, return `ST_Distance`, order by distance.
- Return bounded safe preview fields; exclude drafts, hidden, deleted and unlisted.

## Publish RPC
Transactional operation verifies auth owner, required metadata/location, cover and asset ownership, block schema/size/count, story destinations in same World, at least one meaningful block and secret presence for question blocks. Then sets published status/time and returns safe public representation.

## RLS
Enable RLS on every exposed table:
- Profiles: safe public read; owner update.
- Worlds: public read published/public; creator manages own.
- Blocks: readable only if parent accessible; creator writes own.
- Assets: owner-scoped writes; read only when referenced by accessible World.
- Question secrets: no client access.
- Visits/progress/saves: user-scoped.
- Reports: authenticated insert; reporter reads own; trusted admin reads/modifies.
Admin role comes from trusted process, never client-editable profile metadata.

## Important
This is the schema contract, not a substitute for SQL migrations, RLS policies, RPC implementation and tests. Do not trust arbitrary client progress JSON; validate transitions server-side. Normalize answer input consistently and test Unicode/case/whitespace behavior.
