# TLQ Design System

Single source of truth for visual direction, poster templates, and brand decisions for **The Last Question** (TLQ).

Last updated: 2026-10-28

## Visual Direction

- **Black and white only** — pure high-contrast monochrome. No color, no gradients, no glow.
- **Minimal and classy** — vast negative space, precise geometry, refined typography.
- **Inspired by Asimov’s “The Last Question”** — themes of entropy, heat death, computation across cosmic time, a single persistent question.
- **Restrained tech / cyberpunk feeling** — subtle circuit-like grids, data dissolution, binary fragments. Not flashy, not neon, not cyberpunk cliché.
- **Future-oriented and computational** without decoration.
- Posters must be easy to update in Mac Preview: clear zones for episode number + title.
- Must remain readable and strong as small covers / thumbnails.

## Concepts Considered

### 1. The Persistent Question (Circuit Question Mark) ✅ Chosen Direction
Large white question mark formed by fine circuit traces and sparse binary fragments on pure black. Strong clear silhouette that stays readable at small sizes. Generous negative space. Title at the top, episode number under it, website at the very bottom.

**Status:** Selected as the primary poster style (better for small covers than the dissolving grid).

### 2. Entropy Field
Sparse geometric grid of thin white lines and dots. Dense at the top, slowly dissolves / breaks apart / fades toward the bottom. One tiny, perfectly sharp white question mark remains intact near the vertical center. Vast negative space. Clean lower third reserved for text.

**Status:** Considered and initially liked, but rejected because it does not hold up well at small cover sizes.

### 3. Pure Signal
Typography-led. Elegant white “THE LAST QUESTION” in the upper third. Thin horizontal broken data line or sparse binary fragment below that fades out. Clean empty lower band for episode text.

**Status:** Strong secondary option. Liked, but not chosen for covers.

## Final Chosen Design (The Persistent Question)

Reference poster layout:
- Title: **The Last Question** at the top (elegant white font)
- Episode number (e.g. **EP 00**) directly under the title
- Large central question mark made of fine circuit traces + sparse binary fragments
- Website **tlq.dev** at the very bottom of the cover

The composition is intentionally simple and high-contrast so the episode number can be updated easily while the circuit question mark and overall structure stay locked.

### Prompt used (Grok Imagine)

```
Minimal black and white poster, pure black background, large bold white question mark made of fine circuit traces and sparse binary fragments, very clean high-contrast silhouette readable at small thumbnail size, generous negative space, title "The Last Question" in elegant white font at the top, episode number "EP 00" in bold white below the title, website "tlq.dev" in white at the very bottom, thin horizontal rule near bottom if needed, classy restrained tech style, Asimov The Last Question inspired, no neon, no glow, no people, no extra text, vertical poster composition
```

(The tighter version of the original Persistent Question prompt was used.)

### Other prompts (for reference)

Entropy Field and Pure Signal prompts are kept in git history if needed later.

## How to Update for a New Episode

1. Start from the master Persistent Question base (or the current reference poster).
2. In Mac Preview (or any editor):
   - Change the episode number (currently “EP 00”).
   - Optionally adjust or add an episode title if desired in the upper text zone.
3. Keep the circuit question mark, title treatment, and bottom website untouched.
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
- Reference poster image: `design/poster-persistent-question-reference.jpg`

When new visual decisions are made, update this file so it remains the single source of truth.
