-- Bootstrap and security tests for public.profiles.
--
-- How to run: execute this whole file as one statement, for example in the
-- Supabase SQL editor or with the Supabase MCP execute_sql tool.
--
-- It never leaves data behind. It always ends by raising an exception, which
-- rolls back everything it did, including the test users.
--
-- PASS: the error message is exactly
--   WORLDS_TESTS_PASSED profiles_test: <n> checks
-- Any other message is a FAILURE and names the check that failed.
--
-- Limitation: real sign-ups insert into auth.users as supabase_auth_admin.
-- The postgres role cannot switch to that role, so test users are inserted
-- as postgres. The bootstrap function is security definer, so it runs with
-- the same rights either way.
do $$
declare
  user_a constant uuid := 'aaaaaaaa-aa00-4000-8000-000000000001';
  user_b constant uuid := 'bbbbbbbb-bb00-4000-8000-000000000002';
  user_c constant uuid := 'cccccccc-cc00-4000-8000-000000000003';
  user_d constant uuid := 'dddddddd-dd00-4000-8000-000000000004';
  user_e constant uuid := 'eeeeeeee-ee00-4000-8000-000000000005';
  user_f constant uuid := 'ffffffff-ff00-4000-8000-000000000006';
  all_users constant uuid[] := array[user_a, user_b, user_c, user_d, user_e, user_f];
  generated_name constant text := '^user_[0-9a-f]{10}$';
  checks integer := 0;
  rows_changed integer;
  found_count integer;
  value text;
