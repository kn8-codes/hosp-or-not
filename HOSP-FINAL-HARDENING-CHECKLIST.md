# HOSP Final Hardening Checklist

## Purpose

This checklist exists for one moment:
when we are ready to run `supabase-post-cutover-direct-insert-block.sql`.

That patch should only happen after frontend RPC behavior is confirmed in the real app.

---

# Preconditions

## Database
- [x] safe migration applied
- [x] legacy votes backfilled with `actor_id`
- [x] `submit_vote()` verified
- [x] duplicate vote rejection verified
- [x] `update_vote_blurb()` available

## Code
- [x] vote path in `src/lib/votes.js` uses `submit_vote()` RPC
- [x] blurb path in `src/lib/votes.js` uses `update_vote_blurb()` RPC
- [x] no obvious remaining direct `votes` writes in `src/`

## Still required before hardening
- [ ] app tested against live migrated Supabase project
- [ ] guest vote through UI confirmed
- [ ] blurb update through UI confirmed
- [ ] refresh behavior confirmed
- [ ] Realtime behavior confirmed

---

# App test checklist

## Vote
- [ ] open `/vote`
- [ ] open a post
- [ ] cast vote as guest
- [ ] vote succeeds without DB/policy error

## Duplicate behavior
- [ ] second vote attempt blocked appropriately

## Blurb
- [ ] add blurb after vote
- [ ] blurb persists after refresh

## Realtime
- [ ] second session/browser reflects new vote
- [ ] no duplicate UI rows appear

## Read-only views
- [ ] feed still renders
- [ ] post detail still renders
- [ ] stats page still renders

---

# Hardening step

When all boxes above are true, run:

- `supabase-post-cutover-direct-insert-block.sql`

This patch will deny direct client inserts to `votes`.

---

# Immediate post-hardening checks

After applying the patch:

## Repeat these checks immediately
- [ ] guest vote through UI still works
- [ ] blurb update still works
- [ ] Realtime still works
- [ ] no silent vote failures

## If something breaks
Use the rollback/emergency note in:
- `ROLLBACK-PLAN-auth-landing.md`

---

# Decision rule

If there is any doubt about live UI behavior, **do not run the hardening patch yet**.

There is no trophy for bricking votes 10 minutes early.
