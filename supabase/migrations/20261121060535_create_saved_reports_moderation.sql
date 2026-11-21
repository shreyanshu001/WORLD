-- Saved Worlds, reports, moderation and profile pages (Checkpoint 6,
-- docs/DATABASE.md).
--
-- Who can read what:
--   saved_worlds    their own account only
--   world_reports   their reporter only, without the moderation outcome
--   private.moderation_actions   nobody through the API
--
-- Moderation has no API (docs/DECISIONS.md, D-036). Its functions live in
-- the private schema and are run by the project owner in the Supabase SQL
-- editor; each one records who acted, why, and what changed.
--
-- Limits (D-034, D-035): 500 saved Worlds per account; 10 reports per
-- account per day; one pending report per account and World; report details
-- of at most 500 characters.

---------------------------------------------------------------------------
-- Saved Worlds
---------------------------------------------------------------------------
create table public.saved_worlds (
  user_id uuid not null references public.profiles (id) on delete cascade,
  world_id uuid not null references public.worlds (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, world_id)
);

comment on table public.saved_worlds is
  'Worlds an account bookmarked. Private to that account.';

create index saved_worlds_recent_idx on public.saved_worlds (user_id, created_at desc);
create index saved_worlds_world_idx on public.saved_worlds (world_id);

alter table public.saved_worlds enable row level security;

revoke all on table public.saved_worlds from anon, authenticated;
grant select on table public.saved_worlds to authenticated;

create policy "Users read their own saved Worlds"
  on public.saved_worlds for select to authenticated
  using ((select auth.uid()) = user_id);

-- Saves or removes a World for the signed-in user. Saving needs a published
-- public World; removing always works. Repeating either changes nothing.
-- Returns {"saved": true | false}.
create function public.set_world_saved(world_id uuid, saved boolean)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  wanted boolean := saved;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  if target is null or wanted is null then
    raise exception 'Invalid request' using errcode = '22023';
  end if;

  if not wanted then
    delete from public.saved_worlds as s
    where s.user_id = uid and s.world_id = target;
    return jsonb_build_object('saved', false);
  end if;

  perform 1 from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from public.saved_worlds as s
    where s.user_id = uid and s.world_id = target
  ) then
    return jsonb_build_object('saved', true);
  end if;

  if (select count(*) from public.saved_worlds as s where s.user_id = uid) >= 500 then
    raise exception 'Saved list is full' using errcode = 'WR429';
  end if;

  insert into public.saved_worlds (user_id, world_id)
  values (uid, target)
  on conflict on constraint saved_worlds_pkey do nothing;

  return jsonb_build_object('saved', true);
end;
$$;

