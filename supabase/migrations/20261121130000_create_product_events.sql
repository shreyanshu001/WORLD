-- Product events for the pilot (Checkpoint 7, docs/DECISIONS.md, D-039).
--
-- Only what the server cannot already see is recorded: that Explore was
-- opened, a marker selected, details opened and an unlock attempted. Starts,
-- completions, publishing, saving and reporting are counted from their own
-- tables by the functions at the end.
--
-- No trail. An event holds a random id made when the app was launched, a
-- name and a time. It holds no account, no World and no position. Which
-- Worlds were opened is kept only as a daily total per World, with no id of
-- any person or launch.
--
-- Nothing here can be read or written through the API except log_event.
-- Limits: 200 events per launch id, and 20,000 events in all per 24 hours;
-- beyond either, events are dropped. Events older than 90 days are deleted
-- whenever a new launch id first appears.

---------------------------------------------------------------------------
-- Tables (private: no API access)
---------------------------------------------------------------------------
create table private.product_events (
  id bigint generated always as identity primary key,
  -- Made by the app at launch and never stored on the device.
  session_id uuid not null,
  name text not null
    constraint product_events_name check (
      name in (
        'explore_opened', 'world_marker_selected', 'world_details_opened',
        'world_unlock_attempted'
      )
    ),
  -- How an unlock attempt ended; no distance and no accuracy.
  outcome text,
  occurred_at timestamptz not null default now(),
  constraint product_events_outcome check (
    (name = 'world_unlock_attempted'
       and outcome in ('unlocked', 'too_far', 'inaccurate', 'no_location', 'failed'))
    or (name <> 'world_unlock_attempted' and outcome is null)
  )
);

create index product_events_session_idx on private.product_events (session_id);
create index product_events_time_idx on private.product_events (occurred_at);

alter table private.product_events enable row level security;
revoke all on table private.product_events from public, anon, authenticated;

create table private.world_event_counts (
  world_id uuid not null references public.worlds (id) on delete cascade,
  day date not null,
  name text not null
    constraint world_event_counts_name check (
      name in ('world_details_opened', 'world_unlock_attempted')
    ),
  total integer not null default 0,
  primary key (world_id, day, name)
);

alter table private.world_event_counts enable row level security;
revoke all on table private.world_event_counts from public, anon, authenticated;

---------------------------------------------------------------------------
-- The only way in. Callable signed out, because browsing needs no account.
-- Returns whether the event was kept; a dropped event is not an error.
---------------------------------------------------------------------------
create function public.log_event(
  event_name text,
  session_id uuid,
  world_id uuid default null,
  outcome text default null
)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  kind text := event_name;
  launch uuid := session_id;
  target uuid := world_id;
  ending text := outcome;
  seen integer;
begin
  if launch is null or kind is null or kind not in (
       'explore_opened', 'world_marker_selected', 'world_details_opened',
       'world_unlock_attempted'
     ) then
    raise exception 'Unknown event' using errcode = '22023';
  end if;
  if kind = 'world_unlock_attempted' then
    if ending is null or ending not in (
         'unlocked', 'too_far', 'inaccurate', 'no_location', 'failed'
       ) then
      raise exception 'Unknown outcome' using errcode = '22023';
    end if;
  elsif ending is not null then
    raise exception 'This event has no outcome' using errcode = '22023';
  end if;

  select count(*) into seen
  from private.product_events as e where e.session_id = launch;

  if seen = 0 then
    -- A new launch: the moment old events are cleared out.
    delete from private.product_events as e
    where e.occurred_at < now() - interval '90 days';
  end if;

  if seen >= 200 then
    return false;
  end if;
  if (
    select count(*) from private.product_events as e
    where e.occurred_at > now() - interval '1 day'
  ) >= 20000 then
    return false;
  end if;

  insert into private.product_events (session_id, name, outcome)
  values (launch, kind, ending);

  -- A daily total per World, for published Worlds only, with no id of the
  -- launch or of anyone.
  if target is not null and kind in ('world_details_opened', 'world_unlock_attempted')
     and exists (
       select 1 from public.worlds as w
       where w.id = target and w.status = 'published' and w.visibility = 'public'
     ) then
    insert into private.world_event_counts as c (world_id, day, name, total)
    values (target, (now() at time zone 'utc')::date, kind, 1)
    on conflict on constraint world_event_counts_pkey do update
    set total = c.total + 1;
  end if;

  return true;
