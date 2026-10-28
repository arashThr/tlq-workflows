# TLQ Workflows

Personal searchable reference page for The Last Question podcast production.

## Principles

- **Brevity first.** Prefer one recommended command or short note over multiple options or long explanations.
- Keep cards focused: title, short description, one primary command (if any), and concise notes.
- Pipeline steps should stay high-level and link to the detailed cards.
- Dark, minimal UI. No extra libraries or frameworks — pure HTML/CSS/JS.
- When adding a new workflow, decide if it belongs as a searchable card, a pipeline step, or both.

## Structure

- `index.html` — the entire page (search, pipeline, and command cards).
- Commands live in the `commands` array in the script.
- Pipeline is static HTML above the results.

## Editing

- Update existing cards in place rather than adding near-duplicates.
- Keep escapeHtml correct (`&`, `<`, `>`).
- Test search and copy buttons after changes.
- Prefer updating the living page over adding separate docs unless the content is long.

## Defaults

- Audio extract: high-quality MP3 VBR (`-q:a 2`).
- Shotcut normalize: same Target on both tracks, -14 LUFS for YouTube dialogue.
- Audio hosting: Cloudflare R2 with custom domain.
