-- World authoring (Checkpoint 4, docs/DATABASE.md): drafts, typed content
-- blocks, private puzzle answers, media assets and the publish lifecycle.
--
-- Clients never write these tables directly. Every change goes through the
-- functions at the end of this file, which check ownership against
-- auth.uid() and validate content.
--
-- Who can read what:
--   worlds                published public Worlds, plus creators' own (unchanged)
--   world_assets          owners, plus the cover of a published public World
--   world_content_blocks  creators only. Public reading arrives with the player
--                         in Checkpoint 5, so content stays behind the unlock step.
--   private.world_question_secrets  nobody; only these functions
--
-- Limits (docs/DECISIONS.md, D-023): 30 blocks per World; images of
-- at most 5 MB as JPEG, PNG or WebP; 40 images per World; 20 new Worlds per
-- account per day.

---------------------------------------------------------------------------
-- Drafts may be saved before a location is chosen.
---------------------------------------------------------------------------
alter table public.worlds alter column location drop not null;

alter table public.worlds
  add constraint worlds_location_required
  check (status in ('draft', 'deleted') or location is not null);

---------------------------------------------------------------------------
-- Media assets: one row per uploaded file, owned by one World.
---------------------------------------------------------------------------
create table public.world_assets (
  id uuid primary key,
  world_id uuid not null references public.worlds (id) on delete cascade,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  -- <owner_id>/<world_id>/<asset_id>.<jpg|png|webp> in the world-media bucket.
  storage_path text not null unique,
  mime_type text not null
    constraint world_assets_mime_type check (
      mime_type in ('image/jpeg', 'image/png', 'image/webp')
    ),
  size_bytes integer not null
    constraint world_assets_size check (size_bytes between 1 and 5242880),
  created_at timestamptz not null default now()
);

comment on table public.world_assets is
  'Uploaded images. Registered by register_world_asset after the file is in storage.';

create index world_assets_world_idx on public.world_assets (world_id);
create index world_assets_owner_idx on public.world_assets (owner_id);

alter table public.worlds
  add constraint worlds_cover_asset_fk
  foreign key (cover_asset_id) references public.world_assets (id) on delete set null;

create index worlds_cover_asset_idx on public.worlds (cover_asset_id);

alter table public.world_assets enable row level security;

revoke all on table public.world_assets from anon, authenticated;
grant select on table public.world_assets to anon, authenticated;

create policy "Owners, and anyone for covers of published public Worlds, read assets"
  on public.world_assets
  for select
  to anon, authenticated
  using (
    (select auth.uid()) = owner_id
    or exists (
      select 1
      from public.worlds as w
      where w.cover_asset_id = world_assets.id
        and w.status = 'published'
        and w.visibility = 'public'
    )
  );

---------------------------------------------------------------------------
-- Content blocks: an ordered list of typed, versioned blocks per World.
---------------------------------------------------------------------------
create table public.world_content_blocks (
  id uuid primary key,
  world_id uuid not null references public.worlds (id) on delete cascade,
  block_type text not null
    constraint world_content_blocks_type check (
      block_type in ('text', 'image', 'story_choice', 'question', 'artwork', 'completion')
    ),
  position integer not null
    constraint world_content_blocks_position_range check (position between 0 and 29),
  schema_version integer not null default 1
    constraint world_content_blocks_schema_version check (schema_version = 1),
  -- Validated by save_world. Never holds a question's answer.
  content jsonb not null
    constraint world_content_blocks_content_object check (jsonb_typeof(content) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Deferred so a reorder can move several blocks in one transaction.
  constraint world_content_blocks_position_unique
    unique (world_id, position) deferrable initially deferred
);

comment on table public.world_content_blocks is
  'Typed content of a World. Readable by its creator only until the player exists.';

alter table public.world_content_blocks enable row level security;

revoke all on table public.world_content_blocks from anon, authenticated;
grant select on table public.world_content_blocks to authenticated;

create policy "Creators read their own Worlds' blocks"
  on public.world_content_blocks
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.worlds as w
      where w.id = world_content_blocks.world_id
        and w.creator_id = (select auth.uid())
    )
  );

create trigger world_content_blocks_set_updated_at
  before update on public.world_content_blocks
  for each row
  execute function private.set_updated_at();

---------------------------------------------------------------------------
-- Puzzle answers. In the private schema, which the Data API does not expose,
-- with row level security on and no policies or grants: only the functions
-- below can touch it. Stored as a bcrypt hash of the normalised answer.
---------------------------------------------------------------------------
create table private.world_question_secrets (
  block_id uuid primary key
    references public.world_content_blocks (id) on delete cascade,
  answer_hash text not null,
  normalization_version smallint not null default 1,
  updated_at timestamptz not null default now()
);