end;
$$;

revoke all on function public.log_event(text, uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.log_event(text, uuid, uuid, text) to anon, authenticated;

---------------------------------------------------------------------------
-- Reading the pilot: private functions for the SQL editor.
---------------------------------------------------------------------------

-- One row per day (UTC) from first_day to today: how many launches reached
-- each step, and what the other tables recorded that day.
create function private.pilot_funnel(first_day date default (current_date - 29))
returns table (
  day date,
  launches bigint,
  launches_selecting_a_marker bigint,
  launches_opening_details bigint,
  launches_attempting_unlock bigint,
  launches_unlocking bigint,
  worlds_started bigint,
  worlds_completed bigint,
  worlds_published bigint,
  worlds_saved bigint,
  worlds_reported bigint
)
language sql
stable
set search_path = ''
as $$
  select
    d.day::date,
    (select count(distinct e.session_id) from private.product_events as e
     where (e.occurred_at at time zone 'utc')::date = d.day::date and e.name = 'explore_opened'),
    (select count(distinct e.session_id) from private.product_events as e
     where (e.occurred_at at time zone 'utc')::date = d.day::date and e.name = 'world_marker_selected'),
    (select count(distinct e.session_id) from private.product_events as e
     where (e.occurred_at at time zone 'utc')::date = d.day::date and e.name = 'world_details_opened'),
    (select count(distinct e.session_id) from private.product_events as e
     where (e.occurred_at at time zone 'utc')::date = d.day::date and e.name = 'world_unlock_attempted'),
    (select count(distinct e.session_id) from private.product_events as e
     where (e.occurred_at at time zone 'utc')::date = d.day::date and e.outcome = 'unlocked'),
    (select count(*) from public.world_progress as p
     where (p.started_at at time zone 'utc')::date = d.day::date),
    (select count(*) from public.world_progress as p
     where (p.completed_at at time zone 'utc')::date = d.day::date),
    (select count(*) from public.worlds as w
     where (w.published_at at time zone 'utc')::date = d.day::date and w.status = 'published'),
    (select count(*) from public.saved_worlds as s
     where (s.created_at at time zone 'utc')::date = d.day::date),
    (select count(*) from public.world_reports as r
     where (r.created_at at time zone 'utc')::date = d.day::date)
  from generate_series(first_day::timestamp, (now() at time zone 'utc')::date::timestamp, interval '1 day') as d(day)
  order by 1;
$$;

-- The whole pilot in one row: who created, who came back to create again,
-- who discovered a second World, who finished one.
create function private.pilot_summary()
returns table (
  accounts bigint,
  creators bigint,
  repeat_creators bigint,
  explorers bigint,
  explorers_with_a_second_world bigint,
  explorers_who_finished_one bigint,
  published_worlds bigint
)
language sql
stable
set search_path = ''
as $$
  select
    (select count(*) from public.profiles),
    (select count(*) from (
       select w.creator_id from public.worlds as w
       where w.published_at is not null and w.status <> 'deleted'
       group by w.creator_id) as c),
    (select count(*) from (
       select w.creator_id from public.worlds as w
       where w.published_at is not null and w.status <> 'deleted'
       group by w.creator_id having count(*) >= 2) as c),
    (select count(distinct p.user_id) from public.world_progress as p),
    (select count(*) from (
       select p.user_id from public.world_progress as p
       group by p.user_id having count(*) >= 2) as x),
    (select count(distinct p.user_id) from public.world_progress as p
     where p.completion_count > 0),
    (select count(*) from public.worlds as w
     where w.status = 'published' and w.visibility = 'public');
$$;

-- Daily totals per World: details opened and unlock attempts.
create function private.pilot_worlds(first_day date default (current_date - 29))
returns table (
  world_id uuid,
  title text,
  details_opened bigint,
  unlock_attempts bigint
)
language sql
stable
set search_path = ''
as $$
  select
    w.id,
    w.title,
    coalesce(sum(c.total) filter (where c.name = 'world_details_opened'), 0),
    coalesce(sum(c.total) filter (where c.name = 'world_unlock_attempted'), 0)
  from public.worlds as w
  join private.world_event_counts as c on c.world_id = w.id
  where c.day >= first_day
  group by w.id, w.title
  order by 3 desc, 2;
$$;

revoke all on function private.pilot_funnel(date) from public;
revoke all on function private.pilot_summary() from public;
revoke all on function private.pilot_worlds(date) from public;
