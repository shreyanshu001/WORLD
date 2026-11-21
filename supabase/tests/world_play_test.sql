-- Tests for playing Worlds: unlock_world, get_world_play, advance_world,
-- answer_question, restart_world, progress privacy, players' image access,
-- unpublished and hidden Worlds, and the play status in get_world_details.
--
-- How to run: execute this whole file as one statement. It always ends by
-- raising an exception, which rolls back everything it did.
--
-- PASS: the error message is exactly
--   WORLDS_TESTS_PASSED world_play_test: <n> checks
--
-- Fixture Worlds sit in the South Pacific (-42, -122).
do $$
declare
  creator constant uuid := 'e5e5e5e5-0000-4000-8000-00000000000a';
  player constant uuid := 'f6f6f6f6-0000-4000-8000-00000000000b';
  other constant uuid := 'a7a7a7a7-0000-4000-8000-00000000000c';
  claims_creator constant text := json_build_object('sub', 'e5e5e5e5-0000-4000-8000-00000000000a', 'role', 'authenticated')::text;
  claims_player constant text := json_build_object('sub', 'f6f6f6f6-0000-4000-8000-00000000000b', 'role', 'authenticated')::text;
  claims_other constant text := json_build_object('sub', 'a7a7a7a7-0000-4000-8000-00000000000c', 'role', 'authenticated')::text;
  lat constant double precision := -42.0;
  lon constant double precision := -122.0;
  -- Story: intro, choice, left ending, right text, right ending
  sw constant uuid := '30000000-0000-4000-8000-000000000001';
  s_intro constant uuid := '31000000-0000-4000-8000-000000000001';
  s_choice constant uuid := '31000000-0000-4000-8000-000000000002';
  s_left constant uuid := '31000000-0000-4000-8000-000000000003';
  s_right constant uuid := '31000000-0000-4000-8000-000000000004';
  s_right_end constant uuid := '31000000-0000-4000-8000-000000000005';
  o_left constant uuid := '32000000-0000-4000-8000-000000000001';
  o_right constant uuid := '32000000-0000-4000-8000-000000000002';
  -- Puzzle: text, question, image, ending
  pw constant uuid := '30000000-0000-4000-8000-000000000002';
  p_text constant uuid := '33000000-0000-4000-8000-000000000001';
  p_question constant uuid := '33000000-0000-4000-8000-000000000002';
  p_image constant uuid := '33000000-0000-4000-8000-000000000003';
  p_end constant uuid := '33000000-0000-4000-8000-000000000004';
  p_asset constant uuid := '34000000-0000-4000-8000-000000000001';
  -- Registered for the puzzle, but no part uses it.
  p_unused constant uuid := '34000000-0000-4000-8000-000000000002';
  asset_path text;
  unused_path text;
  checks integer := 0;
  result jsonb;
  found_count integer;