alter table private.world_question_secrets enable row level security;
revoke all on table private.world_question_secrets from public, anon, authenticated;

-- Normalisation version 1: Unicode NFKC, lower case, whitespace runs collapsed
-- to one space, trimmed. Answer checking in Checkpoint 5 must use the same.
create function private.normalize_answer(answer text)
returns text
language sql
immutable
set search_path = ''
as $$
  select btrim(regexp_replace(lower(normalize(answer, nfkc)), '\s+', ' ', 'g'));
$$;

revoke all on function private.normalize_answer(text) from public;

---------------------------------------------------------------------------
-- Storage: a private bucket. Paths are <owner>/<world>/<asset>.<ext>.
-- The bucket limits size and declared type; register_world_asset checks the
-- stored object again before the app may use it.
---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'world-media',
  'world-media',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
);

create policy "World media: creators upload into their own World folders"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'world-media'
    and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png|webp)$'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (
      select 1
      from public.worlds as w
      where w.id::text = (storage.foldername(objects.name))[2]
        and w.creator_id = (select auth.uid())
        and w.status in ('draft', 'published')
    )
  );

-- world_assets' own policy decides which registered files others may see.
create policy "World media: owners, and readers of registered public files"
  on storage.objects
  for select
  to anon, authenticated
  using (
    bucket_id = 'world-media'
    and (
      owner_id = (select auth.uid())::text
      or exists (
        select 1 from public.world_assets as a where a.storage_path = objects.name
      )
    )
  );

-- A file can be deleted only after forget_world_asset has released it.
create policy "World media: owners delete files no World uses"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'world-media'
    and owner_id = (select auth.uid())::text
    and not exists (
      select 1 from public.world_assets as a where a.storage_path = objects.name
    )
  );

-- No update policy: stored files are never overwritten.

---------------------------------------------------------------------------
-- Validation helpers (private; called only by the functions below).
---------------------------------------------------------------------------

