-- World play (Checkpoint 5, docs/DATABASE.md): unlocking on site, playing,
-- puzzle answers checked here, and progress that survives restarts.
--
-- An account is needed to unlock and play (docs/DECISIONS.md, D-032);
-- browsing and details stay public. Clients cannot write these tables:
-- every change goes through the functions below, which validate each step.
--
-- Rules (D-033):
--   Unlock: a fresh position with accuracy of 100 m or better, within the
--     World's radius plus up to 25 m of reported uncertainty. Once unlocked,
--     a World stays unlocked for that account while it is published.
--   Answers: 5 wrong attempts per question in 10 minutes, then a pause.
--   Content is served only to accounts that unlocked the World, without
--     answers and without success messages, which come with a correct answer.

---------------------------------------------------------------------------
-- Tables
---------------------------------------------------------------------------
create table public.world_progress (
  world_id uuid not null references public.worlds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  current_block_id uuid references public.world_content_blocks (id) on delete set null,
  status text not null default 'in_progress'
    constraint world_progress_status check (status in ('in_progress', 'completed')),
  -- Validated by the functions below: parts visited in order, and questions
  -- answered correctly.
  path uuid[] not null default '{}'
    constraint world_progress_path_length check (cardinality(path) <= 300),
  answered uuid[] not null default '{}',
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  completion_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (world_id, user_id)
);

comment on table public.world_progress is
  'One row per account and unlocked World. Written only by the play functions.';

create index world_progress_user_idx on public.world_progress (user_id, updated_at desc);
create index world_progress_block_idx on public.world_progress (current_block_id);

