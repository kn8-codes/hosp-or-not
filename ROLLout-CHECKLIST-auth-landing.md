# HOSP or Not — Rollout Checklist for Auth Prep + Landing Page Cut

This is the practical checklist for shipping the current local work safely.

## Scope of this rollout

Includes:
- landing page at `/`
- feed moved to `/vote`
- guest actor vote-flow prep in frontend
- SQL migration for actor-backed voting

Does not yet include:
- optional auth UI
- Google login
- moderation surfaces

---

## Phase 0 — before touching Supabase

- [ ] review `supabase-migration-auth-actor-plan.sql`
- [ ] confirm production schema still matches README-era schema closely enough
- [ ] check current RLS policies in Supabase
- [ ] confirm current app env vars are correct
- [ ] confirm local build passes
- [ ] snapshot/export current database schema if possible

## Phase 1 — local verification

- [ ] `npm install`
- [ ] `npm run build`
- [ ] run local dev server with real env vars
- [ ] verify `/`
- [ ] verify `/vote`
- [ ] verify `/post/[id]`
- [ ] verify `/submit`
- [ ] verify `/stats`

## Phase 2 — Supabase migration review

Before applying, inspect SQL sections:
- [ ] `profiles`
- [ ] `actors`
- [ ] `guest_sessions`
- [ ] `votes.actor_id` backfill
- [ ] helper functions
- [ ] `submit_vote()`
- [ ] `update_vote_blurb()`
- [ ] RLS changes
- [ ] `post_vote_totals` view

Questions to answer before run:
- [ ] do any current policies conflict with `votes_no_direct_insert`?
- [ ] does production already use different vote constraints?
- [ ] do any external scripts write directly to `votes`?

## Phase 3 — apply migration

- [ ] run SQL in Supabase SQL editor or migration flow
- [ ] verify tables/functions created successfully
- [ ] verify legacy vote rows received `actor_id`
- [ ] verify `submit_vote()` callable by anon
- [ ] verify `update_vote_blurb()` callable by anon

## Phase 4 — app smoke test after migration

### Landing page
- [ ] `/` loads
- [ ] CTA to `/vote` works
- [ ] mobile layout looks sane

### Feed
- [ ] `/vote` loads cases
- [ ] post cards still show tallies

### Voting
- [ ] guest can cast vote
- [ ] second vote on same post is blocked
- [ ] vote appears in UI immediately
- [ ] Realtime still updates other tabs/clients

### Blurbs
- [ ] voter can add blurb after vote
- [ ] blurb saves to the correct vote row
- [ ] blurb renders in post detail

### Posting
- [ ] anonymous post submit still works
- [ ] storage upload still works
- [ ] EXIF path still works

### Stats
- [ ] stats page still loads
- [ ] closed-case accuracy still calculates

## Phase 5 — production confidence pass

- [ ] test on mobile
- [ ] test on desktop
- [ ] test fresh browser session
- [ ] test incognito guest voting
- [ ] test an old post with legacy votes

## Phase 6 — aftercare

- [ ] monitor Supabase logs for RPC errors
- [ ] monitor client console for vote failures
- [ ] note any oddities around Realtime payload shape
- [ ] decide when to add optional auth UI
