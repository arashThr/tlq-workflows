# TLQ Design System

Single source of truth for visual direction, poster/cover templates, and brand decisions for **The Last Question** (TLQ).

Last updated: 2026-10-28

## Visual Direction

- **Black and white only** — pure high-contrast monochrome. Flat, no color, no gradients, no glow, no shadows, no texture.
- **Minimal and classy** — precise geometry, generous negative space, strong typography.
- **Monospaced typography** for a technical, terminal-like, computational feel.
- **Inspired by Asimov’s “The Last Question”** without literal illustration.
- Must work strongly as a **square 1:1 podcast cover** (and remain readable at small sizes).

## Concepts Considered (historical)

### 1. The Persistent Question (Circuit Question Mark)
Large white question mark formed by fine circuit traces and sparse binary fragments. Title at top, episode number, website at bottom.

**Status:** Used briefly, then superseded.

### 2. Entropy Field
Dissolving geometric grid of lines and dots with a tiny central question mark.

**Status:** Rejected for poor small-cover readability.

### 3. Pure Signal
Typography-led with a thin data line.

**Status:** Considered, not chosen.

## Final Chosen Design (Square Monospaced Cover)

**Format:** Square podcast cover, 1:1 aspect ratio.

**Specification:**
- Pure black background
- Thin white square frame inset about 7% from each edge
- Centered in the upper half: the letters **TLQ** in a huge bold monospaced typeface, white, tight but not touching
- Below that: the words **THE LAST QUESTION** in smaller white monospaced capitals with wide letter-spacing
- Near the bottom: **ARASH · AMIN** in even smaller white monospaced capitals, also letter-spaced
- No photographs, no gradients, no shadows, no rounded corners, no texture
- Flat black and white only

This is the locked master cover style.

### Prompt / Description used

```
Square podcast cover, 1:1, pure black background. A thin white square frame inset about 7% from each edge. Centered in the upper half, the letters TLQ in a huge bold monospaced typeface, white, tight but not touching. Below that, the words THE LAST QUESTION in smaller white monospaced capitals with wide letter-spacing. Near the bottom, ARASH · AMIN in even smaller white monospaced capitals, also letter-spaced. No photographs, no gradients, no shadows, no rounded corners, no texture. Flat black and white only.
```

## How to Update for a New Episode

The master cover is mostly static. For episode-specific versions:
1. Start from the master square cover.
2. Optionally overlay or replace text zones if an episode title or number needs to appear (while preserving the frame, TLQ, and hosts line).
3. Keep the monospaced treatment and pure black/white constraint.
4. Export high-resolution square PNG/JPG for podcast platforms, Telegram (TLQ Dev), and the website (tlq.dev).

## Brand Notes

- Show name: **The Last Question**
- Short: **TLQ**
- Website: **tlq.dev**
- Telegram: **TLQ Dev**
- Co-hosted with Amin (shown as ARASH · AMIN on cover)
- Topics: recent tech & AI events and their impact on developers, human life, and the economy
- Recording: Zencaster
- Editing: OneShot + Borumi
- Output: Video + Podcast per episode

## Files

- This document: `design/README.md`
- Reference cover image should live alongside this file (e.g. `design/cover-square-monospaced-reference.jpg` or `.png`).

When new visual decisions are made, update this file so it remains the single source of truth.
