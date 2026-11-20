-- Development seed: published Worlds around one point, so the Explore map has
-- something to show before World creation exists (Checkpoint 4).
--
-- NOT a migration. Run it only on the development project, and only with the
-- product owner's agreement.
--
-- Before running, edit the three values marked EDIT:
--   * center_lat / center_lon: a public, safe place (not a home or school).
--   * creator_username: an existing account. Sign up in the app first.
--
-- Every title starts with "[dev]". To remove them all:
--   delete from public.worlds where title like '[dev] %';
do $$
declare
  center_lat constant double precision := 0;          -- EDIT
  center_lon constant double precision := 0;          -- EDIT
  creator_username constant text := 'your_username';  -- EDIT
  creator uuid;
begin
  if center_lat = 0 and center_lon = 0 then
    raise exception 'Set center_lat and center_lon first.';
  end if;

  select id into creator from public.profiles where username = creator_username;
  if creator is null then
    raise exception 'No profile with username %', creator_username;
  end if;

  insert into public.worlds (creator_id, title, description, category, location, status, published_at)
  select
    creator,
    v.title,
    v.description,
    v.category,
    extensions.st_setsrid(
      extensions.st_makepoint(center_lon + v.dlon, center_lat + v.dlat),
      4326
    )::extensions.geography,
    v.status,
    case when v.status = 'published' then now() end
  from (
    values
      ('[dev] The Old Gate', 'A short story about the gate.', 'story', 0.002::double precision, 0.001::double precision, 'published'),
      ('[dev] Riddle of the Bench', 'Find the answer nearby.', 'puzzle', -0.003, 0.002, 'published'),
      ('[dev] Wall Colours', 'A mural walk.', 'art', 0.004, -0.003, 'published'),
      ('[dev] Morning Loop', 'A short guided walk.', 'experience', -0.001, -0.004, 'published'),
      ('[dev] Corner Tale', 'Another story, about 1 km away.', 'story', 0.008, 0.006, 'published'),
      ('[dev] Lantern Puzzle', 'Count the lanterns.', 'puzzle', -0.012, 0.009, 'published'),
      ('[dev] Far Sculpture', 'About 6 km away: outside the default 5 km search.', 'art', 0.055, 0.0, 'published'),
      ('[dev] Hidden Draft', 'A draft: must never appear on the map.', 'story', 0.001, 0.001, 'draft')
  ) as v(title, description, category, dlat, dlon, status);
end $$;
