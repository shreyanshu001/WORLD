-- Tests for public.worlds and public.get_nearby_worlds.
--
-- How to run: execute this whole file as one statement (Supabase SQL editor
-- or the Supabase MCP execute_sql tool). It always ends by raising an
-- exception, which rolls back everything it did.
--
-- PASS: the error message is exactly
--   WORLDS_TESTS_PASSED worlds_test: <n> checks
-- Any other message is a FAILURE and names the check that failed.
--
-- Fixture Worlds sit in the South Pacific (-40, -120), where no real World
-- should ever be, at known distances north of the search centre:
--   w1 ~89 m, w9 ~600 m, w2 ~1 km, w3 ~4 km, w4 ~10 km, w10 ~30 km
--   w5 draft, w6 hidden, w7 deleted, w8 unlisted (all within 500 m)
do $$
declare
  user_a constant uuid := 'a1a1a1a1-0000-4000-8000-00000000000a';
  user_b constant uuid := 'b2b2b2b2-0000-4000-8000-00000000000b';
  center_lat constant double precision := -40.0;
  center_lon constant double precision := -120.0;
  w1 constant uuid := '10000000-0000-4000-8000-000000000001';
  w2 constant uuid := '10000000-0000-4000-8000-000000000002';
  w3 constant uuid := '10000000-0000-4000-8000-000000000003';
  w4 constant uuid := '10000000-0000-4000-8000-000000000004';
  w5 constant uuid := '10000000-0000-4000-8000-000000000005';
  w6 constant uuid := '10000000-0000-4000-8000-000000000006';
  w7 constant uuid := '10000000-0000-4000-8000-000000000007';
  w8 constant uuid := '10000000-0000-4000-8000-000000000008';
  w9 constant uuid := '10000000-0000-4000-8000-000000000009';
  w10 constant uuid := '10000000-0000-4000-8000-000000000010';
  fixture_worlds constant uuid[] := array[w1, w2, w3, w4, w5, w6, w7, w8, w9, w10];
  nearest_four constant uuid[] := array[w1, w9, w2, w3];
  checks integer := 0;
  ids uuid[];
  found_count integer;
  value text;
  distance double precision;
  lat double precision;
  lon double precision;
