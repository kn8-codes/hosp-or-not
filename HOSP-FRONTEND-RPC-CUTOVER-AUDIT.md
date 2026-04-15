# HOSP Frontend RPC Cutover Audit

## Goal

Verify whether the frontend is truly ready for the final vote-write hardening step.

That hardening step is:
- `supabase-post-cutover-direct-insert-block.sql`

This audit answers one question:

**If we block direct inserts to `votes`, will the app still work?**

---

# Audit result

## Short answer
**Almost, but not yet safe to harden blind.**

The main vote and blurb paths have been moved to RPC.
That is good.

But final hardening should still wait until app-level testing confirms:
- guest vote through UI works
- blurb update through UI works
- post detail still renders vote rows cleanly
- no stale/old frontend deployment is still writing direct inserts

So the status is:
- backend ready
- code mostly ready
- production hardening should still wait for one real UI verification pass

---

# What was audited

Searched for:
- direct `votes` inserts/updates
- `submit_vote`
- `update_vote_blurb`
- vote-related code paths
- any remaining direct write use

---

# Findings

## 1. Main vote creation path
File:
- `src/lib/votes.js`

### Result
Good.

Current behavior:
- generates/uses persistent `guest_id`
- calls `supabase.rpc('submit_vote', ...)`
- stores local vote hint in localStorage

### Read
This is the correct new path.
The server is now the real source of truth for vote uniqueness.

---

## 2. Blurb update path
File:
- `src/lib/votes.js`

### Result
Good.

Current behavior:
- calls `supabase.rpc('update_vote_blurb', ...)`

### Read
Also correct.
This means post-vote blurbs are no longer relying on a raw client table update.

---

## 3. Post detail page behavior
File:
- `src/routes/post/[id]/+page.svelte`

### Result
Mostly good, but this is where the real UI verification still matters.

Current behavior:
- uses `castVote()`
- uses `updateVoteBlurb()`
- appends returned vote row to local UI state
- subscribes to Realtime inserts on `votes`
- duplicate protection in UI still uses localStorage hint via `hasVoted()`

### Risk
Potential mismatch between:
- optimistic/local UI update
- returned RPC row shape
- Realtime insert event shape

This may be fine.
But it should be visually tested before final hardening.

---

## 4. Stats page
File:
- `src/lib/stats.js`

### Result
Safe with respect to insert hardening.

Current behavior:
- reads from `posts`
- reads from `votes`
- no direct vote writes

### Note
Not part of cutover risk.

---

## 5. Other direct `votes` writes
### Result
No lingering direct `insert` or `update` calls to `votes` were found in `src/` besides the migrated paths.

This is the big good news.

---

# Cutover readiness judgment

## Ready now
- backend migration is applied
- helper RPCs work
- duplicate enforcement works server-side
- code paths for vote + blurb are pointed at RPCs
- no obvious lingering direct vote writes remain in source

## Not proven yet
- live deployed frontend is definitely using the new code
- no cached/old client path is still active in the environment you care about
- UI state + Realtime behavior is clean after real user interaction

---

# Required pre-hardening checks

Before applying `supabase-post-cutover-direct-insert-block.sql`, confirm all of these through the app UI:

## Guest voting
- [ ] open a post in browser
- [ ] cast vote as guest
- [ ] vote succeeds
- [ ] page updates correctly

## Duplicate protection
- [ ] same guest cannot vote same post twice
- [ ] failure mode is sane

## Blurbs
- [ ] add blurb after voting
- [ ] blurb saves correctly
- [ ] blurb renders correctly on refresh

## Realtime
- [ ] second browser/session sees vote update
- [ ] no weird duplicate rendering

## Feed/post integrity
- [ ] `/vote` still loads
- [ ] post detail still shows counts and blurbs cleanly
- [ ] stats page still loads

---

# Hardening rule

## Safe rule
Only run:
- `supabase-post-cutover-direct-insert-block.sql`

when the app has been tested against the migrated database through the real UI.

That is the right threshold.

---

# Recommendation

## My call
The codebase looks close enough that final hardening is likely to work.
But not enough to justify doing it blind.

So the correct next move is:
1. run the app against the migrated Supabase project
2. test guest vote + blurb + refresh + Realtime
3. then apply the insert-block patch

That is the least stupid finish.