-- Rejects keys outside allowed and missing required keys.
create function private.check_keys(obj jsonb, allowed text[], required text[], label text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  extra text;
  missing text;
begin
  if obj is null or jsonb_typeof(obj) <> 'object' then
    raise exception '% must be an object', label using errcode = '22023';
  end if;
  select string_agg(k, ', ') into extra
  from jsonb_object_keys(obj) as k
  where k <> all (allowed);
  if extra is not null then
    raise exception '% has unsupported keys: %', label, extra using errcode = '22023';
  end if;
  select string_agg(k, ', ') into missing
  from unnest(required) as k
  where not obj ? k;
  if missing is not null then
    raise exception '% is missing keys: %', label, missing using errcode = '22023';
  end if;
end;
$$;

-- obj->key must be a string of at most max_length characters, or absent/null
-- when nullable.
create function private.check_text(obj jsonb, key text, max_length integer, nullable boolean, label text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  value jsonb := obj -> key;
begin
  if value is null or jsonb_typeof(value) = 'null' then
    if nullable then
      return;
    end if;
    raise exception '%.% is required', label, key using errcode = '22023';
  end if;
  if jsonb_typeof(value) <> 'string' then
    raise exception '%.% must be text', label, key using errcode = '22023';
  end if;
  if char_length(value #>> '{}') > max_length then
    raise exception '%.% is longer than % characters', label, key, max_length
      using errcode = '22023';
  end if;
end;
$$;

-- obj->key as a uuid, or null when absent/null. Raises on anything else.
create function private.uuid_or_null(obj jsonb, key text, label text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
declare
  value jsonb := obj -> key;
begin
  if value is null or jsonb_typeof(value) = 'null' then
    return null;
  end if;
  if jsonb_typeof(value) <> 'string'
     or (value #>> '{}') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception '%.% must be an id', label, key using errcode = '22023';
  end if;
  return (value #>> '{}')::uuid;
end;
$$;

-- Which block types each category may use (docs/PRODUCT_SPEC.md section 5).
create function private.block_allowed(category text, block_type text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case category
    when 'story' then block_type in ('text', 'image', 'story_choice', 'completion')
    when 'puzzle' then block_type in ('text', 'image', 'question', 'completion')
    when 'art' then block_type in ('artwork', 'text', 'image', 'completion')
    when 'experience' then true
    else false
  end;
$$;

-- Structural check of one block for a draft: known keys, types and maximum
-- lengths, and that any image belongs to this World and its creator. Blank
-- fields are allowed in drafts; publishing requires them (see below).
create function private.check_block_content(
  block_type text,
  content jsonb,
  world uuid,
  owner uuid,
  label text
)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare
  asset uuid;
  option jsonb;
  option_ids text[] := '{}';
  option_id uuid;
begin
  case block_type
    when 'text' then
      perform private.check_keys(content, array['body'], array['body'], label);
      perform private.check_text(content, 'body', 2000, false, label);
    when 'image' then
      perform private.check_keys(content, array['asset_id', 'caption'], array['asset_id'], label);
      perform private.check_text(content, 'caption', 200, true, label);
    when 'story_choice' then
      perform private.check_keys(content, array['prompt', 'options'], array['prompt', 'options'], label);
      perform private.check_text(content, 'prompt', 300, false, label);
      if jsonb_typeof(content -> 'options') <> 'array'
         or jsonb_array_length(content -> 'options') > 4 then
        raise exception '%.options must be a list of at most 4', label using errcode = '22023';
      end if;
      for option in select value from jsonb_array_elements(content -> 'options') loop
        perform private.check_keys(
          option,
          array['id', 'label', 'destination_block_id'],
          array['id', 'label', 'destination_block_id'],
          label || '.option'
        );
        perform private.check_text(option, 'label', 80, false, label || '.option');
        option_id := private.uuid_or_null(option, 'id', label || '.option');
        if option_id is null or option_id::text = any (option_ids) then
          raise exception '% has a missing or repeated option id', label using errcode = '22023';
        end if;
        option_ids := option_ids || option_id::text;
        perform private.uuid_or_null(option, 'destination_block_id', label || '.option');
      end loop;
    when 'question' then
      -- No answer key: answers travel separately and are stored as hashes.
      perform private.check_keys(content, array['prompt', 'hint', 'success_message'], array['prompt'], label);
      perform private.check_text(content, 'prompt', 500, false, label);
      perform private.check_text(content, 'hint', 300, true, label);
      perform private.check_text(content, 'success_message', 300, true, label);
    when 'artwork' then
      perform private.check_keys(
        content, array['asset_id', 'title', 'description'],
        array['asset_id', 'title', 'description'], label
      );
      perform private.check_text(content, 'title', 80, false, label);
      perform private.check_text(content, 'description', 2000, false, label);
    when 'completion' then
      perform private.check_keys(
        content, array['title', 'message', 'asset_id'], array['title', 'message'], label
      );
      perform private.check_text(content, 'title', 80, false, label);
      perform private.check_text(content, 'message', 1000, false, label);
    else
      raise exception '% has an unknown type', label using errcode = '22023';
  end case;

  asset := private.uuid_or_null(content, 'asset_id', label);
  if asset is not null and not exists (
    select 1
    from public.world_assets as a
    where a.id = asset and a.world_id = world and a.owner_id = owner
  ) then
    raise exception '% uses an image that is not part of this World', label
      using errcode = '22023';
  end if;
end;
$$;

-- Everything that stops a World from being published, as a JSON list of
-- {"code": ..., "block_id": ...}. An empty list means it can be published.
create function private.world_publish_problems(world uuid)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  w public.worlds%rowtype;
  problems jsonb := '[]'::jsonb;
  b record;
  option jsonb;
  destination_position integer;
  incomplete boolean;
  meaningful integer;
begin
  select * into w from public.worlds as x where x.id = world;

  if nullif(btrim(coalesce(w.description, '')), '') is null then
    problems := problems || jsonb_build_object('code', 'description_required');
  end if;
  if w.location is null then
    problems := problems || jsonb_build_object('code', 'location_required');
  end if;

  select count(*) into meaningful
  from public.world_content_blocks as x
  where x.world_id = world and x.block_type <> 'completion';
  if meaningful = 0 then
    problems := problems || jsonb_build_object('code', 'content_required');
  end if;

  if w.category = 'puzzle' and not exists (
    select 1 from public.world_content_blocks as x
    where x.world_id = world and x.block_type = 'question'
  ) then
    problems := problems || jsonb_build_object('code', 'question_required');
  end if;
  if w.category = 'art' and not exists (
    select 1 from public.world_content_blocks as x
    where x.world_id = world and x.block_type = 'artwork'
  ) then
    problems := problems || jsonb_build_object('code', 'artwork_required');
  end if;
  if w.category = 'story' and not exists (
    select 1 from public.world_content_blocks as x
    where x.world_id = world and x.block_type = 'text'
  ) then
    problems := problems || jsonb_build_object('code', 'text_required');
  end if;

  for b in
    select x.id, x.block_type, x.position, x.content
    from public.world_content_blocks as x
    where x.world_id = world
    order by x.position
  loop
    if not private.block_allowed(w.category, b.block_type) then
      problems := problems || jsonb_build_object('code', 'block_not_allowed', 'block_id', b.id);
      continue;
    end if;

    incomplete := case b.block_type
      when 'text' then nullif(btrim(coalesce(b.content ->> 'body', '')), '') is null
      when 'image' then b.content ->> 'asset_id' is null
      when 'story_choice' then
        nullif(btrim(coalesce(b.content ->> 'prompt', '')), '') is null
        or jsonb_array_length(b.content -> 'options') < 2
        or exists (
          select 1 from jsonb_array_elements(b.content -> 'options') as o
          where nullif(btrim(coalesce(o ->> 'label', '')), '') is null
             or o ->> 'destination_block_id' is null
        )
      when 'question' then nullif(btrim(coalesce(b.content ->> 'prompt', '')), '') is null
      when 'artwork' then
        b.content ->> 'asset_id' is null
        or nullif(btrim(coalesce(b.content ->> 'title', '')), '') is null
        or nullif(btrim(coalesce(b.content ->> 'description', '')), '') is null
      when 'completion' then
        nullif(btrim(coalesce(b.content ->> 'title', '')), '') is null
        or nullif(btrim(coalesce(b.content ->> 'message', '')), '') is null
      else true
    end;
    if incomplete then
      problems := problems || jsonb_build_object('code', 'block_incomplete', 'block_id', b.id);
    end if;

    if b.block_type = 'question' and not exists (
      select 1 from private.world_question_secrets as s where s.block_id = b.id
    ) then
      problems := problems || jsonb_build_object('code', 'answer_required', 'block_id', b.id);
    end if;

    -- A choice may only lead forward to a block of the same World, so every
    -- path moves towards an end and cannot loop.
    if b.block_type = 'story_choice' then
      for option in select value from jsonb_array_elements(b.content -> 'options') loop
        continue when option ->> 'destination_block_id' is null;
        select x.position into destination_position
        from public.world_content_blocks as x
        where x.world_id = world
          and x.id::text = option ->> 'destination_block_id';
        if destination_position is null or destination_position <= b.position then
          problems := problems || jsonb_build_object(
            'code', 'choice_destination_invalid', 'block_id', b.id
          );
          exit;
        end if;
      end loop;
    end if;
  end loop;

  return problems;
end;
$$;

revoke all on function private.check_keys(jsonb, text[], text[], text) from public;
revoke all on function private.check_text(jsonb, text, integer, boolean, text) from public;
revoke all on function private.uuid_or_null(jsonb, text, text) from public;
revoke all on function private.block_allowed(text, text) from public;
revoke all on function private.check_block_content(text, jsonb, uuid, uuid, text) from public;
revoke all on function private.world_publish_problems(uuid) from public;

---------------------------------------------------------------------------
-- Creator API. Each function is security definer, checks auth.uid() itself
-- and is callable by signed-in users only.
--
-- Errors: 42501 not allowed (signed out, or a World hidden by moderation);
-- P0002 not found (also used for other people's Worlds, so ids do not leak);
-- 22023 invalid content; WR429 a creation limit was reached.
---------------------------------------------------------------------------

-- The creator's full editable copy of a World.
create function public.get_world_draft(world_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  w public.worlds%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into w
  from public.worlds as x
  where x.id = target and x.creator_id = uid and x.status <> 'deleted';
  if not found then
    raise exception 'World not found' using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'id', w.id,
    'category', w.category,
    'title', w.title,
    'description', w.description,
    'cover_asset_id', w.cover_asset_id,
    'latitude', extensions.st_y(w.location::extensions.geometry),
    'longitude', extensions.st_x(w.location::extensions.geometry),
    'unlock_radius_meters', w.unlock_radius_meters,
    'status', w.status,
    'published_at', w.published_at,
    'updated_at', w.updated_at,
    'blocks', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', b.id,
          'block_type', b.block_type,
          'schema_version', b.schema_version,
          'content', b.content,
          'has_answer', b.block_type = 'question' and exists (
            select 1 from private.world_question_secrets as s where s.block_id = b.id
          )
        )
        order by b.position
      )
      from public.world_content_blocks as b
      where b.world_id = target
    ), '[]'::jsonb),
    'assets', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'storage_path', a.storage_path,
          'mime_type', a.mime_type
        )
        order by a.created_at, a.id
      )
      from public.world_assets as a
      where a.world_id = target
    ), '[]'::jsonb)
  );
