-- HOSP or Not
-- Repo-accurate migration draft for optional auth + anonymous-first actor model
-- Based on current documented schema in README.md:
--   posts(id, photo_url, description, exif_verified, exif_data, status, outcome, created_at, closed_at)
--   votes(id, post_id, vote, blurb, created_at)
--
-- Goal:
-- - keep anonymous posting and browsing intact
-- - replace localStorage-only vote identity with actor-backed identity
-- - make optional Supabase Auth possible later without breaking the current vibe
-- - preserve existing posts and votes
--
-- Read this before running:
-- - This migration assumes the current public schema matches the README.
-- - Review in Supabase before applying to production.
-- - If your live `votes` table already differs, adapt before running.

create extension if not exists pgcrypto;

begin;

-- -------------------------------------------------------------------
-- 1. profiles
-- optional signed-in user metadata
-- -------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  avatar_url text,
  role text not null default 'user' check (role in ('user', 'moderator', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

DROP TRIGGER IF EXISTS profiles_set_updated_at ON public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- -------------------------------------------------------------------
-- 2. actors
-- unified identity for guest users and signed-in users
-- -------------------------------------------------------------------
create table if not exists public.actors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  guest_id text,
  merged_into_actor_id uuid references public.actors(id),
  created_at timestamptz not null default now(),
  constraint actors_has_identity check (user_id is not null or guest_id is not null)
);

create unique index if not exists actors_user_id_unique
  on public.actors (user_id)
  where user_id is not null;

create unique index if not exists actors_guest_id_unique
  on public.actors (guest_id)
  where guest_id is not null;

-- -------------------------------------------------------------------
-- 3. guest_sessions
-- optional anti-abuse and continuity support for anonymous users
-- -------------------------------------------------------------------
create table if not exists public.guest_sessions (
  guest_id text primary key,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  user_agent_hash text,
  ip_hash text,
  risk_flags jsonb not null default '[]'::jsonb
);

-- -------------------------------------------------------------------
-- 4. extend votes instead of replacing it
-- preserve existing vote rows and migrate safely
-- -------------------------------------------------------------------
alter table public.votes
  add column if not exists actor_id uuid references public.actors(id) on delete cascade;

-- legacy anonymous votes existed before actor identity.
-- create one actor per legacy vote row so history remains intact and unique.
insert into public.actors (id, guest_id, created_at)
select
  gen_random_uuid(),
  'legacy-vote-' || v.id::text,
  coalesce(v.created_at, now())
from public.votes v
where v.actor_id is null;

update public.votes v
set actor_id = a.id
from public.actors a
where v.actor_id is null
  and a.guest_id = 'legacy-vote-' || v.id::text;

alter table public.votes
  alter column actor_id set not null;

create unique index if not exists votes_post_actor_unique
  on public.votes (post_id, actor_id);

create index if not exists votes_post_id_idx
  on public.votes (post_id);

create index if not exists votes_actor_id_idx
  on public.votes (actor_id);

-- -------------------------------------------------------------------
-- 5. helper functions for guest/user actor resolution
-- -------------------------------------------------------------------
create or replace function public.get_or_create_guest_actor(p_guest_id text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
begin
  if p_guest_id is null or length(trim(p_guest_id)) = 0 then
    raise exception 'guest_id required';
  end if;

  select id into v_actor_id
  from public.actors
  where guest_id = p_guest_id
    and merged_into_actor_id is null;

  if v_actor_id is not null then
    insert into public.guest_sessions (guest_id, last_seen_at)
    values (p_guest_id, now())
    on conflict (guest_id)
    do update set last_seen_at = now();

    return v_actor_id;
  end if;

  insert into public.actors (guest_id)
  values (p_guest_id)
  returning id into v_actor_id;

  insert into public.guest_sessions (guest_id, last_seen_at)
  values (p_guest_id, now())
  on conflict (guest_id)
  do update set last_seen_at = now();

  return v_actor_id;
end;
$$;

create or replace function public.get_or_create_user_actor(p_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
begin
  if p_user_id is null then
    raise exception 'user_id required';
  end if;

  select id into v_actor_id
  from public.actors
  where user_id = p_user_id;

  if v_actor_id is not null then
    return v_actor_id;
  end if;

  insert into public.actors (user_id)
  values (p_user_id)
  returning id into v_actor_id;

  return v_actor_id;
end;
$$;

create or replace function public.merge_guest_actor_into_user_actor(
  p_guest_id text,
  p_user_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_guest_actor_id uuid;
  v_user_actor_id uuid;
begin
  v_user_actor_id := public.get_or_create_user_actor(p_user_id);

  select id into v_guest_actor_id
  from public.actors
  where guest_id = p_guest_id
    and merged_into_actor_id is null;

  if v_guest_actor_id is null or v_guest_actor_id = v_user_actor_id then
    return v_user_actor_id;
  end if;

  -- preserve earliest vote rule by only moving guest votes that don't already conflict
  update public.votes gv
  set actor_id = v_user_actor_id
  where gv.actor_id = v_guest_actor_id
    and not exists (
      select 1
      from public.votes uv
      where uv.actor_id = v_user_actor_id
        and uv.post_id = gv.post_id
    );

  update public.actors
  set merged_into_actor_id = v_user_actor_id
  where id = v_guest_actor_id;

  return v_user_actor_id;
end;
$$;

-- -------------------------------------------------------------------
-- 6. controlled vote write RPC
-- keeps anonymous voting, but enforces one actor vote per post server-side
-- -------------------------------------------------------------------
create or replace function public.submit_vote(
  p_post_id uuid,
  p_vote boolean,
  p_blurb text default null,
  p_guest_id text default null
)
returns public.votes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_actor_id uuid;
  v_vote public.votes;
begin
  v_user_id := auth.uid();

  if p_post_id is null then
    raise exception 'post_id required';
  end if;

  if p_vote is null then
    raise exception 'vote required';
  end if;

  if v_user_id is not null then
    v_actor_id := public.get_or_create_user_actor(v_user_id);

    if p_guest_id is not null and length(trim(p_guest_id)) > 0 then
      v_actor_id := public.merge_guest_actor_into_user_actor(p_guest_id, v_user_id);
    end if;
  else
    v_actor_id := public.get_or_create_guest_actor(p_guest_id);
  end if;

  insert into public.votes (post_id, actor_id, vote, blurb)
  values (p_post_id, v_actor_id, p_vote, left(p_blurb, 280))
  on conflict (post_id, actor_id)
  do nothing
  returning * into v_vote;

  if v_vote.id is null then
    raise exception 'duplicate vote for this post';
  end if;

  return v_vote;
end;
$$;

create or replace function public.update_vote_blurb(
  p_post_id uuid,
  p_blurb text,
  p_guest_id text default null
)
returns public.votes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_actor_id uuid;
  v_vote public.votes;
begin
  v_user_id := auth.uid();

  if p_post_id is null then
    raise exception 'post_id required';
  end if;

  if v_user_id is not null then
    v_actor_id := public.get_or_create_user_actor(v_user_id);

    if p_guest_id is not null and length(trim(p_guest_id)) > 0 then
      v_actor_id := public.merge_guest_actor_into_user_actor(p_guest_id, v_user_id);
    end if;
  else
    v_actor_id := public.get_or_create_guest_actor(p_guest_id);
  end if;

  update public.votes
  set blurb = left(nullif(trim(p_blurb), ''), 280)
  where post_id = p_post_id
    and actor_id = v_actor_id
  returning * into v_vote;

  if v_vote.id is null then
    raise exception 'vote not found for this actor/post';
  end if;

  return v_vote;
end;
$$;

-- -------------------------------------------------------------------
-- 7. lightweight aggregate view for feed/landing/stats usage
-- -------------------------------------------------------------------
create or replace view public.post_vote_totals as
select
  p.id as post_id,
  count(v.id) as total_votes,
  count(v.id) filter (where v.vote = true) as hosp_votes,
  count(v.id) filter (where v.vote = false) as not_votes,
  case
    when count(v.id) = 0 then 50
    else round((count(v.id) filter (where v.vote = true)::numeric / count(v.id)::numeric) * 100)
  end as hosp_pct
from public.posts p
left join public.votes v on v.post_id = p.id
group by p.id;

-- -------------------------------------------------------------------
-- 8. RLS starter posture
-- browsing remains public, direct vote inserts get shut off
-- -------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.actors enable row level security;
alter table public.guest_sessions enable row level security;
alter table public.votes enable row level security;

-- profiles: users can manage their own record
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
create policy "profiles_update_own"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- votes: public read stays open for feed, post pages, stats, realtime consumption
DROP POLICY IF EXISTS "votes_public_read" ON public.votes;
create policy "votes_public_read"
  on public.votes
  for select
  to anon, authenticated
  using (true);

-- HOLD on blocking direct client inserts until frontend RPC cutover is confirmed.
-- Leave current insert behavior in place for now.
-- After confirming production is writing through submit_vote(), replace the live insert policy with a deny policy.
-- Suggested post-cutover patch:
-- DROP POLICY IF EXISTS "votes_no_direct_insert" ON public.votes;
-- CREATE POLICY "votes_no_direct_insert"
--   ON public.votes
--   FOR INSERT
--   TO anon, authenticated
--   WITH CHECK (false);

-- optional: if existing loose insert policies exist in production, remove them manually after cutover

grant execute on function public.submit_vote(uuid, boolean, text, text) to anon, authenticated;
grant execute on function public.update_vote_blurb(uuid, text, text) to anon, authenticated;
grant execute on function public.get_or_create_guest_actor(text) to anon, authenticated;
grant execute on function public.get_or_create_user_actor(uuid) to authenticated;
grant execute on function public.merge_guest_actor_into_user_actor(text, uuid) to authenticated;
grant select on public.post_vote_totals to anon, authenticated;

commit;
