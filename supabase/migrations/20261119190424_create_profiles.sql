-- Public profile for every auth user, created automatically at sign-up.
-- Contract: docs/DATABASE.md (profiles). Username rules: docs/DECISIONS.md.

-- Internal helpers live in a schema the Data API does not expose.
create schema if not exists private;
revoke all on schema private from public;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null
    constraint profiles_username_key unique
    constraint profiles_username_format check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text
    constraint profiles_display_name_format check (
      display_name is null
      or (
        display_name = btrim(display_name)
        and char_length(display_name) between 1 and 50
      )
    ),
  bio text
    constraint profiles_bio_length check (bio is null or char_length(bio) <= 280),
  avatar_path text
    constraint profiles_avatar_path_length check (
      avatar_path is null or char_length(avatar_path) <= 512
    ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is
  'Public profile for each user. Every column is public; private data stays in auth.users.';

alter table public.profiles enable row level security;

-- Replace Supabase's default broad grants with exactly what clients need.
-- avatar_path stays server-managed until storage ownership rules exist.
revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to anon, authenticated;
grant update (username, display_name, bio) on table public.profiles to authenticated;

create policy "Profiles are publicly readable"
  on public.profiles
  for select
  to anon, authenticated
  using (true);

create policy "Users update their own profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.set_updated_at() from public;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function private.set_updated_at();

-- Creates the profile for a new auth user. Must never fail for a bad or
-- taken username, because a failure here blocks sign-up:
--   1. use the requested username (lower-cased) if it is valid and free;
--   2. otherwise use 'user_' plus the first 10 hex digits of the user id;
--   3. if even that is taken, try random 10-hex-digit suffixes.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested text := lower(btrim(coalesce(new.raw_user_meta_data ->> 'username', '')));
  candidate text;
begin
  if requested ~ '^[a-z0-9_]{3,20}$' then
    begin
      insert into public.profiles (id, username) values (new.id, requested);
      return new;
    exception
      when unique_violation then
        null; -- taken: fall through to a generated name
    end;
  end if;

  for attempt in 1..10 loop
    if attempt = 1 then
      candidate := 'user_' || substr(replace(new.id::text, '-', ''), 1, 10);
    else
      candidate := 'user_' || substr(md5(random()::text || clock_timestamp()::text), 1, 10);
    end if;

    begin
      insert into public.profiles (id, username) values (new.id, candidate);
      return new;
    exception
      when unique_violation then
        null; -- taken: try another
    end;
  end loop;

  raise exception 'Could not generate a unique username for user %', new.id;
end;
$$;

revoke all on function private.handle_new_user() from public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function private.handle_new_user();
