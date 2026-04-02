---
name: hosp-frontend-design
description: >
  Frontend design skill for HOSP or Not. Use this skill whenever building,
  styling, or polishing any UI component, page, or layout for this project.
  Triggers on: "style this", "polish pass", "make it look better", "landing page",
  "design", "vibe", "ugly", "needs work", or any request involving visual output.
  This skill overrides generic design instincts with HOSP or Not's specific
  aesthetic direction.
---

# HOSP or Not — Frontend Design Skill

## The Vibe

HOSP or Not is not a health app. It is not a startup. It is not trying to be trusted.

It is a chaotic, funny, slightly gross community site in the tradition of early internet culture — Something Awful, early Reddit, Fark, rate-my-x sites. The kind of thing that gets passed around in group chats. The name is intentionally dumb. The content is gross on purpose. The energy is irreverent.

Design should reflect this. It should feel like a human made it with strong opinions, not like a design system committee approved it.

**One-line aesthetic brief:** Raw editorial meets late-night internet — dark, typographically bold, a little unhinged.

---

## Aesthetic Direction

### Tone
- Brutalist-adjacent but not unreadable
- Dark theme always (light mode is a future toggle, not the default)
- Confident, not polished — this site knows what it is
- A little medical, a little wrong — like a WebMD that got loose

### Typography
- Display/wordmark: something with personality — condensed, heavy, or slightly wrong. Consider: **Bebas Neue**, **DM Serif Display**, **Archivo Black**, **Oswald**, **Anton**. NOT Inter, NOT Helvetica, NOT system fonts.
- Body: something legible but with character — **IBM Plex Mono**, **DM Mono**, **Syne**, **Inconsolata** for a clinical/terminal feel that fits the medical-but-chaotic vibe
- Size contrast should be dramatic — big things should be BIG, small things should be small
- Uppercase labels with letter-spacing for UI chrome (badges, meta, buttons)

### Color
Always use the existing CSS variables — do not hardcode hex values:
```
--color-hosp          red       HOSP decisions, danger, urgency
--color-not           blue      NOT decisions, safety, calm
--color-verified      green     EXIF trust badge
--color-bg            #0f0f0f   near-black background
--color-surface       #1a1a1a   card backgrounds
--color-surface-raised #222     inputs, gauge tracks
--color-border        #1e1e1e   subtle dividers
--color-text          #f0f0f0   primary text
--color-text-faint    #555      timestamps, meta
```

Accent usage: red and blue are load-bearing — they ARE the voting system. Don't dilute them with decorative use elsewhere. Let them mean something.

### Motion (GSAP is already installed)
- The Gauge component is the hero animation — protect it, don't compete with it
- Entrance animations: stagger card reveals on feed load (already implemented — preserve)
- Micro-interactions: hover states should feel snappy, not floaty — `power2.out`, short durations (0.15–0.2s)
- Page transitions: simple opacity fade is enough — don't over-choreograph
- Never animate things that don't need it — motion should be purposeful

### Layout
- Max-width 680px centered — already established, keep it
- Mobile-first always — most users will be on phones
- Cards should feel dense but not cramped — 16px padding minimum
- Generous whitespace around hero elements (gauge, vote buttons)
- The vote buttons on the post page are a KEY moment — they should be large, confident, unmissable

---

## Component Design Rules

### The Gauge
- This is the signature element — it should be the most polished thing on the page
- Do not resize or reposition it without good reason
- The elastic needle bounce is intentional — preserve it
- "No votes yet" state should still look good — consider a centered neutral needle at 50%

### Vote Buttons
- HOSP button: solid red, heavy font, large — this is the dramatic choice
- NOT button: outlined blue — the cautious choice gets the outlined treatment
- Both should be finger-friendly (min 48px height on mobile)
- After voting: replace buttons with a clear "vote recorded" state — don't leave them grayed out and confusing

### Post Cards (feed)
- Photo thumbnail should be square, object-fit cover — no distortion
- Keep the CSS bar gauge on cards — it's correct here, GSAP is overkill for a feed item
- EXIF verified badge: green, small, bottom-left of photo — already good
- Closed badge: muted, top-right — already good
- Hover state: subtle opacity shift is fine, don't overdo it

### The Wordmark
- "HOSP or Not" — the "HOSP" should visually dominate
- Red on dark background
- Heaviest available font weight
- This is the brand moment — make it memorable

### Landing / About Section
When adding a landing or about section to the home page:
- Keep it SHORT — two sentences max
- Punchy, slightly irreverent tone — not marketing copy
- Examples of the right tone:
  - "Post your injury. Let the internet decide if you're being dramatic."
  - "Anonymous. Unfiltered. Probably not medical advice."
- Place it above the feed, below the header
- Should not take up more than ~100px of vertical space — it's context, not a hero section

### Stats Page
- Numbers should be BIG and bold — the stat is the content
- Labels should be small, uppercase, letter-spaced
- Accuracy bar should use `--color-hosp` and `--color-not`
- Tongue-in-cheek caption is correct — keep the personality

### Error States
- Keep them in character — not "An error occurred", something like "Something went wrong. Maybe go to the hospital."
- Use `--color-hosp` red for errors — it's already the danger color

---

## What to Avoid

- **Purple anything** — no gradients, no accents, nothing
- **Rounded everything** — some sharp edges are appropriate here
- **Friendly illustrations** — this is not Headspace
- **Sans-serif body text at small sizes** — use a mono or serif with character
- **Generic loading spinners** — if you need a loader, make it fit the vibe
- **Excessive card shadows** — dark theme + box-shadow looks muddy, use borders instead
- **Centered body text** — only center UI labels and numbers, not paragraphs
- **Hover tooltips on everything** — trust the user

---

## SvelteKit-Specific Notes

- Scoped styles in `.svelte` files are correct — use them
- `:global()` only for base resets and body styles in `+layout.svelte`
- All colors via CSS variables — never hardcode hex in component styles
- GSAP imports: `import { gsap } from 'gsap'` — already in package.json
- Fonts: load via `@import` in `+layout.svelte` global styles or via `<svelte:head>`
- `loading="lazy"` on all feed images — already implemented, keep it

---

## The Test

Before shipping any UI work, ask:

1. Does it look like something a human with opinions made?
2. Does the red/blue voting language feel clear and intentional?
3. Is the gauge still the hero?
4. Would someone screenshot this and send it to a friend?
5. Does it feel like HOSP or Not, or does it feel like a generic web app?

If the answer to any of those is no — keep going.
