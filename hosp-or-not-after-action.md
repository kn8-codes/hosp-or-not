# HOSP or Not — After Action Report
> Session date: April 2026
> Status: MVP build in progress — stats page remaining

---

## What This Document Is

A handoff document capturing everything built, every decision made, and the exact state of the project at the end of this session. Feed this into Claude Code or a new Claude conversation to resume without re-explaining anything.

---

## Project Summary

HOSP or Not is an anonymous community voting site. Users upload a photo and description of an injury or ailment. The crowd votes yes or no on whether they should go to the hospital. Voters can add a short blurb with self-reported credentials. The submitter sees a live animated gauge showing the running verdict in real time. No logins, no accounts — fully anonymous, 4chan-style participation.

**Stack:** SvelteKit + Supabase + GSAP + exifr  
**Target timeline:** Weekend project  
**First Claude Code project** — learning tool as much as product

---

## What Was Built This Session

### Phase 1 — Project Scaffold
- SvelteKit skeleton project created at `~/Projects/hosp-or-not`
- Dependencies installed: `@supabase/supabase-js`, `exifr`, `gsap`
- `CLAUDE.md` created in project root
- `hosp-or-not.md` spec doc in project root
- `.env` file created with Supabase URL and anon key

### Phase 2 — Supabase Setup
- Supabase project created and configured
- SQL tables created via dashboard SQL editor
- Storage bucket `photos` created (public)
- `.env` populated with real keys

### Phase 2 — Data Layer (all complete)

**`src/lib/supabase.js`**
Supabase client initialized from environment variables.

**`src/lib/posts.js`**
- `getPosts()` — feed query, nested vote counts, sorted verified-first then newest
- `getPost(id)` — single post with full vote details including blurbs
- `createPost()` — uploads photo to Supabase Storage, inserts post row with EXIF data
- `closePost()` — flips status to closed, saves outcome text, stamps closed_at

**`src/lib/votes.js`**
- `castVote(postId, vote, blurb)` — inserts vote, saves to localStorage after success
- `hasVoted(postId)` — checks localStorage for duplicate prevention
- `tallyVotes(votes)` — returns `{ yes, no, total }` for gauge calculation
- localStorage key: `hosp_votes` (object mapping postId → vote)
- Owner tracking key: `hosp_owned` (array of post IDs the user submitted)

### Phase 3 — UI (mostly complete)

**`src/routes/+layout.svelte`**
- Global shell with header, wordmark, nav (Feed / + Post / Stats)
- CSS custom properties defined in `:root` — full list below
- Dark theme (`--color-bg: #0f0f0f`)
- 680px max-width, mobile-first

**CSS Variables defined (for light mode toggle later):**
```css
--color-hosp          #ff3c3c    /* Brand red, HOSP labels */
--color-not           #3b82f6    /* Brand blue, NOT labels */
--color-verified      #22c55e    /* EXIF badge */
--color-bg            #0f0f0f    /* Page background */
--color-surface       #1a1a1a    /* Photo placeholder */
--color-surface-raised #222      /* Gauge bar track */
--color-border        #1e1e1e    /* Dividers */
--color-border-strong #222       /* Stronger dividers */
--color-text          #f0f0f0    /* Primary text */
--color-text-secondary           /* Body text */
--color-text-muted               /* Secondary labels */
--color-text-faint    #555       /* Timestamps, meta */
```

**`src/lib/components/PostCard.svelte`**
- Feed card component — photo thumbnail, description excerpt (2-line clamp), CSS gauge bar, vote tally, time ago, EXIF badge, closed badge
- Entire card is a link to `/post/{id}`
- CSS gauge bar (not GSAP) — correct for feed cards, static snapshot only
- `loading="lazy"` on images

**`src/routes/+page.svelte`** (feed)
- Loads posts via `getPosts()`
- Maps over posts, renders `PostCard` for each
- GSAP stagger entrance animation on cards

**`src/routes/submit/+page.svelte`**
- Drag-and-drop or tap-to-upload photo
- EXIF extraction via `exifr` on file select (not on submit)
- EXIF status indicator shown to user after photo selection
- 911 disclaimer always visible at top, above upload zone
- Description text field
- On submit: uploads photo → inserts post → saves post ID to `hosp_owned` localStorage → redirects to post page

**`src/lib/components/Gauge.svelte`** ⭐
The signature UI component. SVG semicircle gauge with animated needle.
- Props: `yesPct`, `total`
- Two arc fills: NOT (blue) from left, HOSP (red) from right, meet at split point
- Both arcs use `stroke-dashoffset` tweened by GSAP
- Needle rotates -90° (all NOT) → 0° (tie) → +90° (all HOSP) via `gsap.to()` with `svgOrigin` pivot lock
- Needle easing: `elastic.out(1, 0.6)` — satisfying bounce on settle
- Arc easing: `power2.out` — smooth fill
- Animated counter: `displayPct` ticks up/down via pctProxy object GSAP tweens
- Svelte 5 `$effect` watches `yesPct` — reruns animation on every vote update
- Realtime-ready: new Supabase votes update `yesPct` → `$effect` fires → gauge animates