begin
  ---------------------------------------------------------------------------
  -- Bootstrap: each new auth user gets exactly one profile with a valid name.
  ---------------------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values (user_a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'a@worlds.test', '{"username": "wtest_alice"}', now(), now());
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values (user_b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'b@worlds.test', '{"username": "  WTest_Bob "}', now(), now());
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values (user_c, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'c@worlds.test', '{"username": "wtest_alice"}', now(), now());
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values (user_d, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'd@worlds.test', '{"username": "x!"}', now(), now());
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values (user_e, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'e@worlds.test', '{}', now(), now());

  select username into value from public.profiles where id = user_a;
  if value is distinct from 'wtest_alice' then
    raise exception 'FAIL bootstrap: requested name not used, got %', value;
  end if;
  checks := checks + 1;

  select username into value from public.profiles where id = user_b;
  if value is distinct from 'wtest_bob' then
    raise exception 'FAIL bootstrap: requested name not trimmed and lower-cased, got %', value;
  end if;
  checks := checks + 1;

  select username into value from public.profiles where id = user_c;
  if value is distinct from 'user_cccccccccc' then
    raise exception 'FAIL bootstrap: taken name did not fall back to generated name, got %', value;
  end if;
  checks := checks + 1;

  select username into value from public.profiles where id = user_d;
  if value is distinct from 'user_dddddddddd' then
    raise exception 'FAIL bootstrap: invalid name did not fall back to generated name, got %', value;
  end if;
  checks := checks + 1;

  select username into value from public.profiles where id = user_e;
  if value is distinct from 'user_eeeeeeeeee' then
    raise exception 'FAIL bootstrap: missing name did not get generated name, got %', value;
  end if;
  checks := checks + 1;

  -- Occupy F's first generated name so bootstrap must pick another.
  update public.profiles set username = 'user_ffffffffff' where id = user_d;
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values (user_f, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
          'f@worlds.test', '{}', now(), now());
  select username into value from public.profiles where id = user_f;
  if value is null or value = 'user_ffffffffff' or value !~ generated_name then
    raise exception 'FAIL bootstrap: generated-name collision not resolved, got %', value;
  end if;
  checks := checks + 1;

  select count(*) into found_count from public.profiles where id = any(all_users);
  if found_count <> 6 then
    raise exception 'FAIL bootstrap: expected 6 profiles, found %', found_count;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Configuration: RLS on, internal schema and functions not reachable.
  ---------------------------------------------------------------------------
  if not (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass) then
    raise exception 'FAIL config: row level security is not enabled on public.profiles';
  end if;
  checks := checks + 1;

  if has_schema_privilege('anon', 'private', 'USAGE')
     or has_schema_privilege('authenticated', 'private', 'USAGE') then
    raise exception 'FAIL config: API roles can use the private schema';
  end if;
  checks := checks + 1;

  if has_function_privilege('anon', 'private.handle_new_user()', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.handle_new_user()', 'EXECUTE') then
    raise exception 'FAIL config: API roles can execute private.handle_new_user()';
  end if;
  checks := checks + 1;

  -- Make updated_at old so the trigger's refresh can be observed.
  alter table public.profiles disable trigger profiles_set_updated_at;
  update public.profiles set updated_at = '2000-01-01 00:00:00+00' where id = user_a;
  alter table public.profiles enable trigger profiles_set_updated_at;

  ---------------------------------------------------------------------------
  -- Signed out (anon): can read, cannot write.
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  if current_user <> 'anon' or auth.uid() is not null then
    raise exception 'FAIL setup: could not act as anon (current_user %)', current_user;
  end if;

  select count(*) into found_count from public.profiles where id = any(all_users);
  if found_count <> 6 then
    raise exception 'FAIL anon: expected to read 6 profiles, read %', found_count;
  end if;
  checks := checks + 1;

  begin
    update public.profiles set display_name = 'Anon' where id = user_a;
    raise exception 'FAIL anon: update was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    insert into public.profiles (id, username) values (gen_random_uuid(), 'wtest_anon');
    raise exception 'FAIL anon: insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  reset role;

  ---------------------------------------------------------------------------
  -- Signed in as A: can read all, update only own permitted columns.
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text,
    true
  );
  if current_user <> 'authenticated' or auth.uid() is distinct from user_a then
    raise exception 'FAIL setup: could not act as user A (current_user %, uid %)', current_user, auth.uid();
  end if;

  select count(*) into found_count from public.profiles where id = any(all_users);
  if found_count <> 6 then
    raise exception 'FAIL user A: expected to read 6 profiles, read %', found_count;
  end if;
  checks := checks + 1;

  -- Positive control: A can update their own profile.
  update public.profiles set display_name = 'Alice' where id = user_a;
  get diagnostics rows_changed = row_count;
  if rows_changed <> 1 then
    raise exception 'FAIL user A: could not update own display_name (% rows)', rows_changed;
  end if;
  checks := checks + 1;

  select updated_at::text into value from public.profiles where id = user_a;
  if value::timestamptz <= '2001-01-01 00:00:00+00'::timestamptz then
    raise exception 'FAIL user A: updated_at was not refreshed, still %', value;
  end if;
  checks := checks + 1;

  -- A cannot change B's profile: the row is filtered out, nothing changes.
  update public.profiles set display_name = 'Hacked' where id = user_b;
  get diagnostics rows_changed = row_count;
  if rows_changed <> 0 then
    raise exception 'FAIL user A: updated user B''s profile (% rows)', rows_changed;
  end if;
  checks := checks + 1;

  begin
    update public.profiles set avatar_path = 'someone/else.png' where id = user_a;
    raise exception 'FAIL user A: avatar_path update was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    update public.profiles set id = user_b where id = user_a;
    raise exception 'FAIL user A: id update was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    update public.profiles set created_at = now() where id = user_a;
    raise exception 'FAIL user A: created_at update was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    update public.profiles set updated_at = now() where id = user_a;
    raise exception 'FAIL user A: updated_at update was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    insert into public.profiles (id, username) values (gen_random_uuid(), 'wtest_extra');
    raise exception 'FAIL user A: insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    delete from public.profiles where id = user_a;
    raise exception 'FAIL user A: delete was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    update public.profiles set username = 'Bad Name' where id = user_a;
    raise exception 'FAIL user A: invalid username was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    update public.profiles set username = 'wtest_bob' where id = user_a;
    raise exception 'FAIL user A: duplicate username was accepted';
  exception
    when unique_violation then checks := checks + 1;
  end;

  begin
    update public.profiles set display_name = ' Alice' where id = user_a;
    raise exception 'FAIL user A: untrimmed display_name was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    update public.profiles set display_name = '' where id = user_a;
    raise exception 'FAIL user A: empty display_name was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    update public.profiles set display_name = repeat('a', 51) where id = user_a;
    raise exception 'FAIL user A: 51-character display_name was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    update public.profiles set bio = repeat('a', 281) where id = user_a;
    raise exception 'FAIL user A: 281-character bio was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  -- Positive controls for the limits.
  update public.profiles
    set username = 'wtest_alice2', display_name = repeat('a', 50), bio = repeat('a', 280)
    where id = user_a;
  get diagnostics rows_changed = row_count;
  if rows_changed <> 1 then
    raise exception 'FAIL user A: valid values at the limits were rejected (% rows)', rows_changed;
  end if;
  checks := checks + 1;

  update public.profiles set display_name = null, bio = null where id = user_a;
  get diagnostics rows_changed = row_count;
  if rows_changed <> 1 then
    raise exception 'FAIL user A: could not clear optional fields (% rows)', rows_changed;
  end if;
  checks := checks + 1;

  reset role;

  ---------------------------------------------------------------------------
  -- B's profile is untouched by A's attempts.
  ---------------------------------------------------------------------------
  select display_name into value from public.profiles where id = user_b;
  if value is not null then
    raise exception 'FAIL user A: user B''s display_name changed to %', value;
  end if;
  checks := checks + 1;

  raise exception 'WORLDS_TESTS_PASSED profiles_test: % checks', checks;
end $$;