-- The signed-in user's saved Worlds that can be shown now (published and
-- public), newest save first, one page at a time. Distance is measured from
-- the given position when there is one. Returns {"items": [...],
-- "has_more": boolean, "unavailable": number of saved Worlds that are
-- unpublished, hidden or deleted at the moment}.
create function public.get_saved_worlds(
  page_size integer default 20,
  page_offset integer default 0,
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
  wanted integer := least(greatest(coalesce(page_size, 20), 1), 50);
  skipped integer := least(greatest(coalesce(page_offset, 0), 0), 500);
  origin extensions.geography;
  items jsonb;
  fetched integer;
  unavailable integer;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
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

  -- One row more than a page, to know whether another page exists.
  select coalesce(jsonb_agg(q.item order by q.saved_at desc, q.id), '[]'::jsonb), count(*)
  into items, fetched
  from (
    select
      w.id,
      s.created_at as saved_at,
      jsonb_build_object(
        'id', w.id,
        'title', w.title,
        'category', w.category,
        'creator_username', p.username,
        'creator_display_name', p.display_name,
        'cover_path', (
          select a.storage_path from public.world_assets as a where a.id = w.cover_asset_id
        ),
        'distance_meters', case
          when origin is not null then extensions.st_distance(w.location, origin)
        end,
        'saved_at', s.created_at
      ) as item
    from public.saved_worlds as s
    join public.worlds as w on w.id = s.world_id
    join public.profiles as p on p.id = w.creator_id
    where s.user_id = uid and w.status = 'published' and w.visibility = 'public'
    order by s.created_at desc, w.id
    limit wanted + 1 offset skipped
  ) as q;

  select count(*) into unavailable
  from public.saved_worlds as s
  join public.worlds as w on w.id = s.world_id
  where s.user_id = uid and not (w.status = 'published' and w.visibility = 'public');

  return jsonb_build_object(
    'items', case when fetched > wanted then items - wanted else items end,
    'has_more', fetched > wanted,
    'unavailable', unavailable
  );
end;
$$;

---------------------------------------------------------------------------
-- Reports
---------------------------------------------------------------------------
create table public.world_reports (
  id uuid primary key default gen_random_uuid(),
  world_id uuid not null references public.worlds (id) on delete cascade,
  -- A report outlives its reporter's account, without the name.
  reporter_id uuid references public.profiles (id) on delete set null,
  reason text not null
    constraint world_reports_reason check (
      reason in (
        'unsafe_or_private_place', 'harassment_or_hate', 'sexual_content',
        'dangerous_activity', 'spam_or_misleading', 'other'
      )
    ),
  description text
    constraint world_reports_description check (
      description is null
      or (description = btrim(description) and char_length(description) between 1 and 500)
    ),
  status text not null default 'pending'
    constraint world_reports_status check (
      status in ('pending', 'reviewed', 'actioned', 'dismissed')
    ),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

comment on table public.world_reports is
  'Reports of Worlds. A reporter sees only their own; creators see none.';

create unique index world_reports_one_pending_idx
  on public.world_reports (world_id, reporter_id) where status = 'pending';
create index world_reports_reporter_idx on public.world_reports (reporter_id, created_at desc);
create index world_reports_queue_idx on public.world_reports (status, created_at);

alter table public.world_reports enable row level security;

revoke all on table public.world_reports from anon, authenticated;
-- Not the status or resolved_at: the outcome of moderation stays internal.
grant select (id, world_id, reporter_id, reason, description, created_at)
  on table public.world_reports to authenticated;

create policy "Reporters read their own reports"
  on public.world_reports for select to authenticated
  using ((select auth.uid()) = reporter_id);

-- Reports a published public World. Returns {"reported": true,
-- "already_reported": boolean}; a second report of the same World while the
-- first is pending changes nothing and does not count towards the limit.
create function public.report_world(world_id uuid, reason text, details text default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  target uuid := world_id;
  chosen text := reason;
  note text := nullif(btrim(coalesce(details, '')), '');
  w public.worlds%rowtype;
begin
  if uid is null then
    raise exception 'Sign in required' using errcode = '42501';
  end if;
  if chosen is null or chosen not in (
       'unsafe_or_private_place', 'harassment_or_hate', 'sexual_content',
       'dangerous_activity', 'spam_or_misleading', 'other'
     ) then
    raise exception 'Choose a reason' using errcode = '22023';
  end if;
  if char_length(note) > 500 then
    raise exception 'Details are too long' using errcode = '22023';
  end if;

  select * into w from public.worlds as x
  where x.id = target and x.status = 'published' and x.visibility = 'public';
  if not found then
    raise exception 'World not available' using errcode = 'P0002';
  end if;
  if w.creator_id = uid then
    raise exception 'You cannot report your own World' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.world_reports as r
    where r.world_id = target and r.reporter_id = uid and r.status = 'pending'
  ) then
    return jsonb_build_object('reported', true, 'already_reported', true);
  end if;

  if (
    select count(*) from public.world_reports as r
    where r.reporter_id = uid and r.created_at > now() - interval '1 day'
  ) >= 10 then
    raise exception 'Daily report limit reached' using errcode = 'WR429';
  end if;

  begin
    insert into public.world_reports (world_id, reporter_id, reason, description)
    values (target, uid, chosen, note);
  exception
    -- The same report arrived twice at once.
    when unique_violation then
      return jsonb_build_object('reported', true, 'already_reported', true);
  end;

  return jsonb_build_object('reported', true, 'already_reported', false);
end;
$$;

---------------------------------------------------------------------------
-- Moderation: private functions for the SQL editor, with a log.
---------------------------------------------------------------------------
create table private.moderation_actions (
  id bigint generated always as identity primary key,
  -- No foreign key: the record outlives the World.
  world_id uuid not null,
  world_title text not null,
  action text not null
    constraint moderation_actions_action check (
      action in ('hide', 'restore', 'remove', 'dismiss_reports')
    ),
  moderator text not null
    constraint moderation_actions_moderator check (char_length(btrim(moderator)) between 2 and 80),
  note text not null
    constraint moderation_actions_note check (char_length(btrim(note)) between 3 and 1000),
  previous_status text not null,
  new_status text not null,
  reports_closed integer not null default 0,
  acted_at timestamptz not null default now()
);

create index moderation_actions_world_idx on private.moderation_actions (world_id, acted_at desc);

alter table private.moderation_actions enable row level security;
revoke all on table private.moderation_actions from public, anon, authenticated;

-- Applies one moderation action to a World and logs it. Called by the four
-- functions below.
create function private.moderate_world(
  target_world uuid,
  wanted_action text,
  moderator text,
  note text
)
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  w public.worlds%rowtype;
  next_status text;
  report_status text;
  closed integer := 0;
begin
  select * into w from public.worlds as x where x.id = target_world for update;
  if not found then
    raise exception 'World % not found', target_world;
  end if;

  case wanted_action
    when 'hide' then
      if w.status not in ('published', 'draft') then
        raise exception 'Only a published or draft World can be hidden; this one is %', w.status;
      end if;
      if w.location is null then
        raise exception 'A draft without a place cannot be hidden; remove it instead';
      end if;
      next_status := 'hidden';
      report_status := 'actioned';
    when 'restore' then
      if w.status <> 'hidden' then
        raise exception 'Only a hidden World can be restored; this one is %', w.status;
      end if;
      -- Back to published only if it was published when hidden and is still
      -- complete; otherwise to a draft its creator can publish again.
      select a.previous_status into next_status
      from private.moderation_actions as a
      where a.world_id = target_world and a.action = 'hide'
      order by a.acted_at desc, a.id desc
      limit 1;
      if next_status is distinct from 'published'
         or w.published_at is null
         or jsonb_array_length(private.world_publish_problems(target_world)) > 0 then
        next_status := 'draft';
      end if;
    when 'remove' then
      if w.status = 'deleted' then
        raise exception 'This World is already deleted';
      end if;
      next_status := 'deleted';
      report_status := 'actioned';
    when 'dismiss_reports' then
      next_status := w.status;
      report_status := 'dismissed';
    else
      raise exception 'Unknown action %', wanted_action;
  end case;

  if next_status <> w.status then
    update public.worlds as x set status = next_status where x.id = target_world;
  end if;

  if report_status is not null then
    update public.world_reports as r
    set status = report_status, resolved_at = now()
    where r.world_id = target_world and r.status = 'pending';
    get diagnostics closed = row_count;
  end if;

  insert into private.moderation_actions
    (world_id, world_title, action, moderator, note, previous_status, new_status, reports_closed)
  values
    (target_world, w.title, wanted_action, btrim(moderator), btrim(note), w.status, next_status, closed);

  return format('%s: "%s" %s -> %s, %s report(s) closed',
                wanted_action, w.title, w.status, next_status, closed);
end;
$$;

-- Takes a World out of discovery, details and play. Its creator cannot edit,
-- publish or delete it while hidden. Pending reports become "actioned".
create function private.hide_world(target_world uuid, moderator text, note text)
returns text
language sql
volatile
set search_path = ''
as $$ select private.moderate_world(target_world, 'hide', moderator, note); $$;

-- Undoes a hide.
create function private.restore_world(target_world uuid, moderator text, note text)
returns text
language sql
volatile
set search_path = ''
as $$ select private.moderate_world(target_world, 'restore', moderator, note); $$;

-- Soft-deletes a World for good. Pending reports become "actioned".
create function private.remove_world(target_world uuid, moderator text, note text)
returns text
language sql
volatile
set search_path = ''
as $$ select private.moderate_world(target_world, 'remove', moderator, note); $$;

-- Closes a World's pending reports as "dismissed" and leaves the World alone.
create function private.dismiss_reports(target_world uuid, moderator text, note text)
returns text
language sql
volatile
set search_path = ''
as $$ select private.moderate_world(target_world, 'dismiss_reports', moderator, note); $$;

-- Pending reports, oldest first, with what a moderator needs to decide.
create function private.moderation_queue()
returns table (
  report_id uuid,
  reported_at timestamptz,
  reason text,
  description text,
  reporter text,
  world_id uuid,
  world_title text,
  world_status text,
  creator text,
  pending_for_world bigint
)
language sql
stable
set search_path = ''
as $$
  select
    r.id, r.created_at, r.reason, r.description, rp.username,
    w.id, w.title, w.status, cp.username,
    count(*) over (partition by r.world_id)
  from public.world_reports as r
  join public.worlds as w on w.id = r.world_id
  join public.profiles as cp on cp.id = w.creator_id
  left join public.profiles as rp on rp.id = r.reporter_id
  where r.status = 'pending'
  order by r.created_at, r.id;
$$;

revoke all on function private.moderate_world(uuid, text, text, text) from public;
revoke all on function private.hide_world(uuid, text, text) from public;
revoke all on function private.restore_world(uuid, text, text) from public;
revoke all on function private.remove_world(uuid, text, text) from public;
revoke all on function private.dismiss_reports(uuid, text, text) from public;
revoke all on function private.moderation_queue() from public;

---------------------------------------------------------------------------
-- Profile pages: public fields and published Worlds for everyone; the
-- owner also gets their own private counts.
---------------------------------------------------------------------------
create function public.get_profile_page(
  profile_username text,
  page_size integer default 20,
  page_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  wanted integer := least(greatest(coalesce(page_size, 20), 1), 50);
  skipped integer := least(greatest(coalesce(page_offset, 0), 0), 1000);
  p public.profiles%rowtype;
  own boolean;
  items jsonb;
  fetched integer;
begin
  select * into p from public.profiles as x
  where x.username = lower(btrim(coalesce(profile_username, '')));
  if not found then
    raise exception 'Profile not found' using errcode = 'P0002';
  end if;
  own := uid is not null and uid = p.id;

  select coalesce(jsonb_agg(q.item order by q.published_at desc, q.id), '[]'::jsonb), count(*)
  into items, fetched
  from (
    select
      w.id,
      w.published_at,
      jsonb_build_object(
        'id', w.id,
        'title', w.title,
        'category', w.category,
        'cover_path', (
          select a.storage_path from public.world_assets as a where a.id = w.cover_asset_id
        ),
        'published_at', w.published_at
      ) as item
    from public.worlds as w
    where w.creator_id = p.id and w.status = 'published' and w.visibility = 'public'
    order by w.published_at desc, w.id
    limit wanted + 1 offset skipped
  ) as q;

  return jsonb_build_object(
    'username', p.username,
    'display_name', p.display_name,
    'bio', p.bio,
    'is_own', own,
    'published_count', (
      select count(*) from public.worlds as w
      where w.creator_id = p.id and w.status = 'published' and w.visibility = 'public'
    ),
    -- The owner's own activity; nobody else's is shown.
    'draft_count', case when own then (
      select count(*) from public.worlds as w
      where w.creator_id = p.id and w.status = 'draft'
    ) end,
    'discovered_count', case when own then (
      select count(*) from public.world_progress as g where g.user_id = p.id
    ) end,
    'completed_count', case when own then (
      select count(*) from public.world_progress as g
      where g.user_id = p.id and g.completion_count > 0
    ) end,
    'worlds', case when fetched > wanted then items - wanted else items end,
    'has_more', fetched > wanted
  );
end;
$$;

---------------------------------------------------------------------------
-- Details now say whether the signed-in user saved the World ("is_saved",
-- null when signed out).
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
  saved boolean;
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
    saved := exists (
      select 1 from public.saved_worlds as s
      where s.user_id = uid and s.world_id = w.id
    );
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
    'play_status', play,
    'is_saved', saved
  );
end;
$$;

---------------------------------------------------------------------------
-- Grants: saving and reporting need an account; profile pages are public.
---------------------------------------------------------------------------
revoke all on function public.set_world_saved(uuid, boolean) from public, anon, authenticated;
revoke all on function public.get_saved_worlds(integer, integer, double precision, double precision)
  from public, anon, authenticated;
revoke all on function public.report_world(uuid, text, text) from public, anon, authenticated;
revoke all on function public.get_profile_page(text, integer, integer) from public, anon, authenticated;

grant execute on function public.set_world_saved(uuid, boolean) to authenticated;
grant execute on function public.get_saved_worlds(integer, integer, double precision, double precision)
  to authenticated;
grant execute on function public.report_world(uuid, text, text) to authenticated;
grant execute on function public.get_profile_page(text, integer, integer) to anon, authenticated;
