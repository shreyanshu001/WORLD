-- Worlds and nearby discovery (docs/DATABASE.md).
-- This migration adds the table, public read access and the nearby query.
-- Creating, editing and publishing arrive in Checkpoint 4.

create table public.worlds (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles (id) on delete cascade,
  title text not null
    constraint worlds_title_format check (
      title = btrim(title) and char_length(title) between 3 and 80
    ),
  description text
    constraint worlds_description_length check (
      description is null or char_length(description) <= 2000
    ),
  -- The foreign key to world_assets is added with that table in Checkpoint 4.
  cover_asset_id uuid,
  category text not null
    constraint worlds_category_check check (
      category in ('story', 'puzzle', 'art', 'experience')
    ),
  location extensions.geography(point, 4326) not null,
  unlock_radius_meters integer not null default 50
    constraint worlds_unlock_radius_range check (unlock_radius_meters between 25 and 150),
  visibility text not null default 'public'
    constraint worlds_visibility_check check (visibility in ('public', 'unlisted')),
  status text not null default 'draft'
    constraint worlds_status_check check (
      status in ('draft', 'published', 'hidden', 'deleted')
    ),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint worlds_published_has_date check (status <> 'published' or published_at is not null)
);

comment on table public.worlds is
  'A geolocated experience. Only published public Worlds are discoverable.';

create index worlds_location_idx on public.worlds using gist (location);
create index worlds_discovery_idx on public.worlds (status, visibility, category);
create index worlds_creator_idx on public.worlds (creator_id, created_at desc);

alter table public.worlds enable row level security;

-- Read-only for clients in this checkpoint.
revoke all on table public.worlds from anon, authenticated;
grant select on table public.worlds to anon, authenticated;

-- One policy, so signed-in users are not evaluated against two permissive
-- policies. Unlisted Worlds are not readable here; direct-link access is
-- decided in Checkpoint 4 (docs/REPOSITORY_AUDIT.md, gap G1).
create policy "Published public Worlds, and creators' own Worlds, are readable"
  on public.worlds
  for select
  to anon, authenticated
  using (
    (status = 'published' and visibility = 'public')
    or ((select auth.uid()) = creator_id and status <> 'deleted')
  );

create trigger worlds_set_updated_at
  before update on public.worlds
  for each row
  execute function private.set_updated_at();

-- Nearby discovery. Returns preview fields of published public Worlds only,
-- nearest first. The server clamps every limit; distance is computed here,
-- never on the device.
--   radius_meters: 100 to 25,000 (default 5,000)
--   page_size: 1 to 100 (default 50); page_offset: 0 to 1,000
--   search_text: case-insensitive title match; % and _ are literal
create function public.get_nearby_worlds(
  user_lat double precision,
  user_lon double precision,
  radius_meters integer default 5000,
  category_filter text default null,
  search_text text default null,
  page_size integer default 50,
  page_offset integer default 0
)
returns table (
  id uuid,
  title text,
  category text,
  latitude double precision,
  longitude double precision,
  distance_meters double precision,
  creator_username text,
  creator_display_name text
)
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  center extensions.geography;
  effective_radius integer;
  effective_size integer;
  effective_offset integer;
  title_pattern text;
begin
  if user_lat is null or user_lon is null
     or user_lat < -90 or user_lat > 90
     or user_lon < -180 or user_lon > 180 then
    raise exception 'Invalid coordinates' using errcode = '22023';
  end if;

  if category_filter is not null
     and category_filter not in ('story', 'puzzle', 'art', 'experience') then
    raise exception 'Invalid category' using errcode = '22023';
  end if;

  effective_radius := least(greatest(coalesce(radius_meters, 5000), 100), 25000);
  effective_size := least(greatest(coalesce(page_size, 50), 1), 100);
  effective_offset := least(greatest(coalesce(page_offset, 0), 0), 1000);

  -- Longitude first, latitude second.
  center := extensions.st_setsrid(
    extensions.st_makepoint(user_lon, user_lat),
    4326
  )::extensions.geography;

  if nullif(btrim(search_text), '') is not null then
    title_pattern := '%' || replace(replace(replace(
      left(btrim(search_text), 50),
      '\', '\\'), '%', '\%'), '_', '\_') || '%';
  end if;

  return query
    select
      w.id,
      w.title,
      w.category,
      extensions.st_y(w.location::extensions.geometry),
      extensions.st_x(w.location::extensions.geometry),
      extensions.st_distance(w.location, center),
      p.username,
      p.display_name
    from public.worlds as w
    join public.profiles as p on p.id = w.creator_id
    where w.status = 'published'
      and w.visibility = 'public'
      and (category_filter is null or w.category = category_filter)
      and (title_pattern is null or w.title ilike title_pattern)
      and extensions.st_dwithin(w.location, center, effective_radius)
    order by 6, 1
    limit effective_size
    offset effective_offset;
end;
$$;

revoke all on function public.get_nearby_worlds(
  double precision, double precision, integer, text, text, integer, integer
) from public, anon, authenticated;

grant execute on function public.get_nearby_worlds(
  double precision, double precision, integer, text, text, integer, integer
) to anon, authenticated;
