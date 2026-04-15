-- HOSP or Not — RPC smoke tests
-- These are manual SQL checks to run after the safe migration.
-- Replace placeholder values before running.

-- ------------------------------------------------------------
-- 1. legacy backfill should be complete
-- ------------------------------------------------------------
select count(*) as votes_missing_actor_id
from public.votes
where actor_id is null;

-- ------------------------------------------------------------
-- 2. basic table sanity
-- ------------------------------------------------------------
select count(*) as actor_count from public.actors;
select count(*) as guest_session_count from public.guest_sessions;
select count(*) as profile_count from public.profiles;

-- ------------------------------------------------------------
-- 3. aggregate view sanity
-- ------------------------------------------------------------
select * from public.post_vote_totals limit 10;

-- ------------------------------------------------------------
-- 4. guest actor lookup smoke test
-- ------------------------------------------------------------
select public.get_or_create_guest_actor('smoke-test-guest-1') as guest_actor_id;

-- ------------------------------------------------------------
-- 5. vote submission smoke test
-- replace with a real post UUID
-- ------------------------------------------------------------
select public.submit_vote(
  '00000000-0000-0000-0000-000000000000'::uuid,
  true,
  'smoke test blurb',
  'smoke-test-guest-1'
);

-- ------------------------------------------------------------
-- 6. duplicate prevention smoke test
-- this should error on second run for same guest/post pair
-- ------------------------------------------------------------
select public.submit_vote(
  '00000000-0000-0000-0000-000000000000'::uuid,
  true,
  'duplicate attempt',
  'smoke-test-guest-1'
);

-- ------------------------------------------------------------
-- 7. blurb update smoke test
-- should update the existing guest vote
-- ------------------------------------------------------------
select public.update_vote_blurb(
  '00000000-0000-0000-0000-000000000000'::uuid,
  'updated smoke test blurb',
  'smoke-test-guest-1'
);