create table public.world_visits (
  world_id uuid not null references public.worlds (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  first_visited_at timestamptz not null default now(),
  last_visited_at timestamptz not null default now(),
  visit_count integer not null default 1,
  primary key (world_id, user_id)
);

comment on table public.world_visits is
  'Successful on-site unlock checks per account. No positions are stored.';

create index world_visits_user_idx on public.world_visits (user_id);

alter table public.world_progress enable row level security;
alter table public.world_visits enable row level security;

revoke all on table public.world_progress from anon, authenticated;
revoke all on table public.world_visits from anon, authenticated;
grant select on table public.world_progress to authenticated;
grant select on table public.world_visits to authenticated;

create policy "Users read their own progress"
  on public.world_progress for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users read their own visits"
  on public.world_visits for select to authenticated
  using ((select auth.uid()) = user_id);

create trigger world_progress_set_updated_at
  before update on public.world_progress
  for each row
  execute function private.set_updated_at();

-- Answer attempts, for the attempt limit. Private: no API access at all.
create table private.world_answer_attempts (
  id bigint generated always as identity primary key,
  block_id uuid not null references public.world_content_blocks (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  correct boolean not null,
  attempted_at timestamptz not null default now()
);

create index world_answer_attempts_lookup_idx
  on private.world_answer_attempts (user_id, block_id, attempted_at desc);
create index world_answer_attempts_block_idx on private.world_answer_attempts (block_id);

alter table private.world_answer_attempts enable row level security;
revoke all on table private.world_answer_attempts from public, anon, authenticated;

---------------------------------------------------------------------------
-- Players can see the images that the parts of a World they unlocked use,
-- while that World is published. Covers of published Worlds are already
-- public; an image no part uses stays with its owner.
--
-- Players cannot read parts themselves, so this check runs with the
-- owner's rights. It tells a caller only whether they may see an image that
-- get_world_play already lists for them.
---------------------------------------------------------------------------
create function public.is_unlocked_world_image(asset_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.world_assets as a
    join public.worlds as w on w.id = a.world_id
    join public.world_progress as p on p.world_id = w.id
    where a.id = $1
      and p.user_id = (select auth.uid())
      and w.status = 'published'
      and w.visibility = 'public'
      and exists (
        select 1
        from public.world_content_blocks as b
        where b.world_id = w.id
          and b.content ->> 'asset_id' = a.id::text
      )
  );
$$;

revoke all on function public.is_unlocked_world_image(uuid) from public, anon, authenticated;
grant execute on function public.is_unlocked_world_image(uuid) to authenticated;

create policy "Players read the images used by Worlds they unlocked"
  on public.world_assets
  for select
  to authenticated
  using (public.is_unlocked_world_image(id));

---------------------------------------------------------------------------
-- Helpers (private)
---------------------------------------------------------------------------
create function private.first_block(world uuid)
returns uuid
language sql
stable
set search_path = ''
as $$
  select b.id from public.world_content_blocks as b
  where b.world_id = world
  order by b.position
  limit 1;
$$;

create function private.progress_json(world uuid, player uuid)
returns jsonb
language sql
stable
set search_path = ''
as $$
  select jsonb_build_object(
    'status', p.status,
    'current_block_id', p.current_block_id,
    'path', to_jsonb(p.path),
    'answered', to_jsonb(p.answered),
    'started_at', p.started_at,
    'completed_at', p.completed_at,
    'completion_count', p.completion_count
  )
  from public.world_progress as p
  where p.world_id = world and p.user_id = player;
$$;

revoke all on function private.first_block(uuid) from public;
revoke all on function private.progress_json(uuid, uuid) from public;

---------------------------------------------------------------------------
-- Player API: signed-in users only. Errors: 42501 not signed in;
-- P0002 World not found or no longer published; WR403 not unlocked yet;
-- 22023 an invalid step.
---------------------------------------------------------------------------

-- Checks a fresh position against the World's place. Returns
-- {"result": "unlocked" | "too_far" | "inaccurate", "distance_meters",
--  "unlock_radius_meters", "progress"}. The position is not stored.
create function public.unlock_world(
  world_id uuid,
  latitude double precision,
  longitude double precision,
  accuracy_meters double precision
)
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
  here extensions.geography;
  distance double precision;
  first uuid;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  if latitude is null or longitude is null or accuracy_meters is null
     or latitude < -90 or latitude > 90 or longitude < -180 or longitude > 180
     or accuracy_meters < 0 or accuracy_meters > 100000 then
    raise exception 'Invalid position' using errcode = '22023';
  end if;

  select * into w from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;

  here := extensions.st_setsrid(
    extensions.st_makepoint(longitude, latitude), 4326
  )::extensions.geography;
  distance := extensions.st_distance(w.location, here);

  if accuracy_meters > 100 then
    return jsonb_build_object(
      'result', 'inaccurate',
      'distance_meters', distance,
      'unlock_radius_meters', w.unlock_radius_meters
    );
  end if;

  if distance > w.unlock_radius_meters + least(accuracy_meters, 25) then
    return jsonb_build_object(
      'result', 'too_far',
      'distance_meters', distance,
      'unlock_radius_meters', w.unlock_radius_meters
    );
  end if;

  insert into public.world_visits as v (world_id, user_id)
  values (target, uid)
  on conflict on constraint world_visits_pkey do update
  set last_visited_at = now(), visit_count = v.visit_count + 1;

  first := private.first_block(target);
  insert into public.world_progress (world_id, user_id, current_block_id, path)
  values (target, uid, first, array[first])
  on conflict on constraint world_progress_pkey do nothing;

  return jsonb_build_object(
    'result', 'unlocked',
    'distance_meters', distance,
    'unlock_radius_meters', w.unlock_radius_meters,
    'progress', private.progress_json(target, uid)
  );
end;
$$;

-- Everything the player needs for an unlocked World: its parts in order
-- (without answers or success messages), the images they use, and the
-- account's progress.
create function public.get_world_play(world_id uuid)
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
  p public.world_progress%rowtype;
  first uuid;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  select * into w from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;

  select * into p from public.world_progress as x
  where x.world_id = target and x.user_id = uid
  for update;
  if not found then
    raise exception 'World not unlocked' using errcode = 'WR403';
  end if;

  -- The creator may have removed the part this player was on.
  if p.status = 'in_progress' and (
    p.current_block_id is null or not exists (
      select 1 from public.world_content_blocks as b
      where b.id = p.current_block_id and b.world_id = target
    )
  ) then
    first := private.first_block(target);
    update public.world_progress as x
    set current_block_id = first, path = array[first], answered = '{}'
    where x.world_id = target and x.user_id = uid;
  end if;

  return jsonb_build_object(
    'world', jsonb_build_object(
      'id', w.id,
      'title', w.title,
      'category', w.category,
      'cover_path', (
        select a.storage_path from public.world_assets as a where a.id = w.cover_asset_id
      )
    ),
    'blocks', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', b.id,
          'block_type', b.block_type,
          'schema_version', b.schema_version,
          'content', case
            when b.block_type = 'question' then b.content - 'success_message'
            else b.content
          end
        )
        order by b.position
      )
      from public.world_content_blocks as b
      where b.world_id = target
    ), '[]'::jsonb),
    'assets', coalesce((
      select jsonb_agg(
        jsonb_build_object('id', a.id, 'storage_path', a.storage_path)
        order by a.id
      )
      from public.world_assets as a
      where a.world_id = target
        and exists (
          select 1 from public.world_content_blocks as b
          where b.world_id = target and b.content ->> 'asset_id' = a.id::text
        )
    ), '[]'::jsonb),
    'progress', private.progress_json(target, uid)
  );
