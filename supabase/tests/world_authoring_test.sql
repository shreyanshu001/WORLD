-- Tests for World authoring: save_world, publish/unpublish/delete, assets,
-- storage policies, puzzle answer secrecy and get_world_details.
--
-- How to run: execute this whole file as one statement (Supabase SQL editor
-- or the Supabase MCP execute_sql tool). It always ends by raising an
-- exception, which rolls back everything it did.
--
-- PASS: the error message is exactly
--   WORLDS_TESTS_PASSED world_authoring_test: <n> checks
-- Any other message is a FAILURE and names the check that failed.
--
-- Fixture Worlds sit in the South Pacific (-41, -121), where no real World
-- should ever be.
do $$
declare
  user_a constant uuid := 'c3c3c3c3-0000-4000-8000-00000000000a';
  user_b constant uuid := 'd4d4d4d4-0000-4000-8000-00000000000b';
  claims_a constant text := json_build_object('sub', 'c3c3c3c3-0000-4000-8000-00000000000a', 'role', 'authenticated')::text;
  claims_b constant text := json_build_object('sub', 'd4d4d4d4-0000-4000-8000-00000000000b', 'role', 'authenticated')::text;
  lat constant double precision := -41.0;
  lon constant double precision := -121.0;
  -- A's puzzle World and its blocks
  wp constant uuid := '20000000-0000-4000-8000-000000000001';
  bp_text constant uuid := '21000000-0000-4000-8000-000000000001';
  bp_question constant uuid := '21000000-0000-4000-8000-000000000002';
  bp_done constant uuid := '21000000-0000-4000-8000-000000000003';
  -- A's story World and its blocks
  ws constant uuid := '20000000-0000-4000-8000-000000000002';
  bs_intro constant uuid := '22000000-0000-4000-8000-000000000001';
  bs_choice constant uuid := '22000000-0000-4000-8000-000000000002';
  bs_left constant uuid := '22000000-0000-4000-8000-000000000003';
  bs_right constant uuid := '22000000-0000-4000-8000-000000000004';
  opt_left constant uuid := '23000000-0000-4000-8000-000000000001';
  opt_right constant uuid := '23000000-0000-4000-8000-000000000002';
  -- A's art World; B's World
  wa constant uuid := '20000000-0000-4000-8000-000000000003';
  wb constant uuid := '20000000-0000-4000-8000-000000000004';
  -- Assets
  asset_cover constant uuid := '24000000-0000-4000-8000-000000000001';
  asset_other constant uuid := '24000000-0000-4000-8000-000000000002';
  cover_path text;
  secret_answer constant text := 'Lighthouse Keeper';
  checks integer := 0;
  result jsonb;
  found_count integer;
  value text;
  stamp timestamptz;
  puzzle_world jsonb;
  puzzle_blocks jsonb;
  story_world jsonb;