end;
$$;

-- Creates or replaces a World and its whole block list in one transaction.
-- The client chooses the World and block ids, so retrying after a timeout
-- updates the same rows instead of creating duplicates.
--
-- world: {id, category, title, description, cover_asset_id, latitude,
--         longitude, unlock_radius_meters, blocks: [{id, block_type, content}]}
-- question_answers: {<question block id>: <answer>} for answers to set or
--         replace. Answers are hashed here and never returned.
--
-- A published World stays published only if it still passes publishing
-- validation; otherwise nothing is saved.
create function public.save_world(world jsonb, question_answers jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  w_id uuid;
  w_category text;
  w_title text;
  w_description text;
  w_cover uuid;
  w_radius integer;
  w_location extensions.geography;
  lat_value jsonb;
  lon_value jsonb;
  blocks jsonb;
  existing public.worlds%rowtype;
  block jsonb;
  block_type text;
  block_id uuid;
  block_ids uuid[] := '{}';
  question_ids uuid[] := '{}';
  label text;
  block_index integer := 0;
  option jsonb;
  destination uuid;
  answer_key text;
  answer_value jsonb;
  normalized text;
  problems jsonb;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  perform private.check_keys(
    world,
    array['id', 'category', 'title', 'description', 'cover_asset_id', 'latitude',
          'longitude', 'unlock_radius_meters', 'blocks'],
    array['id', 'category', 'title', 'blocks'],
    'world'
  );

  w_id := private.uuid_or_null(world, 'id', 'world');
  if w_id is null then
    raise exception 'world.id is required' using errcode = '22023';
  end if;

  w_category := world ->> 'category';
  if w_category is null or w_category not in ('story', 'puzzle', 'art', 'experience') then
    raise exception 'world.category is invalid' using errcode = '22023';
  end if;

  perform private.check_text(world, 'title', 80, false, 'world');
  w_title := world ->> 'title';
  perform private.check_text(world, 'description', 2000, true, 'world');
  w_description := nullif(btrim(coalesce(world ->> 'description', '')), '');
  w_cover := private.uuid_or_null(world, 'cover_asset_id', 'world');

  lat_value := world -> 'latitude';
  lon_value := world -> 'longitude';
  if coalesce(jsonb_typeof(lat_value), 'null') = 'null'
     and coalesce(jsonb_typeof(lon_value), 'null') = 'null' then
    w_location := null;
  elsif jsonb_typeof(lat_value) = 'number' and jsonb_typeof(lon_value) = 'number'
        and (lat_value #>> '{}')::double precision between -90 and 90
        and (lon_value #>> '{}')::double precision between -180 and 180 then
    -- Longitude first, latitude second.
    w_location := extensions.st_setsrid(
      extensions.st_makepoint(
        (lon_value #>> '{}')::double precision,
        (lat_value #>> '{}')::double precision
      ),
      4326
    )::extensions.geography;
  else
    raise exception 'world location is invalid' using errcode = '22023';
  end if;

  if coalesce(jsonb_typeof(world -> 'unlock_radius_meters'), 'null') = 'null' then
    w_radius := 50;
  elsif jsonb_typeof(world -> 'unlock_radius_meters') = 'number'
        and (world ->> 'unlock_radius_meters') ~ '^[0-9]+$' then
    w_radius := (world ->> 'unlock_radius_meters')::integer;
  else
    raise exception 'world.unlock_radius_meters is invalid' using errcode = '22023';
  end if;

  blocks := world -> 'blocks';
  if jsonb_typeof(blocks) <> 'array' or jsonb_array_length(blocks) > 30 then
    raise exception 'world.blocks must be a list of at most 30' using errcode = '22023';
  end if;

  -- The World row: create it, or update it if it is the caller's.
  select * into existing from public.worlds as x where x.id = w_id for update;
  if found then
    if existing.creator_id <> uid or existing.status = 'deleted' then
      raise exception 'World not found' using errcode = 'P0002';
    end if;
    if existing.status = 'hidden' then
      raise exception 'World is hidden by moderation' using errcode = '42501';
    end if;
  else
    if (
      select count(*) from public.worlds as x
      where x.creator_id = uid and x.created_at > now() - interval '1 day'
    ) >= 20 then
      raise exception 'Daily World creation limit reached' using errcode = 'WR429';
    end if;
    if w_cover is not null then
      raise exception 'A new World cannot have a cover yet' using errcode = '22023';
    end if;
    insert into public.worlds (id, creator_id, title, description, category, location,
                               unlock_radius_meters, status)
    values (w_id, uid, w_title, w_description, w_category, w_location, w_radius, 'draft');
  end if;

  if w_cover is not null and not exists (
    select 1 from public.world_assets as a
    where a.id = w_cover and a.world_id = w_id and a.owner_id = uid
  ) then
    raise exception 'The cover is not part of this World' using errcode = '22023';
  end if;

  if existing.id is not null then
    update public.worlds as x
    set title = w_title,
        description = w_description,
        category = w_category,
        cover_asset_id = w_cover,
        location = w_location,
        unlock_radius_meters = w_radius
    where x.id = w_id;
  end if;

  -- Blocks: validate all, then replace the stored list with exactly these.
  for block in select value from jsonb_array_elements(blocks) loop
    label := 'block ' || (block_index + 1);
    perform private.check_keys(
      block, array['id', 'block_type', 'schema_version', 'content'],
      array['id', 'block_type', 'content'], label
    );
    block_id := private.uuid_or_null(block, 'id', label);
    if block_id is null or block_id = any (block_ids) then
      raise exception '% has a missing or repeated id', label using errcode = '22023';
    end if;
    if coalesce(block ->> 'schema_version', '1') <> '1' then
      raise exception '% has an unsupported schema version', label using errcode = '22023';
    end if;
    block_type := block ->> 'block_type';
    if block_type is null or not private.block_allowed(w_category, block_type) then
      raise exception '% type is not allowed in this category', label using errcode = '22023';
    end if;
    perform private.check_block_content(block_type, block -> 'content', w_id, uid, label);
    block_ids := block_ids || block_id;
    if block_type = 'question' then
      question_ids := question_ids || block_id;
    end if;
    block_index := block_index + 1;
  end loop;

  -- Story choices may point only at blocks in this list.
  for block in select value from jsonb_array_elements(blocks) loop
    continue when block ->> 'block_type' <> 'story_choice';
    for option in select value from jsonb_array_elements(block -> 'content' -> 'options') loop
      destination := private.uuid_or_null(option, 'destination_block_id', 'option');
      if destination is not null and destination <> all (block_ids) then
        raise exception 'A choice leads to a block outside this World' using errcode = '22023';
      end if;
    end loop;
  end loop;

  -- Block ids are chosen by the client, so refuse ids that belong elsewhere.
  if exists (
    select 1 from public.world_content_blocks as x
    where x.id = any (block_ids) and x.world_id <> w_id
  ) then
    raise exception 'A block id belongs to another World' using errcode = '22023';
  end if;

  delete from public.world_content_blocks as x
  where x.world_id = w_id and x.id <> all (block_ids);

  block_index := 0;
  for block in select value from jsonb_array_elements(blocks) loop
    insert into public.world_content_blocks (id, world_id, block_type, position, schema_version, content)
    values (
      (block ->> 'id')::uuid,
      w_id,
      block ->> 'block_type',
      block_index,
      1,
      block -> 'content'
    )
    on conflict on constraint world_content_blocks_pkey do update
    set block_type = excluded.block_type,
        position = excluded.position,
        schema_version = excluded.schema_version,
        content = excluded.content;
    block_index := block_index + 1;
  end loop;

  -- A block that stopped being a question loses its answer.
  delete from private.world_question_secrets as s
  using public.world_content_blocks as x
  where s.block_id = x.id and x.world_id = w_id and x.block_type <> 'question';

  -- New or replaced answers.
  if question_answers is not null and jsonb_typeof(question_answers) <> 'object' then
    raise exception 'question_answers must be an object' using errcode = '22023';
  end if;
  for answer_key, answer_value in
    select key, value from jsonb_each(coalesce(question_answers, '{}'::jsonb))
  loop
    if answer_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or answer_key::uuid <> all (question_ids) then
      raise exception 'An answer is for a block that is not a question here' using errcode = '22023';
    end if;
    if jsonb_typeof(answer_value) <> 'string' then
      raise exception 'Answers must be text' using errcode = '22023';
    end if;
    normalized := private.normalize_answer(answer_value #>> '{}');
    if char_length(normalized) not between 1 and 100 then
      raise exception 'Answers must be 1 to 100 characters' using errcode = '22023';
    end if;
    insert into private.world_question_secrets (block_id, answer_hash, normalization_version)
    values (answer_key::uuid, extensions.crypt(normalized, extensions.gen_salt('bf', 8)), 1)
    on conflict on constraint world_question_secrets_pkey do update
    set answer_hash = excluded.answer_hash,
        normalization_version = excluded.normalization_version,
        updated_at = now();
  end loop;

  -- A live World must stay publishable.
  if existing.status = 'published' then
    problems := private.world_publish_problems(w_id);
    if jsonb_array_length(problems) > 0 then
      raise exception 'A published World must stay complete'
        using errcode = '22023', detail = problems::text;
    end if;
  end if;

  return public.get_world_draft(w_id);
end;
$$;

-- Publishes a draft after checking everything, or returns the problems and
-- changes nothing. Publishing an already published World succeeds again, so
-- a retry after a timeout is safe.
-- Returns {"status", "published_at", "problems": [...]}.
create function public.publish_world(world_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  w public.worlds%rowtype;
  problems jsonb;
  stamp timestamptz;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into w from public.worlds as x where x.id = target for update;
  if not found or w.creator_id <> uid or w.status = 'deleted' then
    raise exception 'World not found' using errcode = 'P0002';
  end if;
  if w.status = 'hidden' then
    raise exception 'World is hidden by moderation' using errcode = '42501';
  end if;
  if w.status = 'published' then
    return jsonb_build_object(
      'status', w.status, 'published_at', w.published_at, 'problems', '[]'::jsonb
    );
  end if;

  problems := private.world_publish_problems(target);
  if jsonb_array_length(problems) > 0 then
    return jsonb_build_object(
      'status', w.status, 'published_at', w.published_at, 'problems', problems
    );
  end if;

  update public.worlds as x
  set status = 'published', published_at = now()
  where x.id = target
  returning x.published_at into stamp;

  return jsonb_build_object('status', 'published', 'published_at', stamp, 'problems', '[]'::jsonb);
end;
$$;

-- Removes a World from discovery and returns it to draft. Its publish date
-- is kept, which is how the app tells "unpublished" from "never published".
-- Unpublishing a draft succeeds without changes.
create function public.unpublish_world(world_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  w public.worlds%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into w from public.worlds as x where x.id = target for update;
  if not found or w.creator_id <> uid or w.status = 'deleted' then
    raise exception 'World not found' using errcode = 'P0002';
  end if;
  if w.status = 'hidden' then
    raise exception 'World is hidden by moderation' using errcode = '42501';
  end if;

  if w.status = 'published' then
    update public.worlds as x set status = 'draft' where x.id = target;
  end if;

  return jsonb_build_object('status', 'draft', 'published_at', w.published_at);
end;
$$;

-- Soft delete: the World disappears for everyone, including its creator.
-- Its files stay in storage until a retention policy exists.
create function public.delete_world(world_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  w public.worlds%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into w from public.worlds as x where x.id = target for update;
  if not found or w.creator_id <> uid or w.status = 'deleted' then
    raise exception 'World not found' using errcode = 'P0002';
  end if;
  if w.status = 'hidden' then
    raise exception 'World is hidden by moderation' using errcode = '42501';
  end if;

  update public.worlds as x set status = 'deleted' where x.id = target;
end;
$$;

-- Records a file the creator has uploaded to world-media, after checking
-- that the stored object is theirs, in this World's folder, an allowed image
-- type and within the size limit. Repeating the call returns the same asset.
create function public.register_world_asset(asset_id uuid, world_id uuid, storage_path text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target_asset uuid := asset_id;
  target_world uuid := world_id;
  target_path text := storage_path;
  existing public.world_assets%rowtype;
  object_mime text;
  object_size bigint;
  expected_mime text;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  perform 1 from public.worlds as x
  where x.id = target_world and x.creator_id = uid and x.status in ('draft', 'published');
  if not found then
    raise exception 'World not found' using errcode = 'P0002';
  end if;

  if target_asset is null or target_path is null
     or target_path !~ ('^' || uid::text || '/' || target_world::text || '/'
                        || target_asset::text || '\.(jpg|png|webp)$') then
    raise exception 'The file path does not match this asset' using errcode = '22023';
  end if;

  select * into existing from public.world_assets as a where a.id = target_asset;
  if found then
    if existing.owner_id = uid and existing.world_id = target_world
       and existing.storage_path = target_path then
      return jsonb_build_object(
        'id', existing.id, 'storage_path', existing.storage_path,
        'mime_type', existing.mime_type
      );
    end if;
    raise exception 'Asset id already in use' using errcode = '22023';
  end if;

  if (select count(*) from public.world_assets as a where a.world_id = target_world) >= 40 then
    raise exception 'This World has reached its image limit' using errcode = 'WR429';
  end if;

  select o.metadata ->> 'mimetype', (o.metadata ->> 'size')::bigint
  into object_mime, object_size
  from storage.objects as o
  where o.bucket_id = 'world-media' and o.name = target_path and o.owner_id = uid::text;
  if not found then
    raise exception 'Uploaded file not found' using errcode = 'P0002';
  end if;

  expected_mime := case substring(target_path from '\.([a-z]+)$')
    when 'jpg' then 'image/jpeg'
    when 'png' then 'image/png'
    when 'webp' then 'image/webp'
  end;
  if object_mime is distinct from expected_mime
     or object_size is null or object_size not between 1 and 5242880 then
    raise exception 'The file is not an allowed image' using errcode = '22023';
  end if;

  insert into public.world_assets (id, world_id, owner_id, storage_path, mime_type, size_bytes)
  values (target_asset, target_world, uid, target_path, object_mime, object_size);

  return jsonb_build_object(
    'id', target_asset, 'storage_path', target_path, 'mime_type', object_mime
  );
end;
$$;

-- Releases an asset the World no longer uses and returns its storage path,
-- which the app then deletes from storage.
create function public.forget_world_asset(asset_id uuid)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := asset_id;
  asset public.world_assets%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into asset from public.world_assets as a
  where a.id = target and a.owner_id = uid
  for update;
  if not found then
    raise exception 'Asset not found' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.worlds as x
    where x.id = asset.world_id and x.status = 'hidden'
  ) then
    raise exception 'World is hidden by moderation' using errcode = '42501';
  end if;

  if exists (select 1 from public.worlds as x where x.cover_asset_id = target)
     or exists (
       select 1 from public.world_content_blocks as b
       where b.world_id = asset.world_id and b.content ->> 'asset_id' = target::text
     ) then
    raise exception 'The asset is still in use' using errcode = '22023';
  end if;

  delete from public.world_assets as a where a.id = target;
  return asset.storage_path;
end;
$$;

---------------------------------------------------------------------------
-- Public API.
---------------------------------------------------------------------------

-- Safe details of one World: a published public World for anyone, or the
-- caller's own World in any state except deleted. Content blocks are not
-- included, only how many there are. Distance is computed here when the
-- caller passes a position.
create function public.get_world_details(
  world_id uuid,
  from_lat double precision default null,
  from_lon double precision default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  origin extensions.geography;
  w public.worlds%rowtype;
  creator public.profiles%rowtype;
begin
  if (from_lat is null) <> (from_lon is null)
     or from_lat < -90 or from_lat > 90
     or from_lon < -180 or from_lon > 180 then
    raise exception 'Invalid coordinates' using errcode = '22023';
  end if;
  if from_lat is not null then
    origin := extensions.st_setsrid(
      extensions.st_makepoint(from_lon, from_lat), 4326
    )::extensions.geography;
  end if;

  select * into w
  from public.worlds as x
  where x.id = target
    and (
      (x.status = 'published' and x.visibility = 'public')
      or (uid is not null and x.creator_id = uid and x.status <> 'deleted')
    );
  if not found then
    raise exception 'World not found' using errcode = 'P0002';
  end if;

  select * into creator from public.profiles as p where p.id = w.creator_id;

  return jsonb_build_object(
    'id', w.id,
    'title', w.title,
    'description', w.description,
    'category', w.category,
    'unlock_radius_meters', w.unlock_radius_meters,
    'latitude', extensions.st_y(w.location::extensions.geometry),
    'longitude', extensions.st_x(w.location::extensions.geometry),
    'distance_meters', case
      when origin is not null and w.location is not null
        then extensions.st_distance(w.location, origin)
    end,
    'creator_username', creator.username,
    'creator_display_name', creator.display_name,
    'cover_path', (
      select a.storage_path from public.world_assets as a where a.id = w.cover_asset_id
    ),
    'block_count', (
      select count(*) from public.world_content_blocks as b where b.world_id = w.id
    ),
    'status', w.status,
    'published_at', w.published_at,
    'is_creator', uid is not null and w.creator_id = uid
  );
end;
$$;

---------------------------------------------------------------------------
-- Grants: creator functions for signed-in users; details for everyone.
---------------------------------------------------------------------------
revoke all on function public.get_world_draft(uuid) from public, anon, authenticated;
revoke all on function public.save_world(jsonb, jsonb) from public, anon, authenticated;
revoke all on function public.publish_world(uuid) from public, anon, authenticated;
revoke all on function public.unpublish_world(uuid) from public, anon, authenticated;
revoke all on function public.delete_world(uuid) from public, anon, authenticated;
revoke all on function public.register_world_asset(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.forget_world_asset(uuid) from public, anon, authenticated;
revoke all on function public.get_world_details(uuid, double precision, double precision)
  from public, anon, authenticated;

grant execute on function public.get_world_draft(uuid) to authenticated;
grant execute on function public.save_world(jsonb, jsonb) to authenticated;
grant execute on function public.publish_world(uuid) to authenticated;
grant execute on function public.unpublish_world(uuid) to authenticated;
grant execute on function public.delete_world(uuid) to authenticated;
grant execute on function public.register_world_asset(uuid, uuid, text) to authenticated;
grant execute on function public.forget_world_asset(uuid) to authenticated;
grant execute on function public.get_world_details(uuid, double precision, double precision)
  to anon, authenticated;
