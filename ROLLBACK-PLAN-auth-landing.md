# HOSP or Not — Rollback Plan for Auth Prep + Landing Page Cut

If this rollout goes sideways, do not improvise. Use this.

## Failure modes to watch for

- voting breaks completely
- duplicate-vote enforcement fails weirdly
- blurbs no longer save
- feed tallies stop updating
- Realtime payload assumptions break UI
- landing page route split causes navigation confusion

---

## Fastest app-only rollback

Use this if the database was not migrated yet.

### Action
- revert commit `4375a78`

### Result
- `/` becomes feed again
- direct insert vote flow returns
- landing page disappears
- app behavior returns to old anonymous model

Command:
```bash
git revert 4375a78
```

If you want hard reset locally instead:
```bash
git reset --hard 17598b1
```

Do not hard reset shared history unless you mean it.

---

## If migration was applied and app breaks

### Short version
If the SQL is live but the frontend is broken, the safest immediate move is usually:
1. patch frontend fast, or
2. temporarily relax insert policy for `votes`

### Temporary DB-side emergency patch
If new RPC path fails and you need voting back now, you can temporarily allow direct inserts again.

Example emergency patch:
```sql
DROP POLICY IF EXISTS "votes_no_direct_insert" ON public.votes;

CREATE POLICY "votes_temp_direct_insert"
  ON public.votes
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);
```

This is not the final state. This is the fire extinguisher.

### Follow-up after emergency patch
- restore old client insert behavior, or
- fix RPC/frontend mismatch quickly
- then remove temp policy again

---

## Full DB rollback warning

The migration backfills `actor_id` and adds support tables/functions.
Rolling that back cleanly is more annoying than app rollback.

If you must reverse SQL, do it deliberately.
Do not freestyle-drop objects in production half awake.

Objects introduced:
- `profiles`
- `actors`
- `guest_sessions`
- `votes.actor_id`
- helper functions
- RPC functions
- `post_vote_totals` view
- RLS policy changes

## Safer rollback philosophy

Prefer:
- keep schema additions in place
- restore old frontend behavior temporarily
- re-open direct inserts if absolutely necessary

That is usually less destructive than trying to un-migrate the database under pressure.

---

## Decision tree

### Case A — migration not applied yet
Rollback by git only.

### Case B — migration applied, frontend broken
Use emergency insert policy if needed, then patch frontend.

### Case C — migration applied, data weird but app mostly works
Freeze changes, inspect rows/functions, do not thrash.

---

## Minimum rollback prep before production rollout

Before applying migration, make sure you have:
- commit hash of pre-rollout app state
- copy/export of current schema
- visibility into current Supabase policies
- confidence on who is on the hook if prod gets weird