begin
  ---------------------------------------------------------------------------
  -- Fixtures: three accounts; the creator builds and publishes two Worlds.
  ---------------------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values
    (creator, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'play-creator@worlds.test', '{"username": "ptest_creator"}', now(), now()),
    (player, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'play-player@worlds.test', '{"username": "ptest_player"}', now(), now()),
    (other, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'play-other@worlds.test', '{"username": "ptest_other"}', now(), now());

  asset_path := creator::text || '/' || pw::text || '/' || p_asset::text || '.jpg';
  unused_path := creator::text || '/' || pw::text || '/' || p_unused::text || '.jpg';

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_creator, true);

  perform public.save_world(jsonb_build_object(
    'id', sw, 'category', 'story', 'title', 'Two Doors', 'description', 'Pick a door.',
    'latitude', lat, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', jsonb_build_array(
      jsonb_build_object('id', s_intro, 'block_type', 'text',
        'content', jsonb_build_object('body', 'Two doors stand before you.')),
      jsonb_build_object('id', s_choice, 'block_type', 'story_choice',
        'content', jsonb_build_object('prompt', 'Which door?', 'options', jsonb_build_array(
          jsonb_build_object('id', o_left, 'label', 'Left', 'destination_block_id', s_left),
          jsonb_build_object('id', o_right, 'label', 'Right', 'destination_block_id', s_right)))),
      jsonb_build_object('id', s_left, 'block_type', 'completion',
        'content', jsonb_build_object('title', 'The garden', 'message', 'You found the garden.')),
      jsonb_build_object('id', s_right, 'block_type', 'text',
        'content', jsonb_build_object('body', 'A long corridor.')),
      jsonb_build_object('id', s_right_end, 'block_type', 'completion',
        'content', jsonb_build_object('title', 'The library', 'message', 'You found the library.'))
    )), '{}'::jsonb);
  perform public.publish_world(sw);

  perform public.save_world(jsonb_build_object(
    'id', pw, 'category', 'puzzle', 'title', 'Keeper Riddle', 'description', 'Who kept it?',
    'latitude', lat + 0.001, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', '[]'::jsonb), '{}'::jsonb);
  reset role;

  insert into storage.objects (bucket_id, name, owner_id, metadata)
  values
    ('world-media', asset_path, creator::text, '{"mimetype": "image/jpeg", "size": 2048}'),
    ('world-media', unused_path, creator::text, '{"mimetype": "image/jpeg", "size": 2048}');

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_creator, true);
  perform public.register_world_asset(p_asset, pw, asset_path);
  perform public.register_world_asset(p_unused, pw, unused_path);
  perform public.save_world(jsonb_build_object(
    'id', pw, 'category', 'puzzle', 'title', 'Keeper Riddle', 'description', 'Who kept it?',
    'latitude', lat + 0.001, 'longitude', lon, 'unlock_radius_meters', 50,
    'blocks', jsonb_build_array(
      jsonb_build_object('id', p_text, 'block_type', 'text',
        'content', jsonb_build_object('body', 'A lighthouse stands here.')),
      jsonb_build_object('id', p_question, 'block_type', 'question',
        'content', jsonb_build_object('prompt', 'Who lived here?', 'hint', 'Two words',
                                      'success_message', 'Right, the keeper!')),
      jsonb_build_object('id', p_image, 'block_type', 'image',
        'content', jsonb_build_object('asset_id', p_asset, 'caption', 'The lamp room')),
      jsonb_build_object('id', p_end, 'block_type', 'completion',
        'content', jsonb_build_object('title', 'Solved', 'message', 'Well done.'))
    )), jsonb_build_object(p_question::text, 'Lighthouse Keeper'));
  result := public.publish_world(pw);
  if result ->> 'status' <> 'published' then
    raise exception 'FAIL setup: puzzle did not publish: %', result;
  end if;
  reset role;

  ---------------------------------------------------------------------------
  -- Configuration
  ---------------------------------------------------------------------------
  if not (select relrowsecurity from pg_class where oid = 'public.world_progress'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'public.world_visits'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'private.world_answer_attempts'::regclass) then
    raise exception 'FAIL config: row level security is off on a play table';
  end if;
  checks := checks + 1;

  if has_function_privilege('anon', 'public.unlock_world(uuid, double precision, double precision, double precision)', 'EXECUTE')
     or has_function_privilege('anon', 'public.get_world_play(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.advance_world(uuid, uuid, uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.answer_question(uuid, uuid, text)', 'EXECUTE')
     or has_function_privilege('anon', 'public.restart_world(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.is_unlocked_world_image(uuid)', 'EXECUTE')
     or has_table_privilege('anon', 'public.world_progress', 'SELECT')
     or has_table_privilege('anon', 'public.world_visits', 'SELECT')
     or has_table_privilege('authenticated', 'public.world_progress', 'UPDATE')
     or has_table_privilege('authenticated', 'public.world_progress', 'INSERT')
     or has_table_privilege('authenticated', 'private.world_answer_attempts', 'SELECT') then
    raise exception 'FAIL config: play grants are wrong';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Signed out: no playing, but published covers and details still work.
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  begin
    perform public.unlock_world(sw, lat, lon, 10);
    raise exception 'FAIL anon: unlock was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  result := public.get_world_details(sw);
  if result -> 'play_status' <> 'null'::jsonb then
    raise exception 'FAIL anon: play status should be null, got %', result -> 'play_status';
  end if;
  checks := checks + 1;

  select count(*) into found_count from storage.objects where name = asset_path;
  if found_count <> 0 then
    raise exception 'FAIL anon: a block image is readable without unlocking';
  end if;
  checks := checks + 1;
  reset role;

  ---------------------------------------------------------------------------
  -- Unlocking
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_player, true);

  result := public.get_world_details(sw);
  if result ->> 'play_status' <> 'locked' then
    raise exception 'FAIL details: expected locked, got %', result;
  end if;
  checks := checks + 1;

  begin
    perform public.get_world_play(sw);
    raise exception 'FAIL play: content served before unlocking';
  exception
    when sqlstate 'WR403' then checks := checks + 1;
  end;

  -- About 222 m away: too far.
  result := public.unlock_world(sw, lat + 0.002, lon, 10);
  if result ->> 'result' <> 'too_far'
     or (result ->> 'distance_meters')::double precision not between 200 and 240
     or (result ->> 'unlock_radius_meters')::int <> 50 then
    raise exception 'FAIL unlock: far away should be too_far: %', result;
  end if;
  checks := checks + 1;

  -- Close enough, but the reading is too vague.
  result := public.unlock_world(sw, lat, lon, 150);
  if result ->> 'result' <> 'inaccurate' then
    raise exception 'FAIL unlock: a 150 m reading should be inaccurate: %', result;
  end if;
  checks := checks + 1;

  select count(*) into found_count from public.world_progress where world_id = sw;
  if found_count <> 0 then
    raise exception 'FAIL unlock: progress created without a successful unlock';
  end if;
  checks := checks + 1;

  -- About 67 m away with 20 m uncertainty: within 50 m + 20 m.
  result := public.unlock_world(sw, lat + 0.0006, lon, 20);
  if result ->> 'result' <> 'unlocked'
     or result #>> '{progress,current_block_id}' <> s_intro::text
     or result #>> '{progress,status}' <> 'in_progress' then
    raise exception 'FAIL unlock: nearby should unlock at the first part: %', result;
  end if;
  checks := checks + 1;

  -- ...but uncertainty counts for at most 25 m: 80 m away fails even at 100 m.
  perform set_config('request.jwt.claims', claims_other, true);
  result := public.unlock_world(sw, lat + 0.00072, lon, 100);
  if result ->> 'result' <> 'too_far' then
    raise exception 'FAIL unlock: uncertainty above 25 m should not count: %', result;
  end if;
  checks := checks + 1;
  perform set_config('request.jwt.claims', claims_player, true);

  perform public.unlock_world(sw, lat, lon, 5);
  select visit_count into found_count from public.world_visits where world_id = sw and user_id = player;
  if found_count <> 2 then
    raise exception 'FAIL unlock: visits should count each successful check, got %', found_count;
  end if;
  checks := checks + 1;

  begin
    perform public.unlock_world(sw, 95, lon, 5);
    raise exception 'FAIL unlock: latitude 95 was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  result := public.get_world_details(sw);
  if result ->> 'play_status' <> 'in_progress' then
    raise exception 'FAIL details: expected in_progress, got %', result -> 'play_status';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Playing the story, with branching
  ---------------------------------------------------------------------------
  result := public.get_world_play(sw);
  if jsonb_array_length(result -> 'blocks') <> 5
     or result #>> '{world,title}' <> 'Two Doors'
     or result #>> '{progress,current_block_id}' <> s_intro::text then
    raise exception 'FAIL play: story content not as expected: %', result;
  end if;
  checks := checks + 1;

  result := public.advance_world(sw, s_choice);
  if (result ->> 'stale')::boolean is not true
     or result #>> '{progress,current_block_id}' <> s_intro::text then
    raise exception 'FAIL advance: a step from the wrong part should be stale: %', result;
  end if;
  checks := checks + 1;

  result := public.advance_world(sw, s_intro);
  if result #>> '{progress,current_block_id}' <> s_choice::text then
    raise exception 'FAIL advance: text should lead to the next part: %', result;
  end if;
  checks := checks + 1;

  begin
    perform public.advance_world(sw, s_choice);
    raise exception 'FAIL advance: a choice was passed without choosing';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.advance_world(sw, s_choice, gen_random_uuid());
    raise exception 'FAIL advance: an unknown option was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  result := public.advance_world(sw, s_choice, o_right);
  if result #>> '{progress,current_block_id}' <> s_right::text then
    raise exception 'FAIL advance: the right option should lead to its part: %', result;
  end if;
  checks := checks + 1;

  -- Retrying the same step (a timeout) changes nothing.
  result := public.advance_world(sw, s_choice, o_right);
  if (result ->> 'stale')::boolean is not true
     or result #>> '{progress,current_block_id}' <> s_right::text then
    raise exception 'FAIL advance: a repeated step should be stale: %', result;
  end if;
  checks := checks + 1;

  -- Opening the World again (a restarted app) resumes at the same part.
  result := public.get_world_play(sw);
  if result #>> '{progress,current_block_id}' <> s_right::text
     or result #> '{progress,path}' <> jsonb_build_array(s_intro, s_choice, s_right) then
    raise exception 'FAIL resume: a fresh load should report the current part: %', result;
  end if;
  checks := checks + 1;

  perform public.advance_world(sw, s_right);
  result := public.advance_world(sw, s_right_end);
  if (result ->> 'completed')::boolean is not true
     or result #>> '{progress,status}' <> 'completed'
     or (result #>> '{progress,completion_count}')::int <> 1
     or result #> '{progress,path}' <> jsonb_build_array(s_intro, s_choice, s_right, s_right_end) then
    raise exception 'FAIL complete: the right branch should finish: %', result;
  end if;
  checks := checks + 1;

  result := public.advance_world(sw, s_right_end);
  if (result #>> '{progress,completion_count}')::int <> 1 then
    raise exception 'FAIL complete: finishing again was counted twice: %', result;
  end if;
  checks := checks + 1;

  if (public.get_world_details(sw)) ->> 'play_status' <> 'completed' then
    raise exception 'FAIL details: expected completed';
  end if;
  checks := checks + 1;

  result := public.restart_world(sw);
  if result ->> 'status' <> 'in_progress' or result ->> 'current_block_id' <> s_intro::text
     or (result ->> 'completion_count')::int <> 1 then
    raise exception 'FAIL restart: %', result;
  end if;
  checks := checks + 1;
  reset role;

  ---------------------------------------------------------------------------
  -- Playing the puzzle: answers checked here, never revealed, limited
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_player, true);

  select count(*) into found_count from storage.objects where name = asset_path;
  if found_count <> 0 then
    raise exception 'FAIL image: block image readable before unlocking';
  end if;
  checks := checks + 1;

  result := public.unlock_world(pw, lat + 0.001, lon, 10);
  if result ->> 'result' <> 'unlocked' then
    raise exception 'FAIL puzzle: unlock failed: %', result;
  end if;

  select count(*) into found_count from storage.objects where name = asset_path;
  if found_count <> 1 then
    raise exception 'FAIL image: block image not readable after unlocking';
  end if;
  checks := checks + 1;

  -- ...but only the images its parts use.
  select count(*) into found_count from storage.objects where name = unused_path;
  if found_count <> 0 then
    raise exception 'FAIL image: an image no part uses is readable by a player';
  end if;
  select count(*) into found_count from public.world_assets where world_id = pw;
  if found_count <> 1 then
    raise exception 'FAIL image: a player should see 1 asset row of the puzzle, saw %', found_count;
  end if;
  checks := checks + 1;

  -- (The title "Keeper Riddle" is public; the answer is "lighthouse keeper".)
  result := public.get_world_play(pw);
  if result::text ~* 'lighthouse keeper|right, the keeper'
     or (result #> '{blocks,1,content}') ? 'success_message' then
    raise exception 'FAIL puzzle: the answer or its success message was served';
  end if;
  if result #>> '{blocks,1,content,hint}' <> 'Two words'
     or result #>> '{assets,0,storage_path}' <> asset_path then
    raise exception 'FAIL puzzle: play content not as expected: %', result;
  end if;
  checks := checks + 1;

  perform public.advance_world(pw, p_text);
  begin
    perform public.advance_world(pw, p_question);
    raise exception 'FAIL puzzle: passed the question without answering';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.answer_question(pw, p_text, 'anything');
    raise exception 'FAIL puzzle: answered a part that is not the current question';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  result := public.answer_question(pw, p_question, 'The cook');
  if (result ->> 'correct')::boolean or (result ->> 'attempts_left')::int <> 4
     or result::text ~* 'keeper' then
    raise exception 'FAIL puzzle: a wrong answer: %', result;
  end if;
  checks := checks + 1;

  for i in 1..4 loop
    perform public.answer_question(pw, p_question, 'wrong ' || i);
  end loop;
  result := public.answer_question(pw, p_question, 'Lighthouse Keeper');
  if (result ->> 'correct')::boolean or (result ->> 'rate_limited')::boolean is not true
     or (result ->> 'retry_after_seconds')::int not between 1 and 600 then
    raise exception 'FAIL puzzle: the sixth attempt should be limited, even if right: %', result;
  end if;
  checks := checks + 1;
  reset role;

  -- Ten minutes later the limit lifts.
  update private.world_answer_attempts
  set attempted_at = attempted_at - interval '11 minutes'
  where user_id = player and block_id = p_question;

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_player, true);
  result := public.answer_question(pw, p_question, '  LIGHTHOUSE   keeper ');
  if not (result ->> 'correct')::boolean or result ->> 'success_message' <> 'Right, the keeper!' then
    raise exception 'FAIL puzzle: a correct answer (any case, extra spaces): %', result;
  end if;
  checks := checks + 1;

  result := public.answer_question(pw, p_question, 'anything');
  if not (result ->> 'correct')::boolean then
    raise exception 'FAIL puzzle: an answered question should stay answered: %', result;
  end if;
  checks := checks + 1;

  result := public.advance_world(pw, p_question);
  if result #>> '{progress,current_block_id}' <> p_image::text then
    raise exception 'FAIL puzzle: after answering, the next part: %', result;
  end if;
  perform public.advance_world(pw, p_image);
  result := public.advance_world(pw, p_end);
  if result #>> '{progress,status}' <> 'completed' then
    raise exception 'FAIL puzzle: should finish: %', result;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Privacy: progress and attempts belong to their account
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims', claims_other, true);
  select count(*) into found_count from public.world_progress;
  if found_count <> 0 then
    raise exception 'FAIL privacy: another account read % progress rows', found_count;
  end if;
  checks := checks + 1;

  begin
    perform public.get_world_play(pw);
    raise exception 'FAIL privacy: content served to an account that never unlocked';
  exception
    when sqlstate 'WR403' then checks := checks + 1;
  end;

  select count(*) into found_count from storage.objects where name in (asset_path, unused_path);
  if found_count <> 0 or public.is_unlocked_world_image(p_asset) then
    raise exception 'FAIL privacy: an image is readable by an account that never unlocked';
  end if;
  checks := checks + 1;

  begin
    perform 1 from private.world_answer_attempts;
    raise exception 'FAIL privacy: answer attempts were readable';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    update public.world_progress set status = 'completed' where user_id = player;
    raise exception 'FAIL privacy: progress was writable';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  perform set_config('request.jwt.claims', claims_creator, true);
  select count(*) into found_count from public.world_progress where world_id = pw;
  if found_count <> 0 then
    raise exception 'FAIL privacy: the creator read a player''s progress';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Unpublished Worlds cannot be played, even after unlocking
  ---------------------------------------------------------------------------
  perform public.unpublish_world(sw);
  perform set_config('request.jwt.claims', claims_player, true);
  begin
    perform public.get_world_play(sw);
    raise exception 'FAIL unpublished: content still served';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.advance_world(sw, s_intro);
    raise exception 'FAIL unpublished: still playable';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.unlock_world(sw, lat, lon, 5);
    raise exception 'FAIL unpublished: still unlockable';
  exception
    when no_data_found then checks := checks + 1;
  end;
  reset role;

  ---------------------------------------------------------------------------
  -- Worlds hidden by moderation: closed to players who had unlocked them,
  -- content, images and details alike
  ---------------------------------------------------------------------------
  update public.worlds set status = 'hidden' where id = pw;

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_player, true);
  begin
    perform public.get_world_play(pw);
    raise exception 'FAIL hidden: content still served';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.restart_world(pw);
    raise exception 'FAIL hidden: still restartable';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.answer_question(pw, p_question, 'Lighthouse Keeper');
    raise exception 'FAIL hidden: answers still checked';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.get_world_details(pw);
    raise exception 'FAIL hidden: details still served to a player';
  exception
    when no_data_found then checks := checks + 1;
  end;

  select count(*) into found_count from storage.objects where name = asset_path;
  if found_count <> 0 then
    raise exception 'FAIL hidden: a block image is still readable by a player';
  end if;
  checks := checks + 1;
  reset role;

  raise exception 'WORLDS_TESTS_PASSED world_play_test: % checks', checks;
end $$;