begin
  ---------------------------------------------------------------------------
  -- Fixtures (as postgres). Profiles come from the sign-up trigger.
  ---------------------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values
    (user_a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'authoring-a@worlds.test', '{"username": "atest_creator_a"}', now(), now()),
    (user_b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
     'authoring-b@worlds.test', '{"username": "atest_creator_b"}', now(), now());

  cover_path := user_a::text || '/' || wp::text || '/' || asset_cover::text || '.jpg';

  puzzle_blocks := jsonb_build_array(
    jsonb_build_object('id', bp_text, 'block_type', 'text',
      'content', jsonb_build_object('body', 'Find the old lighthouse.')),
    jsonb_build_object('id', bp_question, 'block_type', 'question',
      'content', jsonb_build_object('prompt', 'Who lived here?', 'hint', 'Two words',
                                    'success_message', 'Correct!')),
    jsonb_build_object('id', bp_done, 'block_type', 'completion',
      'content', jsonb_build_object('title', 'Solved', 'message', 'Well done.'))
  );
  puzzle_world := jsonb_build_object(
    'id', wp, 'category', 'puzzle', 'title', 'Lighthouse Riddle',
    'description', null, 'cover_asset_id', null,
    'latitude', null, 'longitude', null, 'unlock_radius_meters', 50,
    'blocks', '[]'::jsonb
  );

  ---------------------------------------------------------------------------
  -- Configuration
  ---------------------------------------------------------------------------
  if not (select relrowsecurity from pg_class where oid = 'public.world_assets'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'public.world_content_blocks'::regclass)
     or not (select relrowsecurity from pg_class where oid = 'private.world_question_secrets'::regclass) then
    raise exception 'FAIL config: row level security is off on an authoring table';
  end if;
  checks := checks + 1;

  if has_table_privilege('anon', 'private.world_question_secrets', 'SELECT')
     or has_table_privilege('authenticated', 'private.world_question_secrets', 'SELECT')
     or has_table_privilege('authenticated', 'private.world_question_secrets', 'INSERT')
     or has_schema_privilege('authenticated', 'private', 'USAGE')
     or has_schema_privilege('anon', 'private', 'USAGE') then
    raise exception 'FAIL config: API roles can reach question secrets';
  end if;
  checks := checks + 1;

  if has_table_privilege('authenticated', 'public.world_content_blocks', 'INSERT')
     or has_table_privilege('authenticated', 'public.world_content_blocks', 'UPDATE')
     or has_table_privilege('authenticated', 'public.world_content_blocks', 'DELETE')
     or has_table_privilege('authenticated', 'public.world_assets', 'INSERT')
     or has_table_privilege('authenticated', 'public.world_assets', 'DELETE')
     or has_table_privilege('authenticated', 'public.worlds', 'UPDATE')
     or has_table_privilege('anon', 'public.world_content_blocks', 'SELECT') then
    raise exception 'FAIL config: clients have direct write access, or anon can read blocks';
  end if;
  checks := checks + 1;

  if has_function_privilege('anon', 'public.save_world(jsonb, jsonb)', 'EXECUTE')
     or has_function_privilege('anon', 'public.publish_world(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.register_world_asset(uuid, uuid, text)', 'EXECUTE')
     or has_function_privilege('anon', 'public.get_world_draft(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.save_world(jsonb, jsonb)', 'EXECUTE')
     or not has_function_privilege('anon', 'public.get_world_details(uuid, double precision, double precision)', 'EXECUTE') then
    raise exception 'FAIL config: function grants are wrong';
  end if;
  checks := checks + 1;

  if not exists (
    select 1 from storage.buckets
    where id = 'world-media' and not public and file_size_limit = 5242880
      and allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp']
      and array_length(allowed_mime_types, 1) = 3
  ) then
    raise exception 'FAIL config: world-media bucket is missing or misconfigured';
  end if;
  checks := checks + 1;

  -- Answer normalisation: case, whitespace and Unicode compatibility forms.
  if private.normalize_answer('  Café   Au' || chr(160) || 'LAIT  ') <> 'café au lait'
     or private.normalize_answer('Ｃａｆé') <> 'café'
     or private.normalize_answer(chr(64257) || 'sh') <> 'fish' then
    raise exception 'FAIL normalisation: got "%", "%", "%"',
      private.normalize_answer('  Café   Au' || chr(160) || 'LAIT  '),
      private.normalize_answer('Ｃａｆé'), private.normalize_answer(chr(64257) || 'sh');
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Signed out
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  begin
    perform public.save_world(puzzle_world, '{}'::jsonb);
    raise exception 'FAIL anon: save_world was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  reset role;

  ---------------------------------------------------------------------------
  -- Creator A: create, retry and fill a puzzle draft
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  if auth.uid() is distinct from user_a then
    raise exception 'FAIL setup: could not act as creator A';
  end if;

  result := public.save_world(puzzle_world, '{}'::jsonb);
  if result ->> 'status' <> 'draft' or result ->> 'title' <> 'Lighthouse Riddle'
     or result -> 'latitude' <> 'null'::jsonb or jsonb_array_length(result -> 'blocks') <> 0 then
    raise exception 'FAIL A: new draft not returned as expected: %', result;
  end if;
  checks := checks + 1;

  -- A retry with the same id updates the same row.
  perform public.save_world(puzzle_world, '{}'::jsonb);
  select count(*) into found_count from public.worlds where id = wp;
  if found_count <> 1 then
    raise exception 'FAIL A: retrying save created % Worlds', found_count;
  end if;
  checks := checks + 1;

  result := public.save_world(
    jsonb_set(puzzle_world, '{blocks}', puzzle_blocks),
    jsonb_build_object(bp_question::text, '  lighthouse   KEEPER ')
  );
  if jsonb_array_length(result -> 'blocks') <> 3
     or result #>> '{blocks,0,id}' <> bp_text::text
     or result #>> '{blocks,1,block_type}' <> 'question'
     or (result #>> '{blocks,1,has_answer}')::boolean is not true
     or (result #>> '{blocks,0,has_answer}')::boolean is not false then
    raise exception 'FAIL A: blocks not saved as expected: %', result;
  end if;
  checks := checks + 1;

  if result::text ~* 'keeper' then
    raise exception 'FAIL A: the draft returned the answer';
  end if;
  checks := checks + 1;

  select count(*) into found_count from public.world_content_blocks where world_id = wp;
  if found_count <> 3 then
    raise exception 'FAIL A: creator should read own 3 blocks, read %', found_count;
  end if;
  checks := checks + 1;

  begin
    perform 1 from private.world_question_secrets;
    raise exception 'FAIL A: question secrets were readable';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    insert into public.world_content_blocks (id, world_id, block_type, position, content)
    values (gen_random_uuid(), wp, 'text', 9, '{"body": "x"}');
    raise exception 'FAIL A: direct block insert was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  -- Invalid content is refused.
  begin
    perform public.save_world(jsonb_set(puzzle_world, '{blocks}', jsonb_build_array(
      jsonb_build_object('id', bp_question, 'block_type', 'question',
        'content', jsonb_build_object('prompt', 'Who?', 'answer', 'keeper')))), '{}'::jsonb);
    raise exception 'FAIL A: an answer inside block content was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.save_world(jsonb_set(puzzle_world, '{blocks}', jsonb_build_array(
      jsonb_build_object('id', gen_random_uuid(), 'block_type', 'story_choice',
        'content', jsonb_build_object('prompt', 'Which way?', 'options', '[]'::jsonb)))), '{}'::jsonb);
    raise exception 'FAIL A: a story choice was accepted in a puzzle';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.save_world(puzzle_world || '{"status": "published"}'::jsonb, '{}'::jsonb);
    raise exception 'FAIL A: an unknown World key (status) was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.save_world(jsonb_set(puzzle_world, '{blocks}', jsonb_build_array(
      jsonb_build_object('id', gen_random_uuid(), 'block_type', 'text',
        'content', jsonb_build_object('body', repeat('x', 2001))))), '{}'::jsonb);
    raise exception 'FAIL A: a 2,001-character text block was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.save_world(jsonb_set(puzzle_world, '{blocks}', (
      select jsonb_agg(jsonb_build_object('id', gen_random_uuid(), 'block_type', 'text',
                                          'content', jsonb_build_object('body', 'x')))
      from generate_series(1, 31))), '{}'::jsonb);
    raise exception 'FAIL A: 31 blocks were accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.save_world(
      jsonb_set(puzzle_world, '{blocks}', puzzle_blocks),
      jsonb_build_object(bp_text::text, 'not a question'));
    raise exception 'FAIL A: an answer for a text block was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.save_world(puzzle_world || '{"latitude": 95, "longitude": 0}'::jsonb, '{}'::jsonb);
    raise exception 'FAIL A: latitude 95 was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  -- The rejected saves above changed nothing.
  select count(*) into found_count from public.world_content_blocks where world_id = wp;
  if found_count <> 3 then
    raise exception 'FAIL A: a rejected save changed the blocks (now %)', found_count;
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Publishing A's puzzle
  ---------------------------------------------------------------------------
  result := public.publish_world(wp);
  if result ->> 'status' <> 'draft'
     or not (result -> 'problems') @> '[{"code": "location_required"}]'
     or not (result -> 'problems') @> '[{"code": "description_required"}]' then
    raise exception 'FAIL publish: missing location and description not reported: %', result;
  end if;
  checks := checks + 1;

  puzzle_world := puzzle_world || jsonb_build_object(
    'description', 'A short walk to the lighthouse.',
    'latitude', lat, 'longitude', lon, 'blocks', puzzle_blocks
  );

  -- Without an answer the question cannot be published.
  perform public.save_world(puzzle_world || jsonb_build_object('blocks', jsonb_build_array(
    puzzle_blocks -> 0,
    jsonb_build_object('id', '21000000-0000-4000-8000-0000000000aa', 'block_type', 'question',
      'content', jsonb_build_object('prompt', 'Unanswered?')))), '{}'::jsonb);
  result := public.publish_world(wp);
  if not (result -> 'problems') @> '[{"code": "answer_required", "block_id": "21000000-0000-4000-8000-0000000000aa"}]' then
    raise exception 'FAIL publish: a question without an answer was not reported: %', result;
  end if;
  checks := checks + 1;

  -- Back to the full list. The question block was removed above, taking its
  -- answer with it, so the answer is set again.
  perform public.save_world(puzzle_world, jsonb_build_object(bp_question::text, secret_answer));
  result := public.publish_world(wp);
  if result ->> 'status' <> 'published' or jsonb_array_length(result -> 'problems') <> 0
     or result ->> 'published_at' is null then
    raise exception 'FAIL publish: a complete puzzle did not publish: %', result;
  end if;
  stamp := (result ->> 'published_at')::timestamptz;
  checks := checks + 1;

  result := public.publish_world(wp);
  if result ->> 'status' <> 'published' or (result ->> 'published_at')::timestamptz <> stamp then
    raise exception 'FAIL publish: publishing again was not idempotent: %', result;
  end if;
  checks := checks + 1;

  -- A published World must stay complete.
  begin
    perform public.save_world(puzzle_world || '{"blocks": []}'::jsonb, '{}'::jsonb);
    raise exception 'FAIL edit: emptying a published World was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  perform public.save_world(puzzle_world || '{"title": "Lighthouse Riddle II"}'::jsonb, '{}'::jsonb);
  select status, title into value, result from (
    select status, to_jsonb(title) as title from public.worlds where id = wp
  ) as s;
  if value <> 'published' or result <> '"Lighthouse Riddle II"'::jsonb then
    raise exception 'FAIL edit: a valid edit of a published World failed (% %)', value, result;
  end if;
  checks := checks + 1;
  reset role;

  -- Stored answer: a bcrypt hash of the normalised answer, never the text.
  select s.answer_hash into value from private.world_question_secrets as s where s.block_id = bp_question;
  if value is null or value ~* 'keeper'
     or extensions.crypt(private.normalize_answer('  LIGHTHOUSE keeper'), value) <> value then
    raise exception 'FAIL secret: answer not stored as a matching hash';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Discovery and details
  ---------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', '', true);

  select count(*) into found_count from public.get_nearby_worlds(lat, lon) as n where n.id = wp;
  if found_count <> 1 then
    raise exception 'FAIL anon: the published World is not discoverable';
  end if;
  checks := checks + 1;

  result := public.get_world_details(wp, lat + 0.001, lon);
  if result ->> 'title' <> 'Lighthouse Riddle II' or (result ->> 'block_count')::int <> 3
     or (result ->> 'is_creator')::boolean or result ->> 'creator_username' <> 'atest_creator_a'
     or (result ->> 'distance_meters')::double precision not between 100 and 125
     or result ? 'blocks' or result ? 'content' then
    raise exception 'FAIL anon: details not as expected: %', result;
  end if;
  checks := checks + 1;

  if result::text ~* 'keeper|who lived here' then
    raise exception 'FAIL anon: details leaked block content or the answer';
  end if;
  checks := checks + 1;

  begin
    perform 1 from public.world_content_blocks;
    raise exception 'FAIL anon: blocks table was readable';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  reset role;

  ---------------------------------------------------------------------------
  -- Another user (B) cannot read or change A's Worlds
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_b, true);

  begin
    perform public.get_world_draft(wp);
    raise exception 'FAIL B: read A''s draft copy';
  exception
    when no_data_found then checks := checks + 1;
  end;

  begin
    perform public.save_world(puzzle_world || '{"title": "Taken Over"}'::jsonb, '{}'::jsonb);
    raise exception 'FAIL B: saved over A''s World';
  exception
    when no_data_found then checks := checks + 1;
  end;

  begin
    perform public.unpublish_world(wp);
    raise exception 'FAIL B: unpublished A''s World';
  exception
    when no_data_found then checks := checks + 1;
  end;

  begin
    perform public.delete_world(wp);
    raise exception 'FAIL B: deleted A''s World';
  exception
    when no_data_found then checks := checks + 1;
  end;

  -- B cannot hijack A's block ids for a World of their own.
  begin
    perform public.save_world(jsonb_build_object(
      'id', wb, 'category', 'puzzle', 'title', 'B Puzzle',
      'blocks', jsonb_build_array(jsonb_build_object('id', bp_text, 'block_type', 'text',
        'content', jsonb_build_object('body', 'Mine now'))))
    , '{}'::jsonb);
    raise exception 'FAIL B: reused A''s block id';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  select count(*) into found_count from public.world_content_blocks where world_id = wp;
  if found_count <> 0 then
    raise exception 'FAIL B: could read % of A''s blocks', found_count;
  end if;
  checks := checks + 1;

  result := public.get_world_details(wp);
  if (result ->> 'is_creator')::boolean then
    raise exception 'FAIL B: is_creator true for A''s World';
  end if;
  checks := checks + 1;
  reset role;

  if (select title from public.worlds where id = wp) <> 'Lighthouse Riddle II'
     or (select content ->> 'body' from public.world_content_blocks where id = bp_text)
        <> 'Find the old lighthouse.' then
    raise exception 'FAIL B: A''s World changed';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Unpublish
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  result := public.unpublish_world(wp);
  if result ->> 'status' <> 'draft' or (result ->> 'published_at')::timestamptz <> stamp then
    raise exception 'FAIL unpublish: % ', result;
  end if;
  checks := checks + 1;
  reset role;

  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  select count(*) into found_count from public.get_nearby_worlds(lat, lon) as n where n.id = wp;
  if found_count <> 0 then
    raise exception 'FAIL unpublish: World still discoverable';
  end if;
  checks := checks + 1;

  begin
    perform public.get_world_details(wp);
    raise exception 'FAIL unpublish: details still public';
  exception
    when no_data_found then checks := checks + 1;
  end;
  reset role;

  ---------------------------------------------------------------------------
  -- Story branching, reordering and category rules
  ---------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);

  story_world := jsonb_build_object(
    'id', ws, 'category', 'story', 'title', 'Two Paths',
    'description', 'Choose your way.', 'latitude', lat, 'longitude', lon,
    'blocks', jsonb_build_array(
      jsonb_build_object('id', bs_intro, 'block_type', 'text',
        'content', jsonb_build_object('body', 'You reach a fork.')),
      jsonb_build_object('id', bs_choice, 'block_type', 'story_choice',
        'content', jsonb_build_object('prompt', 'Which way?', 'options', jsonb_build_array(
          jsonb_build_object('id', opt_left, 'label', 'Left', 'destination_block_id', bs_left),
          jsonb_build_object('id', opt_right, 'label', 'Right', 'destination_block_id', bs_intro)))),
      jsonb_build_object('id', bs_left, 'block_type', 'completion',
        'content', jsonb_build_object('title', 'Left ending', 'message', 'You went left.')),
      jsonb_build_object('id', bs_right, 'block_type', 'completion',
        'content', jsonb_build_object('title', 'Right ending', 'message', 'You went right.'))
    )
  );

  begin
    perform public.save_world(jsonb_set(story_world, '{blocks,1,content,options,0,destination_block_id}',
      to_jsonb(gen_random_uuid()::text)), '{}'::jsonb);
    raise exception 'FAIL story: a choice leading outside the World was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  -- Saved as a draft, but the backwards choice blocks publishing.
  perform public.save_world(story_world, '{}'::jsonb);
  result := public.publish_world(ws);
  if result ->> 'status' <> 'draft'
     or not (result -> 'problems') @> jsonb_build_array(
       jsonb_build_object('code', 'choice_destination_invalid', 'block_id', bs_choice)) then
    raise exception 'FAIL story: a backwards choice was not reported: %', result;
  end if;
  checks := checks + 1;

  story_world := jsonb_set(story_world, '{blocks,1,content,options,1,destination_block_id}',
    to_jsonb(bs_right::text));
  perform public.save_world(story_world, '{}'::jsonb);
  result := public.publish_world(ws);
  if result ->> 'status' <> 'published' then
    raise exception 'FAIL story: a valid branching story did not publish: %', result;
  end if;
  checks := checks + 1;

  perform public.unpublish_world(ws);

  -- Reorder: swap the two endings. Positions follow the list order.
  story_world := jsonb_set(story_world, '{blocks}', jsonb_build_array(
    story_world #> '{blocks,0}', story_world #> '{blocks,1}',
    story_world #> '{blocks,3}', story_world #> '{blocks,2}'));
  perform public.save_world(story_world, '{}'::jsonb);
  set constraints public.world_content_blocks_position_unique immediate;
  set constraints public.world_content_blocks_position_unique deferred;
  if (select position from public.world_content_blocks where id = bs_right) <> 2
     or (select position from public.world_content_blocks where id = bs_left) <> 3 then
    raise exception 'FAIL reorder: positions did not follow the new order';
  end if;
  checks := checks + 1;

  -- Removing a block deletes it.
  perform public.save_world(jsonb_set(story_world, '{blocks}', jsonb_build_array(
    story_world #> '{blocks,0}')), '{}'::jsonb);
  select count(*) into found_count from public.world_content_blocks where world_id = ws;
  if found_count <> 1 then
    raise exception 'FAIL remove: expected 1 block, found %', found_count;
  end if;
  checks := checks + 1;

  -- Art needs an artwork; an empty World needs content.
  perform public.save_world(jsonb_build_object(
    'id', wa, 'category', 'art', 'title', 'Harbour Mural', 'description', 'Paint.',
    'latitude', lat, 'longitude', lon,
    'blocks', jsonb_build_array(jsonb_build_object('id', gen_random_uuid(), 'block_type', 'text',
      'content', jsonb_build_object('body', 'Context only.'))))
  , '{}'::jsonb);
  result := public.publish_world(wa);
  if not (result -> 'problems') @> '[{"code": "artwork_required"}]' then
    raise exception 'FAIL art: missing artwork not reported: %', result;
  end if;
  checks := checks + 1;

  perform public.save_world(jsonb_build_object(
    'id', wa, 'category', 'art', 'title', 'Harbour Mural', 'description', 'Paint.',
    'latitude', lat, 'longitude', lon, 'blocks', '[]'::jsonb), '{}'::jsonb);
  result := public.publish_world(wa);
  if not (result -> 'problems') @> '[{"code": "content_required"}]' then
    raise exception 'FAIL art: empty World not reported: %', result;
  end if;
  checks := checks + 1;

  -- A question turned into text loses its answer.
  perform public.save_world(puzzle_world || jsonb_build_object('blocks', jsonb_build_array(
    puzzle_blocks -> 0,
    jsonb_build_object('id', bp_question, 'block_type', 'text',
      'content', jsonb_build_object('body', 'No longer a question.')))), '{}'::jsonb);
  reset role;
  if exists (select 1 from private.world_question_secrets where block_id = bp_question) then
    raise exception 'FAIL secret: answer kept after the block stopped being a question';
  end if;
  checks := checks + 1;

  ---------------------------------------------------------------------------
  -- Assets and storage
  ---------------------------------------------------------------------------
  -- Simulate a finished upload: the Storage service writes this row.
  insert into storage.objects (bucket_id, name, owner_id, metadata)
  values
    ('world-media', cover_path, user_a::text,
     '{"mimetype": "image/jpeg", "size": 120000}'),
    ('world-media', user_a::text || '/' || wp::text || '/' || asset_other::text || '.png', user_a::text,
     '{"mimetype": "image/jpeg", "size": 1000}');

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_b, true);
  begin
    perform public.register_world_asset(asset_cover, wp, cover_path);
    raise exception 'FAIL asset: B registered a file in A''s World';
  exception
    when no_data_found then checks := checks + 1;
  end;

  perform set_config('request.jwt.claims', claims_a, true);
  result := public.register_world_asset(asset_cover, wp, cover_path);
  if result ->> 'mime_type' <> 'image/jpeg' or result ->> 'storage_path' <> cover_path then
    raise exception 'FAIL asset: register returned %', result;
  end if;
  checks := checks + 1;

  result := public.register_world_asset(asset_cover, wp, cover_path);
  select count(*) into found_count from public.world_assets where id = asset_cover;
  if found_count <> 1 or result ->> 'id' <> asset_cover::text then
    raise exception 'FAIL asset: registering twice was not idempotent';
  end if;
  checks := checks + 1;

  begin
    perform public.register_world_asset(asset_other, wp,
      user_a::text || '/' || wp::text || '/' || asset_other::text || '.png');
    raise exception 'FAIL asset: a JPEG stored as .png was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.register_world_asset(asset_other, wp,
      user_a::text || '/' || ws::text || '/' || asset_other::text || '.jpg');
    raise exception 'FAIL asset: a path in another World''s folder was accepted';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;

  begin
    perform public.register_world_asset(asset_other, wp,
      user_a::text || '/' || wp::text || '/' || asset_other::text || '.jpg');
    raise exception 'FAIL asset: a file that was never uploaded was accepted';
  exception
    when no_data_found then checks := checks + 1;
  end;

  -- Storage upload rules, checked against the insert policy directly.
  begin
    insert into storage.objects (bucket_id, name, owner_id, metadata)
    values ('world-media', user_a::text || '/' || wb::text || '/' || gen_random_uuid()::text || '.jpg',
            user_a::text, '{}');
    raise exception 'FAIL storage: upload into a folder of a World A does not own was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  begin
    insert into storage.objects (bucket_id, name, owner_id, metadata)
    values ('world-media', user_a::text || '/' || wp::text || '/cover.gif', user_a::text, '{}');
    raise exception 'FAIL storage: a badly named upload was allowed';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  insert into storage.objects (bucket_id, name, owner_id, metadata)
  values ('world-media', user_a::text || '/' || wp::text || '/' || gen_random_uuid()::text || '.webp',
          user_a::text, '{}');
  checks := checks + 1;

  -- The cover makes the file public only while the World is published.
  perform public.save_world(
    puzzle_world || jsonb_build_object('cover_asset_id', asset_cover),
    jsonb_build_object(bp_question::text, secret_answer)
  );
  reset role;

  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  select count(*) into found_count from storage.objects where name = cover_path;
  if found_count <> 0 then
    raise exception 'FAIL storage: anon can read the cover of a draft';
  end if;
  checks := checks + 1;
  reset role;

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  result := public.publish_world(wp);
  if result ->> 'status' <> 'published' then
    raise exception 'FAIL asset: republish failed: %', result;
  end if;

  begin
    perform public.forget_world_asset(asset_cover);
    raise exception 'FAIL asset: forgot an asset still used as the cover';
  exception
    when invalid_parameter_value then checks := checks + 1;
  end;
  reset role;

  set local role anon;
  perform set_config('request.jwt.claims', '', true);
  select count(*) into found_count from storage.objects where name = cover_path;
  if found_count <> 1 then
    raise exception 'FAIL storage: anon cannot read the cover of a published World';
  end if;
  checks := checks + 1;

  result := public.get_world_details(wp);
  if result ->> 'cover_path' <> cover_path then
    raise exception 'FAIL details: cover path missing: %', result;
  end if;
  checks := checks + 1;

  select count(*) into found_count from storage.objects
  where bucket_id = 'world-media' and name like user_a::text || '/%';
  if found_count <> 1 then
    raise exception 'FAIL storage: anon can read % of A''s files, expected only the cover', found_count;
  end if;
  checks := checks + 1;
  reset role;

  set local role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  perform public.save_world(puzzle_world || jsonb_build_object('cover_asset_id', null), '{}'::jsonb);
  value := public.forget_world_asset(asset_cover);
  if value <> cover_path or exists (select 1 from public.world_assets where id = asset_cover) then
    raise exception 'FAIL asset: forgetting an unused asset failed';
  end if;
  checks := checks + 1;
  reset role;

  ---------------------------------------------------------------------------
  -- Moderation and deletion
  ---------------------------------------------------------------------------
  update public.worlds set status = 'hidden' where id = ws;
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_a, true);
  begin
    perform public.save_world(story_world, '{}'::jsonb);
    raise exception 'FAIL hidden: creator edited a hidden World';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;
  begin
    perform public.publish_world(ws);
    raise exception 'FAIL hidden: creator republished a hidden World';
  exception
    when insufficient_privilege then checks := checks + 1;
  end;

  perform public.delete_world(wa);
  begin
    perform public.get_world_draft(wa);
    raise exception 'FAIL delete: deleted World still readable by its creator';
  exception
    when no_data_found then checks := checks + 1;
  end;
  begin
    perform public.save_world(jsonb_build_object('id', wa, 'category', 'art', 'title', 'Back',
                                                 'blocks', '[]'::jsonb), '{}'::jsonb);
    raise exception 'FAIL delete: a deleted World was revived by saving';
  exception
    when no_data_found then checks := checks + 1;
  end;
  reset role;

  ---------------------------------------------------------------------------
  -- Creation limit and table constraints
  ---------------------------------------------------------------------------
  insert into public.worlds (creator_id, title, category)
  select user_b, 'Limit World ' || g, 'story' from generate_series(1, 20) as g;
  set local role authenticated;
  perform set_config('request.jwt.claims', claims_b, true);
  begin
    perform public.save_world(jsonb_build_object('id', gen_random_uuid(), 'category', 'story',
                                                 'title', 'One Too Many', 'blocks', '[]'::jsonb), '{}'::jsonb);
    raise exception 'FAIL limit: a 21st World in a day was accepted';
  exception
    when sqlstate 'WR429' then checks := checks + 1;
  end;
  reset role;

  begin
    insert into public.worlds (creator_id, title, category, status, published_at)
    values (user_a, 'Nowhere', 'story', 'published', now());
    raise exception 'FAIL constraint: published World without a location was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  begin
    insert into public.world_content_blocks (id, world_id, block_type, position, content)
    values (gen_random_uuid(), wp, 'video', 5, '{}');
    raise exception 'FAIL constraint: unknown block type was accepted';
  exception
    when check_violation then checks := checks + 1;
  end;

  raise exception 'WORLDS_TESTS_PASSED world_authoring_test: % checks', checks;
end $$;