**`src/routes/post/[id]/+page.svelte`**
- Loads single post via `getPost(id)`
- Supabase Realtime subscription on `votes` table filtered by `post_id`
- Duplicate vote guard: checks `v.id` before adding to local votes array (prevents double-counting optimistic updates)
- `<Gauge {yesPct} total={tally.total} />` replaces old CSS bar
- Vote buttons: HOSP (red filled) / NOT (blue outlined)
- Post-vote blurb form: textarea, 280 char limit, char counter, skip option
- Blurb updates last vote row in Supabase via `.update()`
- "What people said" section: blurbs listed with HOSP/NOT verdict badge
- Owner controls: "Close this case" button (checks `hosp_owned` localStorage)
- Close form: outcome textarea, confirm/cancel, calls `closePost()`
- Closed post shows outcome block
- `onDestroy`: channel unsubscribed to prevent memory leak

### Phase 3 — Remaining
- **`src/routes/stats/+page.svelte`** — IN PROGRESS at end of session

---

## Decisions Made

| Decision | Choice | Reason |
|---|---|---|
| Auth | None — fully anonymous | 4chan-style, no friction |
| Vote dedup | localStorage only | No auth, client-side is enough for v1 |
| Gauge on feed cards | CSS bar | Static snapshot, no animation needed |
| Gauge on post page | GSAP SVG | Hero moment, needs to feel alive |
| EXIF verification | Best-effort, not a gate | Not all phones send GPS, reward realness without blocking |
| EXIF boost | Verified posts float to top of feed | Trust signal affects ranking, not access |
| Content moderation | None in v1 | Ship first, calibrate on real data |
| Theme | Dark (`#0f0f0f`) | Fits the gross-out energy better than light |
| Light mode | Post-launch feature | CSS variables already in place, easy to add |
| Image storage | Supabase Storage bucket `photos` | Public bucket, UUID filenames |

---

## Known Gaps / Post-Launch Features

- Light mode toggle (CSS variables already set up — just needs `[data-theme="light"]` override block)
- AI content moderation (flag non-medical, detect Google Images reposts)
- Smarter EXIF verification (cross-reference GPS + timestamp plausibility)
- Aggregate stats by injury type / body part
- Feed pagination (currently loads all open posts)
- Report/flag system for abuse
- Mobile camera capture direct from phone
- "Pedantic expert" flair for repeat voters

---

## How to Resume

### Pick up where we left off
1. `cd ~/Projects/hosp-or-not`
2. `claude`
3. First message: *"Read CLAUDE.md and hosp-or-not.md. We also have this after action report — [paste this doc]. The stats page at src/routes/stats/+page.svelte was the last thing being built. Resume from there."*

### Stats page spec (next task)
- Route: `src/routes/stats/+page.svelte`
- Show three numbers: total posts, total votes, crowd accuracy rate
- Accuracy = % of closed posts where majority vote matched actual outcome
- Same dark theme, CSS variables, no charts in v1 — clean typography only

### After stats — first run
```bash
npm run dev
```
Open `http://localhost:5173` and look at it. Check:
- Feed loads (will be empty — that's fine)
- Submit page works end to end
- Post page gauge animates
- Realtime subscription fires on new votes

### Deploy
```bash
npm run build
```
Deploy to Vercel — connect GitHub repo, Vercel auto-detects SvelteKit.
Add environment variables in Vercel dashboard (same as `.env` file).

---

## File Structure at End of Session

```
hosp-or-not/
├── CLAUDE.md
├── hosp-or-not.md
├── after-action.md          ← this file
├── .env                     ← Supabase keys (not in git)
├── .gitignore
├── package.json
└── src/
    ├── routes/
    │   ├── +layout.svelte   ← global shell, CSS variables
    │   ├── +page.svelte     ← feed
    │   ├── submit/
    │   │   └── +page.svelte ← upload form + EXIF
    │   ├── post/
    │   │   └── [id]/
    │   │       └── +page.svelte ← gauge + voting + realtime
    │   └── stats/
    │       └── +page.svelte ← IN PROGRESS
    └── lib/
        ├── supabase.js
        ├── posts.js
        ├── votes.js
        └── components/
            ├── PostCard.svelte
            └── Gauge.svelte  ← GSAP SVG gauge ⭐
```

---

## Context for Future Sessions

- This is Nate's first real Claude Code project — chosen deliberately as a lower-stakes build before tackling BoomMates
- BoomMates is on hold until Unify Akron Civic Assembly housing research is further along
- The Gauge.svelte component came directly from GSAP + SVG concepts explored in a playground artifact earlier in the same session
- Nate has been learning GSAP for years without a real project to apply it to — this is the first time it's been used in production code
- Stack preference: SvelteKit over React (compile-away philosophy), Supabase for backend simplicity
- Development machine: M4 MacBook Air (clean AI/coding machine)
- Keep scope ruthless — this is a weekend project, not a startup
