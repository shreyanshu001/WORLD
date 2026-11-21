-- Tests for saved Worlds, reports, moderation and profile pages:
-- set_world_saved, get_saved_worlds, report_world, the private moderation
-- functions and their log, get_profile_page and is_saved in details.
--
-- How to run: execute this whole file as one statement. It always ends by
-- raising an exception, which rolls back everything it did.
--
-- PASS: the error message is exactly
--   WORLDS_TESTS_PASSED community_test: <n> checks
--
-- Fixture Worlds sit in the South Pacific (-43, -123).
do $$
declare
  creator constant uuid := 'c6c6c6c6-0000-4000-8000-00000000000a';
  saver constant uuid := 'd7d7d7d7-0000-4000-8000-00000000000b';
  other constant uuid := 'e8e8e8e8-0000-4000-8000-00000000000c';
  claims_creator constant text := json_build_object('sub', 'c6c6c6c6-0000-4000-8000-00000000000a', 'role', 'authenticated')::text;
  claims_saver constant text := json_build_object('sub', 'd7d7d7d7-0000-4000-8000-00000000000b', 'role', 'authenticated')::text;
  claims_other constant text := json_build_object('sub', 'e8e8e8e8-0000-4000-8000-00000000000c', 'role', 'authenticated')::text;
  lat constant double precision := -43.0;
  lon constant double precision := -123.0;
  -- Two published stories and a draft, all by the creator.
  w1 constant uuid := '40000000-0000-4000-8000-000000000001';
  w2 constant uuid := '40000000-0000-4000-8000-000000000002';
  w3 constant uuid := '40000000-0000-4000-8000-000000000003';
  b1 constant uuid := '41000000-0000-4000-8000-000000000001';
  b2 constant uuid := '41000000-0000-4000-8000-000000000002';
  checks integer := 0;
  result jsonb;
  found_count integer;
  value text;
