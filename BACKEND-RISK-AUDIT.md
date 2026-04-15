# HOSP or Not — Backend Risk Audit

This is the blunt list of what could still bite during the auth/actor backend transition.

## Overall read

The migration direction is good.
The main remaining risks are not conceptual. They are operational:
- mismatched production schema
- RLS conflicts
- unexpected Realtime assumptions
- old client paths still writing directly to `votes`

---

## Risk 1 — production schema drift

### Why it matters
The migration is written against the repo/README schema.
If production drifted, SQL may fail or behave differently.

### What to verify
- `votes` still has `id`, `post_id`, `vote`, `blurb`, `created_at`
- `posts` still has expected columns
- no hidden triggers on `votes`
- no different foreign key names or constraints that matter

### Mitigation
Before running migration, inspect live schema in Supabase.

---

## Risk 2 — existing RLS policies may conflict

### Why it matters
If there are old insert/select policies on `votes`, behavior may differ from what the docs assume.

### What to verify
- existing policies on `votes`
- existing policies on `posts`
- storage bucket policy for `photos`

### Mitigation
Capture current policies before migration.
Do not guess.

---

## Risk 3 — legacy vote backfill semantics

### Why it matters
The migration creates one actor per existing legacy vote.
That is the safest historical move, but it means old duplicate votes remain as-is.

### This is acceptable because
- old data had no trustworthy identity
- dedup can only be enforced correctly going forward

### Watch-out
If someone expects cleanup of historical duplicates, this migration does not do that.
It preserves reality instead of inventing fake certainty.

---

## Risk 4 — Realtime payload shape assumptions

### Why it matters
The frontend appends vote rows from Realtime inserts.
If new rows include different shape/fields than expected, weird UI duplication or mismatch can happen.

### What to watch
- optimistic append vs incoming Realtime insert
- whether newly returned RPC vote row and Realtime payload differ in useful fields
- whether duplicate render protection by `id` still behaves cleanly

### Mitigation
Test two-browser realtime after migration.
This is not optional.

---

## Risk 5 — direct insert paths still exist in the wild

### Why it matters
Even if local repo is moved to RPC, production may still run older code until deploy is complete.
That is why insert blocking is deferred.

### Mitigation
Current posture is correct:
- safe migration first
- verify RPC path
- block direct inserts only after confirmation

---

## Risk 6 — helper RPCs are security definer

### Why it matters
`security definer` is right here, but it deserves care.
If these functions become too permissive later, they can punch through RLS in ugly ways.

### Current read
Current function scope is narrow enough.
They do one job each.
That is good.

### Mitigation
Do not stuff extra business logic into them casually.
Keep them boring.

---

## Risk 7 — guest session hashing is not implemented yet

### Why it matters
`guest_sessions` has `user_agent_hash` and `ip_hash`, but current app code does not populate them.
So anti-abuse is still mostly future-facing.

### Current truth
This migration improves identity integrity more than abuse resistance.
That is still worth doing.

### Mitigation
Treat `guest_sessions` as scaffolding for now, not full protection.

---

## Risk 8 — optional auth merge behavior remains mostly future-facing

### Why it matters
The merge functions exist, but auth UI is not wired yet.
So production benefit right away is mainly:
- actor-backed guest votes
- future-ready schema

### Mitigation
No action needed now.
Just don’t oversell current auth readiness.

---

## Risk 9 — blurb update semantics

### Why it matters
`update_vote_blurb()` updates the vote row for the resolved actor/post pair.
That is correct, but it assumes one vote per actor/post after migration.

### Current read
That is consistent with the design.
Good.

### Mitigation
Smoke test blurbs after migration.
Especially on old posts with lots of legacy data.

---

## Risk 10 — localStorage is still in the UX path

### Why it matters
The app still uses localStorage as a client-side hint for “already voted.”
That is okay, but it is not truth.
The truth is now server-side actor dedup.

### Mitigation
This is acceptable.
Just remember localStorage is convenience, not trust.

---

## Recommendation

Backend path is good enough to proceed when you are ready, with this order:
1. inspect live schema + policies
2. run safe migration
3. run RPC smoke tests
4. verify real app vote flow
5. then run direct-insert block patch later

That is the least stupid path.