begin
  ---------------------------------------------------------------------------
  -- Fixtures (as postgres). Profiles come from the sign-up trigger.
  ---------------------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values
    (user_a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'wa@worlds.test', '{"username": "wtest_creator_a"}', now(), now()),
    (user_b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'wb@worlds.test', '{"username": "wtest_creator_b"}', now(), now());

  insert into public.worlds (id, creator_id, title, category, location, visibility, status, published_at)
  select
    v.id,
    v.creator,
    v.title,
    v.category,
    extensions.st_setsrid(
      extensions.st_makepoint(center_lon, center_lat + v.dlat),
      4326
    )::extensions.geography,
    v.visibility,
    v.status,
    case when v.status = 'published' then now() end
  from (
    values
      (w1, user_a, 'Harbor Story', 'story', 0.0008::double precision, 'public', 'published'),
      (w9, user_a, 'Sale 100%_off', 'story', 0.0054, 'public', 'published'),
      (w2, user_a, 'Lighthouse Puzzle', 'puzzle', 0.009, 'public', 'published'),
      (w3, user_a, 'Mural Walk', 'art', 0.036, 'public', 'published'),
      (w4, user_b, 'Far Experience', 'experience', 0.09, 'public', 'published'),
      (w10, user_b, 'Very Far Story', 'story', 0.27, 'public', 'published'),
      (w5, user_a, 'Draft Story', 'story', 0.0018, 'public', 'draft'),
      (w6, user_b, 'Hidden Story', 'story', 0.0027, 'public', 'hidden'),
      (w7, user_a, 'Deleted Story', 'story', 0.0036, 'public', 'deleted'),
      (w8, user_b, 'Unlisted Story', 'story', 0.0045, 'unlisted', 'published')
  ) as v(id, creator, title, category, dlat, visibility, status);

  ---------------------------------------------------------------------------
  -- Configuration
  ---------------------------------------------------------------------------
  if not (select relrowsecurity from pg_class where oid = 'public.worlds'::regclass) then
    raise exception 'FAIL config: row level security is not enabled on public.worlds';
  end if;
  checks := checks + 1;

  if not has_function_privilege(
    'anon',
    'public.get_nearby_worlds(double precision, double precision, integer, text, text, integer, integer)',
    'EXECUTE'
  ) then
    raise exception 'FAIL config: anon cannot call get_nearby_worlds';
  end if;
  checks := checks + 1;

  select count(*) into found_count from pg_proc
  where pronamespace = 'public'::regnamespace and proname = 'get_nearby_worlds';
  if found_count <> 1 then
    raise exception 'FAIL config: expected exactly one get_nearby_worlds, found %', found_count;
  end if;
  checks := checks + 1;

  value := pg_get_function_result(
    'public.get_nearby_worlds(double precision, double precision, integer, text, text, integer, integer)'::regprocedure
  );
  if value ~ '(status|visibility|creator_id|location|unlock_radius|description)' then
    raise exception 'FAIL config: nearby result exposes non-preview columns: %', value;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Signed out (anon)
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  if current_user <> 'anon' or auth.uid() is not null then
    raise exception 'FAIL setup: could not act as anon (current_user %)', current_user;
  end if;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon) as n;
  if ids is distinct from nearest_four then
    raise exception 'FAIL anon: default search should return published public Worlds within 5 km, nearest first; got %', ids;
  end if;
  checks := checks + 1;

  select n.distance_meters, n.latitude, n.longitude into distance, lat, lon
  from public.get_nearby_worlds(center_lat, center_lon) as n
  where n.id = w1;
  if distance is null or distance not between 80 and 100 then
    raise exception 'FAIL anon: distance to w1 should be about 89 m, got %', distance;
  end if;
  checks := checks + 1;
  if abs(lat - (center_lat + 0.0008)) > 1e-9 or abs(lon - center_lon) > 1e-9 then
    raise exception 'FAIL anon: w1 coordinates wrong (lat %, lon %)', lat, lon;
  end if;
  checks := checks + 1;

  select n.creator_username into value
  from public.get_nearby_worlds(center_lat, center_lon) as n
  where n.id = w1;
  if value is distinct from 'wtest_creator_a' then
    raise exception 'FAIL anon: creator username should be wtest_creator_a, got %', value;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, radius_meters => 20000) as n;
  if ids is distinct from array[w1, w9, w2, w3, w4] then
    raise exception 'FAIL anon: 20 km radius should add w4; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, radius_meters => 999999) as n;
  if ids is distinct from array[w1, w9, w2, w3, w4] then
    raise exception 'FAIL anon: radius should be clamped to 25 km (w10 is ~30 km); got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, radius_meters => 1) as n;
  if ids is distinct from array[w1] then
    raise exception 'FAIL anon: radius should be clamped up to 100 m; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, category_filter => 'puzzle') as n;
  if ids is distinct from array[w2] then
    raise exception 'FAIL anon: puzzle filter should return only w2; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, search_text => '  MURAL ') as n;
  if ids is distinct from array[w3] then
    raise exception 'FAIL anon: title search should be trimmed and case-insensitive; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, search_text => '%') as n;
  if ids is distinct from array[w9] then
    raise exception 'FAIL anon: %% in search must be literal; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, search_text => '_') as n;
  if ids is distinct from array[w9] then
    raise exception 'FAIL anon: _ in search must be literal; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, search_text => '   ') as n;
  if ids is distinct from nearest_four then
    raise exception 'FAIL anon: blank search should not filter; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, page_size => 1) as n;
  if ids is distinct from array[w1] then
    raise exception 'FAIL anon: page_size 1 should return w1; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, page_size => 1, page_offset => 1) as n;
  if ids is distinct from array[w9] then
    raise exception 'FAIL anon: second page of size 1 should return w9; got %', ids;
  end if;
  checks := checks + 1;

  select count(*) into found_count
  from public.get_nearby_worlds(center_lat, center_lon, page_size => 0) as n;
  if found_count <> 1 then
    raise exception 'FAIL anon: page_size 0 should be clamped to 1; got % rows', found_count;
  end if;
  checks := checks + 1;

  select array_agg(n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon, page_size => 1, page_offset => -5) as n;
  if ids is distinct from array[w1] then
    raise exception 'FAIL anon: negative offset should be clamped to 0; got %', ids;
  end if;
  checks := checks + 1;

  begin
    perform * from public.get_nearby_worlds(91, 0);
    raise exception 'FAIL anon: latitude 91 was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform * from public.get_nearby_worlds(0, -181);
    raise exception 'FAIL anon: longitude -181 was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform * from public.get_nearby_worlds(null, 0);
    raise exception 'FAIL anon: null latitude was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform * from public.get_nearby_worlds(0, 0, category_filter => 'food');
    raise exception 'FAIL anon: unknown category was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  select count(*) into found_count from public.worlds where id = any(fixture_worlds);
  if found_count <> 6 then
    raise exception 'FAIL anon: should read exactly the 6 published public Worlds, read %', found_count;
  end if;
  checks := checks + 1;

  begin
    insert into public.worlds (creator_id, title, category, location)
    values (user_a, 'Anon World', 'story',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography);
    raise exception 'FAIL anon: insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  reset role;

  ---------------------------------------------------------------------------
  -- Signed in as creator A
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text,
    true
  );
  if current_user <> 'authenticated' or auth.uid() is distinct from user_a then
    raise exception 'FAIL setup: could not act as creator A';
  end if;

  select array_agg(n.id order by n.distance_meters, n.id) into ids
  from public.get_nearby_worlds(center_lat, center_lon) as n;
  if ids is distinct from nearest_four then
    raise exception 'FAIL creator A: nearby must not include own draft or deleted Worlds; got %', ids;
  end if;
  checks := checks + 1;

  select array_agg(id order by id) into ids from public.worlds where id = any(fixture_worlds);
  if ids is distinct from array[w1, w2, w3, w4, w5, w9, w10] then
    raise exception 'FAIL creator A: should read published public Worlds plus own draft only; got %', ids;
  end if;
  checks := checks + 1;

  begin
    update public.worlds set title = 'Changed' where id = w1;
    raise exception 'FAIL creator A: update was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    delete from public.worlds where id = w1;
    raise exception 'FAIL creator A: delete was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    insert into public.worlds (creator_id, title, category, location)
    values (user_a, 'New World', 'story',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography);
    raise exception 'FAIL creator A: insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  reset role;

  ---------------------------------------------------------------------------
  -- Table constraints
  ---------------------------------------------------------------------------
  begin
    insert into public.worlds (creator_id, title, category, location, status)
    values (user_a, 'No Date', 'story',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography,
            'published');
    raise exception 'FAIL constraint: published World without published_at was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    insert into public.worlds (creator_id, title, category, location, unlock_radius_meters)
    values (user_a, 'Tiny Radius', 'story',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography, 10);
    raise exception 'FAIL constraint: unlock radius 10 was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    insert into public.worlds (creator_id, title, category, location)
    values (user_a, 'ab', 'story',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography);
    raise exception 'FAIL constraint: 2-character title was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    insert into public.worlds (creator_id, title, category, location)
    values (user_a, ' Padded', 'story',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography);
    raise exception 'FAIL constraint: untrimmed title was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    insert into public.worlds (creator_id, title, category, location)
    values (user_a, 'Food Trip', 'food',
            extensions.st_setsrid(extensions.st_makepoint(0, 0), 4326)::extensions.geography);
    raise exception 'FAIL constraint: unknown category was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  raise exception 'WORLDS_TESTS_PASSED worlds_test: % checks', checks;
end $$;
