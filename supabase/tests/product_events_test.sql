-- Tests for product events: log_event, what an event may hold, the limits,
-- the 90-day clearing, the per-World totals and the pilot functions.
--
-- How to run: execute this whole file as one statement. It always ends by
-- raising an exception, which rolls back everything it did.
--
-- PASS: the error message is exactly
--   WORLDS_TESTS_PASSED product_events_test: <n> checks
--
-- Every count is taken for this file's own launch ids and Worlds, or as a
-- difference from a starting value: the real tables may hold rows of their
-- own. Fixture Worlds sit in the South Pacific (-44, -124).
do $$
declare
  creator constant uuid := 'f9f9f9f9-0000-4000-8000-00000000000a';
  explorer constant uuid := 'a0a0a0a0-0000-4000-8000-00000000000b';
  claims_creator constant text := json_build_object('sub', 'f9f9f9f9-0000-4000-8000-00000000000a', 'role', 'authenticated')::text;
  claims_explorer constant text := json_build_object('sub', 'a0a0a0a0-0000-4000-8000-00000000000b', 'role', 'authenticated')::text;
  lat constant double precision := -44.0;
  lon constant double precision := -124.0;
  w1 constant uuid := '50000000-0000-4000-8000-000000000001';
  w2 constant uuid := '50000000-0000-4000-8000-000000000002';
  w3 constant uuid := '50000000-0000-4000-8000-000000000003';
  b1 constant uuid := '51000000-0000-4000-8000-000000000001';
  b2 constant uuid := '51000000-0000-4000-8000-000000000002';
  -- Launch ids
  s1 constant uuid := '52000000-0000-4000-8000-000000000001';
  s2 constant uuid := '52000000-0000-4000-8000-000000000002';
  s3 constant uuid := '52000000-0000-4000-8000-000000000003';
  s4 constant uuid := '52000000-0000-4000-8000-000000000004';
  s5 constant uuid := '52000000-0000-4000-8000-000000000005';
  s6 constant uuid := '52000000-0000-4000-8000-000000000006';
  today constant date := (now() at time zone 'utc')::date;
  checks integer := 0;
  found_count integer;
  value text;
  kept boolean;
  before_funnel record;
  after_funnel record;
  before_summary record;
  after_summary record;
