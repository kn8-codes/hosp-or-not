# HOSP or Not — Project Spec
> Version 1.0 — Claude Code context document
> Last updated: March 2026

---

## What It Is

A dead-simple anonymous community voting site. Users upload a photo and description of an injury or ailment. The crowd votes yes or no on whether they should go to the hospital. Voters can add a short blurb explaining their reasoning — including self-reported credentials ("I'm a nurse, here's why"). The submitter sees a live gauge showing the running verdict in real time.

The draw is gross-out content. The guardrail is medical context. The name is intentionally funny.

---

## The One-Sentence Pitch

"4chan meets WebMD — post your wound, let the internet decide."

---

## Core Philosophy

- **No friction.** No logins, no accounts, no sign-up walls. Show up, post, vote, leave.
- **Anonymous by design.** Neither submitters nor voters have identities on the platform. Anonymity is a feature, not a limitation.
- **Polished, not a wireframe.** Simple enough to ship in a weekend, but it should look like someone gave a damn.
- **Real content only.** EXIF verification is a trust signal, not a hard gate — but we reward realness.

---

## Stack

- **Frontend:** SvelteKit
- **Backend/DB:** Supabase (Postgres + Storage for images)
- **Hosting:** TBD (Vercel or Netlify for SvelteKit frontend)
- **Image storage:** Supabase Storage bucket

---

## Features — V1

### Submitting a Post
- Upload a photo (required for v1)
- Add a text description of the ailment (required)
- EXIF data is extracted on upload:
  - Timestamp checked
  - GPS coordinates checked (if present)
  - Device info checked
  - Posts with valid EXIF get a "verified" trust flag
  - Posts without EXIF are still allowed — just not boosted
- 911 disclaimer shown on submission screen: *"If this is a life-threatening emergency, call 911 immediately."*
- No account required — post is anonymous

### The Feed
- Scrollable list of open cases
- Sort order: newest verified posts first, then newest unverified
- Each card shows:
  - Photo (thumbnail)
  - Short description excerpt
  - Current vote gauge (yes/no meter)
  - Vote count
  - Time posted
  - EXIF verified badge (if applicable)

### Voting
- Any visitor can vote YES (go to hospital) or NO (stay home) on any open post
- One vote per post per session (basic — cookie or localStorage, no auth needed)
- After voting, voter can optionally add a short blurb (free text, ~280 chars)
- Blurb can include self-reported context: "I'm an ER nurse", "I've had this exact injury", etc.
- No credential verification — social weight only

### The Verdict Gauge
- Live yes/no meter displayed on each post
- Visual: gauge or meter with a needle — moves as votes come in
- Shows vote count and percentage split
- Updates in real time (Supabase realtime subscriptions)
- This is a key UI moment — make it feel satisfying and alive (GSAP animation opportunity)

### Post Closure
- Submitter can return to their post and mark it closed
- On closure, they can optionally add an outcome update:
  - "Went to the ER — it was broken"
  - "Stayed home — fine the next day"
  - Free text field
- Closed posts are archived, visible but no longer accepting votes
- Outcome data feeds aggregate stats (see below)

### Stats Page (lightweight v1)
- Overall crowd accuracy rate (when outcomes are reported)
- Total posts, total votes
- Simple — just enough to make the data feel interesting
- Foundation for richer analytics later

---

## Features — Post V1 (do not build yet)

- AI content moderation layer (flag non-medical, detect Google Images reposts)
- EXIF-based fake detection (cross-reference GPS + timestamp plausibility)
- Aggregate accuracy stats by injury type / body part
- "Pedantic expert" flair system for repeat voters
- Mobile-optimized upload flow (camera capture direct from phone)
- Report/flag system for obvious abuse

---

## Data Model (Supabase / Postgres)

### `posts`
| field | type | notes |
|---|---|---|
| id | uuid | primary key |
| photo_url | text | Supabase Storage URL |
| description | text | submitter's description |
| exif_verified | boolean | true if valid EXIF found |
| exif_data | jsonb | raw extracted EXIF (timestamp, gps, device) |
| status | enum | 'open', 'closed' |
| outcome | text | nullable — submitter's closure note |
| created_at | timestamp | |
| closed_at | timestamp | nullable |

### `votes`
| field | type | notes |
|---|---|---|
| id | uuid | primary key |
| post_id | uuid | foreign key → posts |
| vote | boolean | true = HOSP, false = NOT |
| blurb | text | nullable — voter's explanation |
| created_at | timestamp | |

---

## UI / Design Direction

- Dark or light — TBD, but it should feel a little irreverent. Not clinical, not a health app.
- The gauge/meter is the hero UI element — it needs to feel alive and satisfying
- GSAP for the gauge animation — this is a key moment in the experience
- SVG for the gauge itself — tweenable attributes, smooth needle movement
- Card-based feed — clean, scrollable, each card self-contained
- Mobile-first — most submissions will come from phones

---

## What This Is NOT

- Not a medical advice platform (disclaimer covers this)
- Not a moderated community (v1 — ship first, moderate later)
- Not an identity platform (anonymous is the point)
- Not a complex app — this is a weekend project, keep scope ruthless

---

## The Vibe

Think early internet energy. A little gross, a little funny, genuinely useful in a chaotic way. The kind of site that gets passed around in group chats. The name is part of it — HOSP or Not is dumb in the best way.

---

## Claude Code Notes

- Start with Supabase schema and storage bucket setup
- Build the feed and post card components first — get data flowing
- Gauge animation is the signature UI moment — don't ship without it
- EXIF extraction happens client-side on upload (use `exifr` npm package)
- Supabase Realtime for live vote updates on the gauge
- Keep components small and focused — Svelte's philosophy fits this project perfectly
- Reference `grill-me.skill` interrogation notes for any scope questions that come up mid-build
