# TLQ Design System

Single source of truth for visual direction, poster templates, and brand decisions for **The Last Question** (TLQ).

Last updated: 2026-10-28

## Visual Direction

- **Black and white only** — pure high-contrast monochrome. No color, no gradients, no glow.
- **Minimal and classy** — vast negative space, precise geometry, refined typography.
- **Inspired by Asimov’s “The Last Question”** — themes of entropy, heat death, computation across cosmic time, a single persistent question.
- **Restrained tech / cyberpunk feeling** — subtle circuit-like grids, data dissolution, binary fragments. Not flashy, not neon, not cyberpunk cliché.
- **Future-oriented and computational** without decoration.
- Posters must be easy to update in Mac Preview: clear empty zone for episode number + title.

## Concepts Considered

### 1. The Persistent Question (Circuit Question Mark)
Large white question mark formed by thin circuit traces and binary fragments on pure black. Thin horizontal rule near bottom for text zone.

**Status:** Considered, not chosen.

### 2. Entropy Field ✅ Chosen Direction
Sparse geometric grid of thin white lines and dots. Dense at the top, slowly dissolves / breaks apart / fades toward the bottom. One tiny, perfectly sharp white question mark remains intact near the vertical center. Vast negative space. Clean lower third reserved for text.

**Status:** Selected as the primary poster style.

### 3. Pure Signal
Typography-led. Elegant white “THE LAST QUESTION” in the upper third. Thin horizontal broken data line or sparse binary fragment below that fades out. Clean empty lower band for episode text.

**Status:** Strong secondary option. Liked after Entropy Field.

## Final Chosen Design (Entropy Field)

Reference poster includes:
- Title: **The Last Question** (top, white, bold serif-like)
- Dissolving grid of lines + dots
- Small white `?` floating in the dissolving field
- Bottom: **EP 00** (large) + **tlq.dev** underneath

The lower area is intentionally clean so episode number and title can be swapped in Preview (or any image editor) without touching the rest of the composition.

### Prompt used for Entropy Field (Grok Imagine)

```
Minimal black and white poster, pure solid black background, sparse geometric grid of thin precise white lines and dots that is denser at the top and slowly dissolves, breaks apart, and fades toward the bottom, one tiny perfectly sharp white question mark remaining intact near the vertical center, high contrast, vast negative space, completely clean empty lower third reserved for text, restrained cyberpunk aesthetic, entropy and heat-death theme, classy and elegant, inspired by Asimov’s The Last Question, no neon, no glow, no gradients, no people, no text, no logos, vertical poster composition
```

### Secondary Prompt (Pure Signal)

```
Minimal black and white poster, pure solid black background, elegant white typography reading "THE LAST QUESTION" in a refined geometric sans-serif or modern serif font positioned in the upper third, thin horizontal broken data line or sparse binary fragment directly below the title that fades out toward the edges, high contrast, vast negative space, completely clean empty lower band reserved for episode number and title, classy and restrained tech aesthetic, inspired by Asimov’s The Last Question, no neon, no glow, no gradients, no people, no extra text, no logos, vertical poster composition
```

## How to Update for a New Episode

1. Start from the master Entropy Field base (or the current reference poster).
2. In Mac Preview (or any editor):
   - Change the episode number (currently “EP 00”).
   - Add or replace the episode title in the reserved lower zone.
3. Keep the grid, question mark, and overall composition untouched.
4. Export high-resolution PNG/JPG for Telegram (TLQ Dev) and the website (tlq.dev).

## Brand Notes

- Show name: **The Last Question**
- Short: **TLQ**
- Website: **tlq.dev**
- Telegram: **TLQ Dev**
- Co-hosted with Amin
- Topics: recent tech & AI events and their impact on developers, human life, and the economy
- Recording: Zencaster
- Editing: OneShot + Borumi
- Output: Video + Podcast per episode

## Files

- This document: `design/README.md`
- Reference poster image should live next to this file (e.g. `design/poster-entropy-field-reference.jpg`) once committed.

When new visual decisions are made, update this file so it remains the single source of truth.