begin
  ---------------------------------------------------------------------------
  -- Fixtures: a creator with two published Worlds and a draft; an explorer.
  ---------------------------------------------------------------------------
  select * into before_summary from private.pilot_summary();
  select * into before_funnel from private.pilot_funnel(today) as f where f.day = today;

  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values
    (creator, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'events-creator@worlds.test', '{"username": "etest_creator"}', now(), now()),
    (explorer, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'events-explorer@worlds.test', '{"username": "etest_explorer"}', now(), now());

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_creator, true);
  perform public.save_world(jsonb_build_object(
    'id', w1, 'category', 'story', 'title', 'Signal Hill', 'description', 'Up the hill.',
    'latitude', lat, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', jsonb_build_array(jsonb_build_object('id', b1, 'block_type', 'text',
      'content', jsonb_build_object('body', 'The mast hums.')))), '{}'::jsonb);
  perform public.publish_world(w1);
  perform public.save_world(jsonb_build_object(
    'id', w2, 'category', 'story', 'title', 'Ferry Steps', 'description', 'Down the steps.',
    'latitude', lat + 0.01, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', jsonb_build_array(jsonb_build_object('id', b2, 'block_type', 'text',
      'content', jsonb_build_object('body', 'The ferry waits.')))), '{}'::jsonb);
  perform public.publish_world(w2);
  perform public.save_world(jsonb_build_object(
    'id', w3, 'category', 'story', 'title', 'Not Yet', 'blocks', '[]'::jsonb), '{}'::jsonb);
  reset role;

  ---------------------------------------------------------------------------
  -- Configuration: private tables, one public way in, and no trail columns
  ---------------------------------------------------------------------------
  if not (select relrowsecurity from pg_class where oid = 'private.product_events'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'private.world_event_counts'::regclass)
     or has_table_privilege('authenticated', 'private.product_events', 'SELECT')
     or has_table_privilege('anon', 'private.world_event_counts', 'SELECT')
     or not has_function_privilege('anon', 'public.log_event(text, uuid, uuid, text)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.log_event(text, uuid, uuid, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.pilot_funnel(date)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.pilot_summary()', 'EXECUTE')
     or has_function_privilege('anon', 'private.pilot_worlds(date)', 'EXECUTE') then
    raise exception 'FAIL config: grants for product events are wrong';
  end if;
  checks := checks + 1;

  -- An event can hold a launch id, a name, an outcome and a time: nothing
  -- that names an account, a World or a position.
  select string_agg(a.attname, ',' order by a.attname) into value
  from pg_attribute as a
  where a.attrelid = 'private.product_events'::regclass and a.attnum > 0 and not a.attisdropped;
  if value <> 'id,name,occurred_at,outcome,session_id' then
    raise exception 'FAIL config: an event row has unexpected columns: %', value;
  end if;
  select string_agg(a.attname, ',' order by a.attname) into value
  from pg_attribute as a
  where a.attrelid = 'private.world_event_counts'::regclass and a.attnum > 0 and not a.attisdropped;
  if value <> 'day,name,total,world_id' then
    raise exception 'FAIL config: a World total has unexpected columns: %', value;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Signed out: events are kept; bad ones are refused
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  kept := public.log_event('explore_opened', s1);
  if not kept or not public.log_event('world_marker_selected', s1) then
    raise exception 'FAIL anon: events were not kept';
  end if;
  checks := checks + 1;

  begin
    perform public.log_event('world_shared', s1);
    raise exception 'FAIL log: an unknown event was kept';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  begin
    perform public.log_event('explore_opened', null);
    raise exception 'FAIL log: an event without a launch id was kept';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  begin
    perform public.log_event('world_unlock_attempted', s1, w1);
    raise exception 'FAIL log: an unlock attempt without an outcome was kept';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  begin
    perform public.log_event('world_unlock_attempted', s1, w1, '37 m away');
    raise exception 'FAIL log: a free-text outcome was kept';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  begin
    perform public.log_event('world_details_opened', s1, w1, 'unlocked');
    raise exception 'FAIL log: an outcome on another event was kept';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform 1 from private.product_events;
    raise exception 'FAIL anon: events were readable';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  reset role;

  select count(*) into found_count from private.product_events as e where e.session_id = s1;
  if found_count <> 2 then
    raise exception 'FAIL log: expected 2 events for the first launch, found %', found_count;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Signed in: the event still names no account and no World; the World
  -- only gains a daily total
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_explorer, true);
  perform public.log_event('explore_opened', s2);
  perform public.log_event('world_details_opened', s2, w1);
  perform public.log_event('world_details_opened', s2, w1);
  perform public.log_event('world_details_opened', s2, w3);
  perform public.log_event('world_unlock_attempted', s2, w1, 'too_far');
  perform public.log_event('world_unlock_attempted', s2, w1, 'unlocked');
  reset role;

  if exists (
    select 1 from private.product_events as e
    where e.session_id = s2 and e::text ~ (explorer::text || '|' || w1::text)
  ) then
    raise exception 'FAIL trail: an event row contains the account or the World';
  end if;
  checks := checks + 1;

  if (select c.total from private.world_event_counts as c
      where c.world_id = w1 and c.day = today and c.name = 'world_details_opened') <> 2
     or (select c.total from private.world_event_counts as c
         where c.world_id = w1 and c.day = today and c.name = 'world_unlock_attempted') <> 2
     or exists (select 1 from private.world_event_counts as c where c.world_id = w3) then
    raise exception 'FAIL totals: per-World totals are wrong, or a draft was counted';
  end if;
  checks := checks + 1;

  select count(*) into found_count from private.pilot_worlds(today) as p
  where p.world_id = w1 and p.title = 'Signal Hill' and p.details_opened = 2 and p.unlock_attempts = 2;
  if found_count <> 1 then
    raise exception 'FAIL totals: pilot_worlds does not report the World';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Limits: 200 events per launch
  ---------------------------------------------------------------------------
  insert into private.product_events (session_id, name)
  select s3, 'world_marker_selected' from generate_series(1, 200);
  set local role anon;
  kept := public.log_event('world_marker_selected', s3);
  reset role;
  select count(*) into found_count from private.product_events as e where e.session_id = s3;
  if kept or found_count <> 200 then
    raise exception 'FAIL limit: a 201st event of one launch was kept';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Clearing: events older than 90 days go when a new launch appears
  ---------------------------------------------------------------------------
  insert into private.product_events (session_id, name, occurred_at)
  values
    (s4, 'explore_opened', now() - interval '91 days'),
    (s4, 'explore_opened', now() - interval '89 days');
  set local role anon;
  perform public.log_event('explore_opened', s5);
  reset role;
  select count(*) into found_count from private.product_events as e where e.session_id = s4;
  if found_count <> 1 or exists (
    select 1 from private.product_events as e
    where e.session_id = s4 and e.occurred_at < now() - interval '90 days'
  ) then
    raise exception 'FAIL clearing: expected only the 89-day-old event to remain, found %', found_count;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- The pilot functions, as differences from where they started
  ---------------------------------------------------------------------------
  -- The explorer unlocks and finishes one World and unlocks a second; the
  -- creator has published two.
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_explorer, true);
  perform public.unlock_world(w1, lat, lon, 5);
  perform public.advance_world(w1, b1);
  perform public.unlock_world(w2, lat + 0.01, lon, 5);
  perform public.set_world_saved(w1, true);
  perform public.report_world(w2, 'other');
  reset role;

  select * into after_funnel from private.pilot_funnel(today) as f where f.day = today;
  if after_funnel.launches - before_funnel.launches <> 3
     or after_funnel.launches_selecting_a_marker - before_funnel.launches_selecting_a_marker <> 2
     or after_funnel.launches_opening_details - before_funnel.launches_opening_details <> 1
     or after_funnel.launches_attempting_unlock - before_funnel.launches_attempting_unlock <> 1
     or after_funnel.launches_unlocking - before_funnel.launches_unlocking <> 1
     or after_funnel.worlds_started - before_funnel.worlds_started <> 2
     or after_funnel.worlds_completed - before_funnel.worlds_completed <> 1
     or after_funnel.worlds_published - before_funnel.worlds_published <> 2
     or after_funnel.worlds_saved - before_funnel.worlds_saved <> 1
     or after_funnel.worlds_reported - before_funnel.worlds_reported <> 1 then
    raise exception 'FAIL funnel: today changed by % (before %)', after_funnel, before_funnel;
  end if;
  checks := checks + 1;

  select * into after_summary from private.pilot_summary();
  if after_summary.accounts - before_summary.accounts <> 2
     or after_summary.creators - before_summary.creators <> 1
     or after_summary.repeat_creators - before_summary.repeat_creators <> 1
     or after_summary.explorers - before_summary.explorers <> 1
     or after_summary.explorers_with_a_second_world - before_summary.explorers_with_a_second_world <> 1
     or after_summary.explorers_who_finished_one - before_summary.explorers_who_finished_one <> 1
     or after_summary.published_worlds - before_summary.published_worlds <> 2 then
    raise exception 'FAIL summary: changed by % (before %)', after_summary, before_summary;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Limits: 20,000 events in all per 24 hours (last, as it closes the door)
  ---------------------------------------------------------------------------
  insert into private.product_events (session_id, name)
  select gen_random_uuid(), 'explore_opened' from generate_series(1, 20000);
  set local role anon;
  kept := public.log_event('explore_opened', s6);
  reset role;
  if kept or exists (select 1 from private.product_events as e where e.session_id = s6) then
    raise exception 'FAIL limit: an event was kept beyond the daily total';
  end if;
  checks := checks + 1;

  raise exception 'WORLDS_TESTS_PASSED product_events_test: % checks', checks;
end $$;
