# HOSP or Not — Test Plan for Landing + Actor Vote Flow

## Goal

Verify the local app and future migrated app behave correctly without losing the anonymous-first feel.

---

## Test matrix

### 1. Landing page

#### Desktop
- [ ] `/` loads without errors
- [ ] hero copy is readable immediately
- [ ] `Start Voting` routes to `/vote`
- [ ] `How It Works` anchor works

#### Mobile
- [ ] hero stack feels sane
- [ ] CTA remains obvious
- [ ] no broken overflow or crushed gauge

### 2. Feed

- [ ] `/vote` loads open cases
- [ ] cards render images, tally bars, timestamps
- [ ] clicking card opens `/post/[id]`

### 3. Post detail

- [ ] gauge renders
- [ ] tally count matches visible blurbs/votes expectations
- [ ] verified badge still shows where appropriate
- [ ] closed case state still renders cleanly

### 4. Guest voting after migration

#### Fresh browser session
- [ ] vote succeeds
- [ ] second vote on same post fails
- [ ] vote persists after refresh
- [ ] blurb can be added after vote

#### Second browser / incognito
- [ ] separate guest can vote same post
- [ ] Realtime updates first browser

### 5. Realtime

- [ ] open same post in two sessions
- [ ] cast vote in one session
- [ ] other session updates without refresh
- [ ] no duplicate rendered vote item appears

### 6. Posting

- [ ] image upload succeeds
- [ ] EXIF detection still works
- [ ] post appears in feed
- [ ] owner can still close case

### 7. Stats

- [ ] stats page loads
- [ ] totals still look believable
- [ ] no broken queries from schema changes

---

## Manual test cases worth doing

### Case 1 — normal anonymous user
- land on `/`
- click `Start Voting`
- open case
- vote
- add blurb

Expected: clean, fast, no account friction

### Case 2 — anonymous poster
- go to `/submit`
- create case
- verify redirect to post page
- later close case

Expected: old behavior still works

### Case 3 — duplicate prevention
- vote once
- try same case again

Expected: blocked by local UX and server truth

### Case 4 — legacy post with old votes
- open an existing post created before migration
- verify tally still displays
- add a new vote after migration

Expected: old data and new data coexist without drama

---

## Known things to watch closely

- Realtime payload shape vs local optimistic vote append
- blurb update hits correct vote row
- localStorage vote hint not masking server errors
- stats logic still behaving with added `actor_id`

---

## Definition of good enough to ship

- landing page works on mobile and desktop
- guest voting works after migration
- duplicate votes blocked reliably enough
- blurbs save correctly
- existing posts and vote tallies still render
- no obvious broken routes