begin
  ---------------------------------------------------------------------------
  -- Fixtures
  ---------------------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values
    (creator, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'community-creator@worlds.test', '{"username": "ctest_creator"}', now(), now()),
    (saver, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'community-saver@worlds.test', '{"username": "ctest_saver"}', now(), now()),
    (other, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'community-other@worlds.test', '{"username": "ctest_other"}', now(), now());
  update public.profiles set display_name = 'Cara', bio = 'Makes harbour walks.' where id = creator;

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_creator, true);
  perform public.save_world(jsonb_build_object(
    'id', w1, 'category', 'story', 'title', 'Harbour Gate', 'description', 'By the old gate.',
    'latitude', lat, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', jsonb_build_array(jsonb_build_object('id', b1, 'block_type', 'text',
      'content', jsonb_build_object('body', 'The gate creaks.')))), '{}'::jsonb);
  perform public.publish_world(w1);
  perform public.save_world(jsonb_build_object(
    'id', w2, 'category', 'story', 'title', 'Old Mill', 'description', 'By the mill.',
    'latitude', lat + 0.01, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', jsonb_build_array(jsonb_build_object('id', b2, 'block_type', 'text',
      'content', jsonb_build_object('body', 'The wheel turns.')))), '{}'::jsonb);
  result := public.publish_world(w2);
  if result ->> 'status' <> 'published' then
    raise exception 'FAIL setup: the second World did not publish: %', result;
  end if;
  perform public.save_world(jsonb_build_object(
    'id', w3, 'category', 'story', 'title', 'Unfinished', 'blocks', '[]'::jsonb), '{}'::jsonb);
  reset role;
  -- w2 was published after w1.
  update public.worlds set published_at = now() - interval '1 hour' where id = w1;

  ---------------------------------------------------------------------------
  -- Configuration
  ---------------------------------------------------------------------------
  if not (select relrowsecurity from pg_class where oid = 'public.saved_worlds'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'public.world_reports'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'private.moderation_actions'::regclass) then
    raise exception 'FAIL config: row level security is off on a table';
  end if;
  checks := checks + 1;

  if has_function_privilege('anon', 'public.set_world_saved(uuid, boolean)', 'EXECUTE')
     or has_function_privilege('anon', 'public.get_saved_worlds(integer, integer, double precision, double precision)', 'EXECUTE')
     or has_function_privilege('anon', 'public.report_world(uuid, text, text)', 'EXECUTE')
     or not has_function_privilege('anon', 'public.get_profile_page(text, integer, integer)', 'EXECUTE')
     or has_table_privilege('anon', 'public.saved_worlds', 'SELECT')
     or has_table_privilege('authenticated', 'public.saved_worlds', 'INSERT')
     or has_table_privilege('authenticated', 'public.saved_worlds', 'DELETE')
     or has_table_privilege('authenticated', 'public.world_reports', 'INSERT')
     or has_table_privilege('authenticated', 'public.world_reports', 'UPDATE')
     or has_column_privilege('authenticated', 'public.world_reports', 'status', 'SELECT')
     or has_column_privilege('anon', 'public.world_reports', 'reason', 'SELECT') then
    raise exception 'FAIL config: grants for saving or reporting are wrong';
  end if;
  checks := checks + 1;

  if has_function_privilege('authenticated', 'private.hide_world(uuid, text, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.restore_world(uuid, text, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.remove_world(uuid, text, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.dismiss_reports(uuid, text, text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'private.moderate_world(uuid, text, text, text)', 'EXECUTE')
     or has_function_privilege('anon', 'private.moderation_queue()', 'EXECUTE')
     or has_table_privilege('authenticated', 'private.moderation_actions', 'SELECT')
     or has_schema_privilege('authenticated', 'private', 'USAGE') then
    raise exception 'FAIL config: API roles can reach moderation';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Profile pages
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  result := public.get_profile_page('  CTEST_Creator ');
  select string_agg(k, ',' order by k) into value from jsonb_object_keys(result) as k;
  if value <> 'bio,completed_count,discovered_count,display_name,draft_count,has_more,is_own,published_count,username,worlds' then
    raise exception 'FAIL profile: unexpected fields: %', value;
  end if;
  checks := checks + 1;

  if result ->> 'username' <> 'ctest_creator' or result ->> 'display_name' <> 'Cara'
     or (result ->> 'is_own')::boolean or (result ->> 'published_count')::int <> 2
     or result -> 'draft_count' <> 'null'::jsonb or result -> 'discovered_count' <> 'null'::jsonb
     or result -> 'completed_count' <> 'null'::jsonb
     or result #>> '{worlds,0,id}' <> w2::text or result #>> '{worlds,1,title}' <> 'Harbour Gate'
     or jsonb_array_length(result -> 'worlds') <> 2 or (result ->> 'has_more')::boolean then
    raise exception 'FAIL profile: public page not as expected: %', result;
  end if;
  checks := checks + 1;

  result := public.get_profile_page('ctest_creator', 1, 1);
  if jsonb_array_length(result -> 'worlds') <> 1 or result #>> '{worlds,0,id}' <> w1::text
     or (result ->> 'has_more')::boolean then
    raise exception 'FAIL profile: second page of one: %', result;
  end if;
  result := public.get_profile_page('ctest_creator', 1);
  if jsonb_array_length(result -> 'worlds') <> 1 or not (result ->> 'has_more')::boolean then
    raise exception 'FAIL profile: first page of one should say there is more: %', result;
  end if;
  checks := checks + 1;

  begin
    perform public.get_profile_page('nobody_here');
    raise exception 'FAIL profile: an unknown username returned a page';
  exception
    when no_data_found then checks := checks + 1;
  end;

  result := public.get_world_details(w1);
  if result -> 'is_saved' <> 'null'::jsonb then
    raise exception 'FAIL details: is_saved should be null signed out: %', result -> 'is_saved';
  end if;
  checks := checks + 1;

  begin
    perform public.set_world_saved(w1, true);
    raise exception 'FAIL anon: saving was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  begin
    perform public.report_world(w1, 'other');
    raise exception 'FAIL anon: reporting was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  reset role;

  -- The saver discovers and finishes one World; only they see those counts.
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_saver, true);
  perform public.unlock_world(w2, lat + 0.01, lon, 5);
  perform public.advance_world(w2, b2);
  result := public.get_profile_page('ctest_saver');
  if not (result ->> 'is_own')::boolean or (result ->> 'discovered_count')::int <> 1
     or (result ->> 'completed_count')::int <> 1 or (result ->> 'published_count')::int <> 0
     or (result ->> 'draft_count')::int <> 0 then
    raise exception 'FAIL profile: own counts: %', result;
  end if;
  checks := checks + 1;

  perform set_config('request.jwt.claims', claims_creator, true);
  result := public.get_profile_page('ctest_saver');
  if (result ->> 'is_own')::boolean or result -> 'discovered_count' <> 'null'::jsonb
     or result -> 'completed_count' <> 'null'::jsonb then
    raise exception 'FAIL profile: someone else saw private counts: %', result;
  end if;
  result := public.get_profile_page('ctest_creator');
  if (result ->> 'draft_count')::int <> 1 or (result ->> 'published_count')::int <> 2 then
    raise exception 'FAIL profile: creator counts: %', result;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Saving
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims', claims_saver, true);
  if (public.get_world_details(w1) ->> 'is_saved')::boolean then
    raise exception 'FAIL save: is_saved true before saving';
  end if;
  result := public.set_world_saved(w1, true);
  perform public.set_world_saved(w1, true);
  select count(*) into found_count from public.saved_worlds where world_id = w1;
  if not (result ->> 'saved')::boolean or found_count <> 1
     or not (public.get_world_details(w1) ->> 'is_saved')::boolean then
    raise exception 'FAIL save: saving twice should leave one row and say saved';
  end if;
  checks := checks + 1;

  begin
    perform public.set_world_saved(w3, true);
    raise exception 'FAIL save: a draft was saved';
  exception
    when no_data_found then checks := checks + 1;
  end;

  perform public.set_world_saved(w2, true);
  reset role;
  update public.saved_worlds set created_at = now() - interval '1 hour' where world_id = w1;
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_saver, true);

  result := public.get_saved_worlds(20, 0, lat, lon);
  if jsonb_array_length(result -> 'items') <> 2
     or result #>> '{items,0,id}' <> w2::text or result #>> '{items,1,title}' <> 'Harbour Gate'
     or result #>> '{items,1,creator_username}' <> 'ctest_creator'
     or result #>> '{items,1,creator_display_name}' <> 'Cara'
     or (result #>> '{items,1,distance_meters}')::double precision > 1
     or (result #>> '{items,0,distance_meters}')::double precision not between 1000 and 1200
     or (result ->> 'has_more')::boolean or (result ->> 'unavailable')::int <> 0 then
    raise exception 'FAIL saved list: %', result;
  end if;
  checks := checks + 1;

  result := public.get_saved_worlds(1);
  if jsonb_array_length(result -> 'items') <> 1 or result #>> '{items,0,id}' <> w2::text
     or not (result ->> 'has_more')::boolean
     or result #> '{items,0,distance_meters}' <> 'null'::jsonb then
    raise exception 'FAIL saved list: first page of one: %', result;
  end if;
  result := public.get_saved_worlds(1, 1);
  if result #>> '{items,0,id}' <> w1::text or (result ->> 'has_more')::boolean then
    raise exception 'FAIL saved list: second page of one: %', result;
  end if;
  checks := checks + 1;

  begin
    insert into public.saved_worlds (user_id, world_id) values (saver, w3);
    raise exception 'FAIL save: direct insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  -- Nobody else sees a saved list, not even the creator of the Worlds.
  perform set_config('request.jwt.claims', claims_other, true);
  select count(*) into found_count from public.saved_worlds;
  if found_count <> 0 or jsonb_array_length(public.get_saved_worlds() -> 'items') <> 0 then
    raise exception 'FAIL privacy: another account saw saved Worlds';
  end if;
  perform set_config('request.jwt.claims', claims_creator, true);
  select count(*) into found_count from public.saved_worlds;
  if found_count <> 0 then
    raise exception 'FAIL privacy: the creator saw who saved their World';
  end if;
  checks := checks + 1;

  -- An unpublished World leaves the list but stays saved.
  perform public.unpublish_world(w1);
  perform set_config('request.jwt.claims', claims_saver, true);
  result := public.get_saved_worlds();
  if jsonb_array_length(result -> 'items') <> 1 or (result ->> 'unavailable')::int <> 1 then
    raise exception 'FAIL saved list: an unpublished World should be counted, not listed: %', result;
  end if;
  perform set_config('request.jwt.claims', claims_creator, true);
  perform public.publish_world(w1);
  perform set_config('request.jwt.claims', claims_saver, true);
  if jsonb_array_length(public.get_saved_worlds() -> 'items') <> 2 then
    raise exception 'FAIL saved list: a republished World should come back';
  end if;
  checks := checks + 1;

  result := public.set_world_saved(w2, false);
  perform public.set_world_saved(w2, false);
  if (result ->> 'saved')::boolean or jsonb_array_length(public.get_saved_worlds() -> 'items') <> 1 then
    raise exception 'FAIL save: removing should leave one saved World';
  end if;
  checks := checks + 1;
  reset role;

  -- The list holds 500 at most. (Another account fills up, so the saver's
  -- list stays as it is for the checks below.)
  insert into public.worlds (creator_id, title, category)
  select saver, 'Bulk ' || g, 'story' from generate_series(1, 500) as g;
  insert into public.saved_worlds (user_id, world_id)
  select other, x.id from public.worlds as x where x.creator_id = saver;
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_other, true);
  begin
    perform public.set_world_saved(w2, true);
    raise exception 'FAIL save: a 501st World was saved';
  exception
    when sqlstate 'WR429' then checks := checks + 1;
  end;
  reset role;

  ---------------------------------------------------------------------------
  -- Reporting
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_saver, true);
  begin
    perform public.report_world(w1, 'boring');
    raise exception 'FAIL report: an unknown reason was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  begin
    perform public.report_world(w1, 'other', repeat('x', 501));
    raise exception 'FAIL report: 501 characters of details were accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  begin
    perform public.report_world(w3, 'other');
    raise exception 'FAIL report: a draft was reported';
  exception
    when no_data_found then checks := checks + 1;
  end;

  result := public.report_world(w1, 'unsafe_or_private_place', '  Blocks a private gate.  ');
  if not (result ->> 'reported')::boolean or (result ->> 'already_reported')::boolean then
    raise exception 'FAIL report: first report: %', result;
  end if;
  result := public.report_world(w1, 'other', 'Again');
  select count(id), min(description) into found_count, value
  from public.world_reports where world_id = w1;
  if not (result ->> 'already_reported')::boolean or found_count <> 1
     or value <> 'Blocks a private gate.' then
    raise exception 'FAIL report: a second report should change nothing: % % %', result, found_count, value;
  end if;
  checks := checks + 1;

  begin
    perform 1 from public.world_reports where status = 'pending';
    raise exception 'FAIL report: the reporter could read the moderation status';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  begin
    insert into public.world_reports (world_id, reporter_id, reason) values (w2, saver, 'other');
    raise exception 'FAIL report: direct insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  -- The creator cannot report their own World, and sees no reports of it.
  perform set_config('request.jwt.claims', claims_creator, true);
  begin
    perform public.report_world(w1, 'other');
    raise exception 'FAIL report: a creator reported their own World';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  select count(id) into found_count from public.world_reports;
  if found_count <> 0 then
    raise exception 'FAIL privacy: the creator saw % report(s)', found_count;
  end if;
  perform set_config('request.jwt.claims', claims_other, true);
  select count(id) into found_count from public.world_reports;
  if found_count <> 0 then
    raise exception 'FAIL privacy: another account saw % report(s)', found_count;
  end if;
  checks := checks + 1;
  reset role;

  -- Ten reports a day per account. (Nine closed ones of the draft, so the
  -- reports of w1 and w2 stay as they are for the checks below.)
  insert into public.world_reports (world_id, reporter_id, reason, status)
  select w3, saver, 'other', 'dismissed' from generate_series(1, 9);
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_saver, true);
  begin
    perform public.report_world(w2, 'spam_or_misleading');
    raise exception 'FAIL report: an eleventh report in a day was accepted';
  exception
    when sqlstate 'WR429' then checks := checks + 1;
  end;
  perform set_config('request.jwt.claims', claims_other, true);
  result := public.report_world(w2, 'spam_or_misleading');
  if (result ->> 'already_reported')::boolean then
    raise exception 'FAIL report: the limit should be per account: %', result;
  end if;
  checks := checks + 1;
  reset role;

  ---------------------------------------------------------------------------
  -- Moderation (as the project owner in the SQL editor)
  ---------------------------------------------------------------------------
  -- (Counted for the fixture Worlds only: the real queue and log may hold
  -- rows of their own.)
  select count(*), min(q.reporter) into found_count, value
  from private.moderation_queue() as q where q.world_id = w1;
  if found_count <> 1 or value <> 'ctest_saver'
     or (select count(*) from private.moderation_queue() as q where q.world_id in (w1, w2)) <> 2 then
    raise exception 'FAIL queue: expected one pending report of w1 by the saver, two in all';
  end if;
  checks := checks + 1;

  -- A reason is required, and nothing changes without one.
  begin
    perform private.hide_world(w1, 'owner', '  ');
    raise exception 'FAIL moderation: a hide without a note was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;
  if (select status from public.worlds where id = w1) <> 'published' then
    raise exception 'FAIL moderation: a refused hide still changed the World';
  end if;

  perform private.hide_world(w1, 'owner', 'Reported: blocks a private gate');
  if (select status from public.worlds where id = w1) <> 'hidden'
     or (select status from public.world_reports where world_id = w1) <> 'actioned'
     or not exists (
       select 1 from private.moderation_actions as a
       where a.world_id = w1 and a.action = 'hide' and a.moderator = 'owner'
         and a.previous_status = 'published' and a.new_status = 'hidden'
         and a.reports_closed = 1 and a.world_title = 'Harbour Gate'
     ) then
    raise exception 'FAIL moderation: hide did not hide, close the report and log';
  end if;
  checks := checks + 1;

  -- Hidden means gone for everyone but its creator, who cannot undo it.
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  select count(*) into found_count from public.get_nearby_worlds(lat, lon) as n where n.id = w1;
  if found_count <> 0 or (public.get_profile_page('ctest_creator') ->> 'published_count')::int <> 1 then
    raise exception 'FAIL hidden: still in discovery or on the profile page';
  end if;
  checks := checks + 1;
  reset role;

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_saver, true);
  begin
    perform public.get_world_details(w1);
    raise exception 'FAIL hidden: details still served';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.unlock_world(w1, lat, lon, 5);
    raise exception 'FAIL hidden: still unlockable';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.set_world_saved(w1, true);
    raise exception 'FAIL hidden: could be saved';
  exception
    when no_data_found then checks := checks + 1;
  end;
  result := public.get_saved_worlds();
  if jsonb_array_length(result -> 'items') <> 0 or (result ->> 'unavailable')::int <> 1 then
    raise exception 'FAIL hidden: should leave the saved list: %', result;
  end if;
  checks := checks + 1;

  perform set_config('request.jwt.claims', claims_creator, true);
  if public.get_world_details(w1) ->> 'status' <> 'hidden' then
    raise exception 'FAIL hidden: the creator should still see its state';
  end if;
  begin
    perform public.publish_world(w1);
    raise exception 'FAIL hidden: the creator republished it';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  begin
    perform public.delete_world(w1);
    raise exception 'FAIL hidden: the creator deleted it';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  begin
    perform private.restore_world(w1, 'creator', 'Let me back in');
    raise exception 'FAIL moderation: an API role ran a moderation function';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  begin
    perform 1 from private.moderation_actions;
    raise exception 'FAIL moderation: an API role read the log';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  reset role;

  -- Restore: published again, because it was and is still complete.
  perform private.restore_world(w1, 'owner', 'Checked on site: a public path');
  set local role anon;
  select count(*) into found_count from public.get_nearby_worlds(lat, lon) as n where n.id = w1;
  reset role;
  if (select status from public.worlds where id = w1) <> 'published' or found_count <> 1 then
    raise exception 'FAIL moderation: restore did not put the World back';
  end if;
  checks := checks + 1;

  -- Dismiss: the report is closed, the World untouched.
  perform private.dismiss_reports(w2, 'owner', 'Not a violation');
  if (select status from public.world_reports where world_id = w2) <> 'dismissed'
     or (select status from public.worlds where id = w2) <> 'published'
     or (select count(*) from private.moderation_queue() as q where q.world_id in (w1, w2)) <> 0 then
    raise exception 'FAIL moderation: dismiss';
  end if;
  checks := checks + 1;

  -- Remove: deleted for good, even for its creator.
  perform private.remove_world(w2, 'owner', 'Spam');
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_creator, true);
  begin
    perform public.get_world_draft(w2);
    raise exception 'FAIL moderation: a removed World is still readable by its creator';
  exception
    when no_data_found then checks := checks + 1;
  end;
  reset role;

  select count(*), string_agg(a.action, ',' order by a.id) into found_count, value
  from private.moderation_actions as a where a.world_id in (w1, w2);
  if found_count <> 4 or value <> 'hide,restore,dismiss_reports,remove' then
    raise exception 'FAIL moderation: the log should hold the four actions, got %', value;
  end if;
  checks := checks + 1;

  raise exception 'WORLDS_TESTS_PASSED community_test: % checks', checks;
end $$;
