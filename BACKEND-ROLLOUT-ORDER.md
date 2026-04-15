# HOSP or Not — Backend Rollout Order

This is the backend-first sequence.
Frontend polish can wait.

## Goal

Get the database and write path ready in a way that does not brick current voting.

---

## Phase 1 — apply safe migration

Run:
- `supabase-migration-auth-actor-plan.sql`

This phase:
- adds `profiles`
- adds `actors`
- adds `guest_sessions`
- adds `votes.actor_id`
- backfills legacy votes
- adds `submit_vote()`
- adds `update_vote_blurb()`
- adds `post_vote_totals`
- does **not** block direct inserts yet

## Phase 2 — verify DB state

Check:
- `actors` exists
- `guest_sessions` exists
- `profiles` exists
- `votes.actor_id` exists and is populated for legacy rows
- `submit_vote()` runs successfully
- `update_vote_blurb()` runs successfully

Suggested checks:
```sql
select count(*) from public.votes where actor_id is null;
select count(*) from public.actors;
select * from public.post_vote_totals limit 5;
```

Expected:
- `votes.actor_id is null` count should be `0`

## Phase 3 — local/frontend RPC verification

Before touching insert policy:
- confirm local app uses `submit_vote()`
- confirm local app uses `update_vote_blurb()`
- confirm guest vote succeeds
- confirm duplicate vote is blocked

## Phase 4 — production verification

With migration live but direct inserts still allowed:
- verify production vote path works
- verify no RPC permission errors
- verify Realtime still behaves
- verify blurbs still save

This phase is the safety net.
If RPC path is weird, current insert posture is still not hard-blocked.

## Phase 5 — lock down direct inserts

Only after Phase 4 is clearly good.

Run:
- `supabase-post-cutover-direct-insert-block.sql`

That is the actual hardening step.

## Phase 6 — post-lock verification

Check again:
- guest vote still works
- blurb still updates
- direct client inserts are denied
- no regression in post detail or feed tallies

---

## Why this order is right

Because the dumbest possible move would be:
- add server-side RPC path
- block inserts immediately
- discover frontend still depends on direct insert in one weird corner
- break voting

This order avoids that.

---

## Backend artifacts now in repo

- `supabase-migration-auth-actor-plan.sql`
- `supabase-post-cutover-direct-insert-block.sql`
- `MIGRATION-NOTES-auth-actor-plan.md`
- `ROLLout-CHECKLIST-auth-landing.md`
- `ROLLBACK-PLAN-auth-landing.md`
- `TEST-PLAN-auth-landing.md`

## Recommendation

Next backend move when you are ready:
1. run the safe migration
2. verify actor backfill
3. verify RPC calls
4. only then run the insert-block patch
