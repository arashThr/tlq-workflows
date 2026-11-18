# tlq-workflows
Private command and workflow reference for The Last Question podcast production.

## Design
Visual direction, poster system (Entropy Field), prompts, and brand decisions live in **[design/README.md](design/README.md)**.

## Publish an episode

```bash
./publish-episode.sh "/path/to/TLQ-EP03.mp4" topics.txt
```

Times in `topics.txt` are positions in that video. Add `--before-intro` when the notes were taken before the intro.

Open `index.html` for that command and the topics file.
