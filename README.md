# HOSP or Not

> Post your injury. Let the internet decide if you're being dramatic.

Anonymous community voting on whether your injury or ailment needs a hospital visit. Upload a photo, describe what happened, and let strangers on the internet weigh in. No accounts. No BS. Probably not medical advice.

---

## What It Does

- **Submit a case** — upload a photo of your injury with a description
- **EXIF verification** — photos with valid GPS + timestamp get a trust boost and float to the top of the feed
- **Vote** — cast a YES (go to hospital) or NO (stay home) on any open case
- **Add context** — voters can include a blurb: "I'm an ER nurse…", "I've had this exact injury…"
- **Live gauge** — an animated SVG needle updates in real time as votes come in via Supabase Realtime
- **Close your case** — submitters can return and report the outcome, closing the loop for the crowd
- **Stats** — crowd accuracy tracked over time based on outcome reports

---

## Stack

| Layer | Tech |
|---|---|
| Frontend | SvelteKit |
| Database | Supabase (Postgres) |
| Storage | Supabase Storage |
| Realtime | Supabase Realtime |
| Animation | GSAP |
| EXIF extraction | exifr |
| Hosting | Vercel |

---

## Getting Started

### Prerequisites
- Node.js 18+
- A Supabase project

### Install

```bash
git clone https://github.com/kn8-codes/hosp-or-not.git
cd hosp-or-not
npm install
```

### Environment Variables

Create a `.env` file in the project root:

```
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Supabase Setup

Run the following SQL in your Supabase SQL editor:

```sql
-- Posts table
CREATE TABLE posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_url text NOT NULL,
  description text NOT NULL,
  exif_verified boolean DEFAULT false,
  exif_data jsonb,
  status text DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  outcome text,
  created_at timestamptz DEFAULT now(),
  closed_at timestamptz
);

-- Votes table
CREATE TABLE votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
  vote boolean NOT NULL,
  blurb text,
  created_at timestamptz DEFAULT now()
);
```

Create a public storage bucket named `photos`.

Add RLS policies for anonymous access to both tables and the storage bucket.

### Run Locally

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173)

---

## Project Structure

```
src/
├── routes/
│   ├── +layout.svelte        # Global shell, CSS variables, fonts
│   ├── +page.svelte          # Feed — scrollable list of open cases
│   ├── submit/
│   │   └── +page.svelte      # Photo upload + EXIF extraction
│   ├── post/
│   │   └── [id]/
│   │       └── +page.svelte  # Case detail — gauge, voting, blurbs
│   └── stats/
│       └── +page.svelte      # Crowd accuracy stats
└── lib/
    ├── supabase.js            # Supabase client
    ├── posts.js               # Post operations
    ├── votes.js               # Vote operations + localStorage dedup
    ├── stats.js               # Stats queries + accuracy heuristic
    └── components/
        ├── PostCard.svelte    # Feed card component
        └── Gauge.svelte       # GSAP SVG animated gauge ⭐
```

---

## How Voting Works

- Anyone can vote on any open case — no account required
- One vote per case per browser session (localStorage dedup)
- After voting, users can optionally add a short blurb (280 chars)
- Self-reported credentials ("I'm a nurse") carry social weight but are unverified
- Vote tallies update live via Supabase Realtime subscriptions

## How EXIF Verification Works

- EXIF data is extracted client-side on photo select using `exifr`
- Posts with valid `DateTimeOriginal` + GPS coordinates get an `exif_verified` flag
- Verified posts are ranked higher in the feed
- Verification is best-effort — posts without EXIF are still allowed

## How Accuracy Is Calculated

When a submitter closes their case and reports an outcome, the app uses keyword heuristics to infer whether the crowd called it correctly:

- HOSP keywords: `er`, `hospital`, `broken`, `fracture`, `stitches`, `surgery`
- NOT keywords: `fine`, `home`, `better`, `healed`, `okay`, `recovered`

Accuracy = correct predictions / scoreable closed cases

---

## Roadmap

- [ ] Light mode toggle (CSS variables already in place)
- [ ] AI content moderation layer
- [ ] Smarter EXIF fake detection
- [ ] Feed pagination
- [ ] Report / flag system
- [ ] Aggregate stats by injury type
- [ ] Mobile camera capture direct from phone

---

## Disclaimer

HOSP or Not is not medical advice. If you are experiencing a life-threatening emergency, call 911 immediately. Do not wait for internet strangers to weigh in.

---

## License

MIT
