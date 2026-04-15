# HOSP or Not — Migration Notes for Optional Auth + Actor Model

This migration is written against the **current repo schema**, not the earlier abstract draft.

## Current schema it assumes

### `posts`
- `id`
- `photo_url`
- `description`
- `exif_verified`
- `exif_data`
- `status`
- `outcome`
- `created_at`
- `closed_at`

### `votes`
- `id`
- `post_id`
- `vote` boolean
- `blurb`
- `created_at`

## What the migration changes

### Adds
- `profiles`
- `actors`
- `guest_sessions`
- helper functions for actor resolution/merge
- `submit_vote()` RPC
- `post_vote_totals` aggregate view

### Changes
- adds `votes.actor_id`
- backfills every legacy vote with a synthetic actor
- creates unique constraint on `(post_id, actor_id)`

## Why backfill with one actor per legacy vote

Because the current app has no trustworthy identity in the database.
It only has browser localStorage dedup.

That means existing vote rows cannot be safely grouped into real users after the fact.
So the least-bad migration is:
- preserve all old votes
- assign each old vote its own legacy actor
- enforce real actor-based dedup only going forward

That keeps history intact without pretending we know more than we do.

## What this migration does not do yet

- it does **not** update the frontend
- it does **not** add auth UI
- it does **not** move `/` to `/vote`
- it does **not** change post submission yet
- it does **not** remove anonymous posting

## Required app changes after SQL

Before this works in the app, code needs to change:

1. client must create/persist `guest_id`
2. `src/lib/votes.js` must stop inserting directly into `votes`
3. vote writes must call `supabase.rpc('submit_vote', ...)`
4. localStorage should become a UX hint, not the source of truth
5. optional auth can be layered later

## Risk notes

- if production already has custom RLS policies, compare before applying
- if production `votes` already has different columns, adjust first
- per Nate review, direct insert blocking is intentionally deferred until frontend RPC cutover is confirmed

## Recommended next step

Now cut metal in this order:
1. update vote write path to RPC + guest ID
2. verify feed/post detail still render vote data cleanly
3. then add landing page split (`/` marketing, `/vote` feed)
4. then optional auth UI
