# HOSP or Not test results

Date: 2026-04-15
Target Supabase project: `ornymnghjzmwiqykzsjt`
Repo tested: `~/projects/hosp-or-not`

## What I found first

The repo at `~/projects/hosp-or-not` was not in the expected RPC-cutover state when I started.
It was still using direct inserts into `votes` instead of the migrated RPC flow.

I patched the repo to match the known good RPC-cutover implementation already validated in the workspace copy.

## Changes applied before testing

- switched vote submission from direct `votes` insert to `submit_vote` RPC
- added `update_vote_blurb` RPC usage
- added guest id local storage handling for anonymous actor flow
- synced landing/vote/post route files to the cutover version
- synced supporting Supabase client safety checks
- copied migration/test docs and SQL references into repo root for review

## Build result

Command:

```bash
npm run build
```

Result:
- Passed
- Svelte emitted non-fatal warnings in `src/routes/post/[id]/+page.svelte` about local state capturing initial `data`
- No build-blocking errors

## Backend / RPC tests run against live Supabase

All tests below were run against:

- `https://ornymnghjzmwiqykzsjt.supabase.co`

### 1. Basic table presence / counts

Checks:
- `posts` reachable
- `votes` reachable

Results:
- `posts` count response succeeded, count = 1
- `votes` count response succeeded, count = 3 before new test vote was added in this session

### 2. Guest actor bootstrap

RPC tested:
- `get_or_create_guest_actor('shift-test-guest-1')`

Result:
- Passed
- Returned actor id: `231b56e7-24cf-4793-b502-60a84bd0a57c`

### 3. Vote submission via RPC

RPC tested:
- `submit_vote`

Payload used:
- post id: `3ce37848-18db-4be9-8b9d-6417d81dd6ea`
- vote: `true`
- blurb: `shift smoke test blurb`
- guest id: `shift-test-guest-1`

Result:
- Passed
- Returned created vote id: `ed819f1b-0857-43f9-a267-a47dbbf3739b`

### 4. Vote blurb update via RPC

RPC tested:
- `update_vote_blurb`

Payload used:
- same post id
- updated blurb: `shift smoke test blurb updated`
- same guest id

Result:
- Passed
- Returned updated vote row successfully

### 5. Duplicate protection

RPC tested:
- second `submit_vote` call using same guest id / post id

Result:
- Passed
- duplicate attempt failed with HTTP 400 as expected

## Pending SQL

I did not find any new pending SQL files in the original `~/projects/hosp-or-not` repo state.
I copied the known migration/reference SQL files from the validated workspace copy into the repo root for review.

Important:
- I did **not** run `supabase-post-cutover-direct-insert-block.sql`
- that remains intentionally deferred until real browser/UI confirmation is done end to end

## What was tested end to end

Confirmed live backend path:
- anonymous guest actor resolution
- vote submission through `submit_vote`
- blurb update through `update_vote_blurb`
- duplicate vote rejection

## What I did not fully verify yet

I did not complete browser-driven UI interaction testing in this session for:
- clicking through `/vote`
- submitting through the actual rendered frontend UI in a browser
- refresh behavior after voting
- realtime behavior in the browser

So backend cutover is confirmed live, but full browser UX verification is still a separate step.

## Summary

### Passed
- repo patched to RPC-cutover state
- build passes
- correct Supabase project configured
- guest actor RPC works
- submit vote RPC works
- update vote blurb RPC works
- duplicate protection works

### Still pending
- browser-level end-to-end UI validation
- post-cutover direct insert blocking SQL should remain deferred until browser validation is complete