end;
$$;

-- Moves from the current part to the next one, the way the World allows:
-- the following part, the destination of a chosen option, or the end. A
-- question must be answered first. Repeating a request is safe: a step from
-- a part the player is no longer on changes nothing ("stale"), and a
-- finished World stays finished.
-- Returns {"progress", "completed", "stale"}.
create function public.advance_world(
  world_id uuid,
  from_block_id uuid,
  option_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  from_id uuid := from_block_id;
  chosen uuid := option_id;
  p public.world_progress%rowtype;
  current_block public.world_content_blocks%rowtype;
  next_id uuid;
  option jsonb;
  destination_position integer;
  finish boolean := false;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  perform 1 from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;

  select * into p from public.world_progress as x
  where x.world_id = target and x.user_id = uid
  for update;
  if not found then
    raise exception 'World not unlocked' using errcode = 'WR403';
  end if;

  if p.status = 'completed' then
    return jsonb_build_object(
      'progress', private.progress_json(target, uid), 'completed', true, 'stale', false
    );
  end if;
  if p.current_block_id is distinct from from_id then
    return jsonb_build_object(
      'progress', private.progress_json(target, uid), 'completed', false, 'stale', true
    );
  end if;

  select * into current_block from public.world_content_blocks as b
  where b.id = from_id and b.world_id = target;
  if not found then
    raise exception 'Part not found' using errcode = '22023';
  end if;

  case current_block.block_type
    when 'story_choice' then
      select value into option
      from jsonb_array_elements(current_block.content -> 'options')
      where value ->> 'id' = chosen::text;
      if option is null then
        raise exception 'Choose one of the options' using errcode = '22023';
      end if;
      select b.id, b.position into next_id, destination_position
      from public.world_content_blocks as b
      where b.world_id = target and b.id::text = option ->> 'destination_block_id';
      if next_id is null or destination_position <= current_block.position then
        raise exception 'That option leads nowhere' using errcode = '22023';
      end if;
    when 'question' then
      if not from_id = any (p.answered) then
        raise exception 'Answer the question first' using errcode = '22023';
      end if;
    when 'completion' then
      finish := true;
    else
      null;
  end case;

  if not finish and next_id is null then
    select b.id into next_id
    from public.world_content_blocks as b
    where b.world_id = target and b.position > current_block.position
    order by b.position
    limit 1;
    finish := next_id is null;
  end if;

  if finish then
    update public.world_progress as x
    set status = 'completed',
        completed_at = now(),
        completion_count = x.completion_count + 1
    where x.world_id = target and x.user_id = uid;
  else
    update public.world_progress as x
    set current_block_id = next_id,
        path = case
          when cardinality(x.path) >= 300 then x.path
          else x.path || next_id
        end
    where x.world_id = target and x.user_id = uid;
  end if;

  return jsonb_build_object(
    'progress', private.progress_json(target, uid), 'completed', finish, 'stale', false
  );
end;
$$;

-- Checks an answer to the current question. Returns {"correct": true,
-- "success_message"} or {"correct": false, "attempts_left"}, or
-- {"correct": false, "rate_limited": true, "retry_after_seconds"}. The
-- accepted answer is never returned.
create function public.answer_question(world_id uuid, block_id uuid, answer text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  question uuid := block_id;
  given text := answer;
  p public.world_progress%rowtype;
  q public.world_content_blocks%rowtype;
  stored text;
  normalized text;
  is_correct boolean;
  wrong integer;
  oldest timestamptz;
  max_wrong constant integer := 5;
  window_length constant interval := interval '10 minutes';
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  perform 1 from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;

  select * into p from public.world_progress as x
  where x.world_id = target and x.user_id = uid
  for update;
  if not found then
    raise exception 'World not unlocked' using errcode = 'WR403';
  end if;

  select * into q from public.world_content_blocks as b
  where b.id = question and b.world_id = target and b.block_type = 'question';
  if not found or p.status <> 'in_progress' or p.current_block_id is distinct from question then
    raise exception 'That is not the current question' using errcode = '22023';
  end if;

  if question = any (p.answered) then
    return jsonb_build_object('correct', true, 'success_message', q.content ->> 'success_message');
  end if;

  select count(*), min(a.attempted_at) into wrong, oldest
  from private.world_answer_attempts as a
  where a.user_id = uid and a.block_id = question and not a.correct
    and a.attempted_at > now() - window_length;
  if wrong >= max_wrong then
    return jsonb_build_object(
      'correct', false,
      'rate_limited', true,
      'retry_after_seconds',
      greatest(1, ceil(extract(epoch from (oldest + window_length - now()))))::integer
    );
  end if;

  normalized := private.normalize_answer(coalesce(given, ''));
  if char_length(normalized) not between 1 and 200 then
    raise exception 'Enter an answer' using errcode = '22023';
  end if;

  select s.answer_hash into stored
  from private.world_question_secrets as s
  where s.block_id = question;
  is_correct := stored is not null and extensions.crypt(normalized, stored) = stored;

  insert into private.world_answer_attempts (block_id, user_id, correct)
  values (question, uid, is_correct);

  if is_correct then
    update public.world_progress as x
    set answered = x.answered || question
    where x.world_id = target and x.user_id = uid;
    return jsonb_build_object('correct', true, 'success_message', q.content ->> 'success_message');
  end if;

  return jsonb_build_object('correct', false, 'attempts_left', max_wrong - wrong - 1);
end;
$$;

-- Starts an unlocked World again from its first part. Questions must be
-- answered again; completions so far are kept.
create function public.restart_world(world_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  first uuid;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;

  perform 1 from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;

  first := private.first_block(target);
  update public.world_progress as x
  set status = 'in_progress', current_block_id = first, path = array[first], answered = '{}'
  where x.world_id = target and x.user_id = uid;
  if not found then
    raise exception 'World not unlocked' using errcode = 'WR403';
  end if;

  return private.progress_json(target, uid);
end;
$$;

---------------------------------------------------------------------------
-- Details now say where the signed-in user stands with the World:
-- "locked", "in_progress" or "completed" (null when signed out).
---------------------------------------------------------------------------
create or replace function public.get_world_details(
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
  play text;
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

  if uid is not null then
    select coalesce(
      (select p.status from public.world_progress as p
       where p.world_id = w.id and p.user_id = uid),
      'locked'
    ) into play;
  end if;

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
    'is_creator', uid is not null and w.creator_id = uid,
    'play_status', play
  );
end;
$$;

---------------------------------------------------------------------------
-- Grants: the player API needs an account (D-032).
---------------------------------------------------------------------------
revoke all on function public.unlock_world(uuid, double precision, double precision, double precision)
  from public, anon, authenticated;
revoke all on function public.get_world_play(uuid) from public, anon, authenticated;
revoke all on function public.advance_world(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.answer_question(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.restart_world(uuid) from public, anon, authenticated;

grant execute on function public.unlock_world(uuid, double precision, double precision, double precision)
  to authenticated;
grant execute on function public.get_world_play(uuid) to authenticated;
grant execute on function public.advance_world(uuid, uuid, uuid) to authenticated;
grant execute on function public.answer_question(uuid, uuid, text) to authenticated;
grant execute on function public.restart_world(uuid) to authenticated;
