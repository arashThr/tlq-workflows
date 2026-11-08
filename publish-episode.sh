#!/usr/bin/env bash
# Turn a finished episode video into the mp3, the cover, and a committed site post.
# Usage: ./publish-episode.sh [--episode N] [--date YYYY-MM-DD] VIDEO TOPICS.txt
#
# TOPICS.txt, one topic per line. A start time and source links are optional.
#   04:02.000–04:10.970 · You Can See Everything
#   PHP2Shell

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SITE="${TLQ_SITE:-/Users/ATAHER/Documents/workspace/personal/tlqdev}"
ASSETS="${TLQ_ASSETS:-/Users/ATAHER/Documents/workspace/personal/tlq/assets}"
TEMPLATE="${TLQ_COVER:-$ASSETS/EP02.png}"

usage() {
  echo "Usage: $0 [--episode N] [--date YYYY-MM-DD] VIDEO TOPICS.txt" >&2
  echo "TOPICS.txt can be - to read the topics from stdin." >&2
  exit 1
}

episode=""
publish_date=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --episode)
      episode="${2:-}"
      shift 2
      ;;
    --date)
      publish_date="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -eq 2 ]] || usage
video="$1"
topics="$2"

for cmd in ffmpeg ffprobe swiftc python3 git; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done

[[ -f "$video" ]] || { echo "Video not found: $video" >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "Cover template not found: $TEMPLATE" >&2; exit 1; }
[[ -d "$SITE/site/content" ]] || { echo "Site content folder not found: $SITE/site/content" >&2; exit 1; }
git -C "$SITE" rev-parse --is-inside-work-tree >/dev/null

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [[ "$topics" == "-" ]]; then
  cat > "$work/topics.txt"
  topics="$work/topics.txt"
fi
[[ -f "$topics" ]] || { echo "Topics file not found: $topics" >&2; exit 1; }

# Resolve the episode number and the output paths before the encode.
python3 - "$video" "$topics" "$episode" "$publish_date" "$SITE" "$work/job.json" << 'PY'
import json, re, sys
from datetime import date
from pathlib import Path

video, topics_path, episode_arg, date_arg, site, job_path = sys.argv[1:]
site = Path(site)
video = Path(video)

def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)

def episode_in(name):
    match = re.search(r"(?i)(?:^|[^a-z])ep\s*-?\s*(\d+)", name)
    return int(match.group(1)) if match else None

if episode_arg:
    if not re.fullmatch(r"\d{1,3}", episode_arg):
        fail("Episode must be a number from 0 to 999")
    episode = int(episode_arg)
else:
    episode = episode_in(video.name)
    if episode is None:
        episode = episode_in(video.parent.name)
    if episode is None:
        fail("No episode number in the video name. Pass --episode N")

if episode > 999:
    fail("Episode must be a number from 0 to 999")

if date_arg:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date_arg):
        fail("Date must be YYYY-MM-DD")
    publish_date = date_arg
else:
    publish_date = date.today().isoformat()

def parse_time(text):
    parts = text.split(":")
    if len(parts) == 2:
        hours, minutes, seconds = 0, parts[0], parts[1]
    elif len(parts) == 3:
        hours, minutes, seconds = parts
    else:
        fail(f"Bad time: {text}")
    return int(hours) * 3600 + int(minutes) * 60 + float(seconds)

def clock(seconds):
    minutes, secs = divmod(int(seconds), 60)
    return f"{minutes:02d}:{secs:02d}"

TIME = r"\d{1,2}:\d{2}(?::\d{2})?(?:\.\d+)?"
RANGE = re.compile(rf"^({TIME})\s*[-–—]\s*{TIME}\s*(?:·\s*)?(.*)$")
SINGLE = re.compile(rf"^({TIME})\s+(.+)$")

topics = []
for raw in Path(topics_path).read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    stamp = None
    shown = None
    ranged = RANGE.match(line)
    single = SINGLE.match(line)
    if ranged:
        stamp = int(round(parse_time(ranged.group(1))))
        shown = clock(stamp)
        line = ranged.group(2).strip()
    elif single:
        stamp = int(round(parse_time(single.group(1))))
        shown = clock(stamp)
        line = single.group(2).strip()
    if "|" in line:
        bits = [bit.strip() for bit in line.split("|")]
        title, urls = bits[0], [bit for bit in bits[1:] if bit]
    else:
        tokens = line.split()
        urls = []
        while tokens and re.match(r"https?://\S+$", tokens[-1]):
            urls.insert(0, tokens.pop())
        title = " ".join(tokens).strip()
    if not title:
        fail(f"Missing topic title: {raw}")
    for url in urls:
        if not re.match(r"https?://\S+$", url):
            fail(f"Not a link: {url}")
    topics.append({"time": stamp, "shown": shown, "title": title, "urls": urls})

if not topics:
    fail("The topics file is empty")

timed = [topic for topic in topics if topic["time"] is not None]
if timed and len(timed) != len(topics):
    fail("Either every topic has a start time, or none of them do")
previous = -1
for topic in timed:
    if topic["time"] < previous:
        fail(f"Topics are out of time order: {topic['title']}")
    previous = topic["time"]

slug = f"{episode:02d}"
content = site / "site/content"
for post in content.glob("*.md"):
    text = post.read_text()
    if re.search(rf'(?m)^episode:\s*"?{episode}"?\s*$', text) and not post.name.endswith(f"-{slug}.md"):
        fail(f"{post.name} is already episode {episode}")

matches = sorted(content.glob(f"*-{slug}.md"))
post_path = matches[-1] if matches else content / f"{publish_date}-{slug}.md"
chapters_path = site / "site/statics/chapters" / f"{slug}.json"

job = {
    "episode": episode,
    "slug": slug,
    "date": post_path.name[:10],
    "year": post_path.name[:4],
    "video": str(video),
    "topics": topics,
    "mp3": str(video.with_name(f"TLQ-EP{slug}.mp3")),
    "cover": str(video.with_name(f"EP{slug}.png")),
    "post": str(post_path),
    "chapters": str(chapters_path),
    "site": str(site),
    "audio_url": f"https://audio.tlq.dev/TLQ-EP{slug}.mp3",
    "tag_title": f"TLQ {slug}",
    "topics": topics,
}
Path(job_path).write_text(json.dumps(job))
PY

mp3="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["mp3"])' "$work/job.json")"
cover="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["cover"])' "$work/job.json")"
tag_title="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tag_title"])' "$work/job.json")"
year="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["year"])' "$work/job.json")"

bin="/tmp/tlq-cover-number"
if [[ ! -x "$bin" || "$ROOT/cover.swift" -nt "$bin" ]]; then
  swiftc -O -o "$bin" "$ROOT/cover.swift"
fi
"$bin" "$TEMPLATE" "$cover" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["episode"])' "$work/job.json")"

ffmpeg -y -loglevel error -i "$cover" -frames:v 1 -pix_fmt yuvj420p -q:v 2 "$work/cover.jpg"
# ID3v2.3 uses "/" to split artists. One name, also stored as album artist and in ID3v1.
ffmpeg -y -loglevel error -i "$video" -i "$work/cover.jpg" \
  -map 0:a:0 -map 1 \
  -c:a libmp3lame -q:a 2 -c:v copy \
  -id3v2_version 3 \
  -write_id3v1 1 \
  -metadata title="$tag_title" \
  -metadata artist="Arash & Amin" \
  -metadata album_artist="Arash & Amin" \
  -metadata album="The Last Question" \
  -metadata date="$year" \
  -metadata comment="https://tlq.dev" \
  -metadata publisher="TLQ.dev" \
  -metadata:s:v title="Cover" \
  -metadata:s:v comment="Cover (front)" \
  "$mp3"

python3 - "$work/job.json" "$mp3" << 'PY'
import json, re, subprocess, sys
from pathlib import Path

job = json.loads(Path(sys.argv[1]).read_text())
mp3 = Path(sys.argv[2])
topics = job["topics"]

def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)

probe = subprocess.run(
    ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(mp3)],
    check=True, capture_output=True, text=True,
)
total = int(round(float(probe.stdout.strip())))
hours, rem = divmod(total, 3600)
minutes, seconds = divmod(rem, 60)
duration = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
nbytes = mp3.stat().st_size

def html_text(value):
    return (value.replace("&", "&amp;")
                 .replace("<", "&lt;")
                 .replace(">", "&gt;")
                 .replace("`", "&#96;")
                 .replace("$", "&#36;"))

def attr(value):
    return html_text(value).replace('"', "&quot;")

def pt(seconds):
    hours = int(seconds // 3600)
    rem = seconds - hours * 3600
    minutes = int(rem // 60)
    secs = rem - minutes * 60
    if abs(secs - round(secs)) < 1e-6:
        sec_text = str(int(round(secs)))
    else:
        sec_text = f"{secs:.2f}".rstrip("0").rstrip(".")
    parts = []
    if hours:
        parts.append(f"{hours}H")
    if minutes:
        parts.append(f"{minutes}M")
    if sec_text != "0" or not parts:
        parts.append(f"{sec_text}S")
    return "PT" + "".join(parts)

def start_attr(seconds):
    if abs(seconds - round(seconds)) < 1e-6:
        return str(int(round(seconds)))
    return f"{seconds:.2f}".rstrip("0").rstrip(".")

items = []
chapters = []
any_links = False
for topic in topics:
    title = topic["title"]
    visible = html_text(title)
    urls = topic["urls"]
    any_links = any_links or bool(urls)
    if len(urls) == 1:
        body = f'<a href="{attr(urls[0])}" rel="noopener">{visible}</a>'
    elif urls:
        links = [f'<a href="{attr(urls[0])}" rel="noopener">{visible}</a>']
        links += [f'<a href="{attr(url)}" rel="noopener">{attr(url.split("/")[2])}</a>' for url in urls[1:]]
        body = " and ".join(links) if len(links) == 2 else ", ".join(links[:-1]) + ", and " + links[-1]
    else:
        body = visible
    if topic["time"] is None:
        items.append(f"  <li><span>{body}</span></li>")
    else:
        items.append(
            f'  <li><time datetime="{pt(topic["time"])}" data-start="{start_attr(topic["time"])}">{html_text(topic["shown"])}</time><span>{body}</span></li>'
        )
        if visible == title:
            chapters.append({"startTime": topic["time"] if topic["time"] % 1 else int(topic["time"]), "title": title})

detail = []
if topics[0]["time"] is not None:
    detail.append("The time is where each one starts")
if any_links:
    detail.append("the link goes to the original" if detail else "The link goes to the original")
if not detail:
    second = "Amin and I go through a series of topics in this episode."
elif len(detail) == 2:
    second = "Amin and I go through a series of topics in this episode. The time is where each one starts, and the link goes to the original."
else:
    second = f"Amin and I go through a series of topics in this episode. {detail[0]}."

names = [topic["title"] for topic in topics]
if len(names) == 1:
    summary = f"Amin and I talk through {names[0]}."
elif len(names) == 2:
    summary = f"Amin and I talk through {names[0]} and {names[1]}."
elif len(names) <= 6:
    summary = "Amin and I talk through " + ", ".join(names[:-1]) + ", and " + names[-1] + "."
else:
    summary = "A series of topics in this episode."
if len(summary) > 180:
    summary = "A series of topics in this episode."

keywords = []
for name in names:
    keywords.append(name)
    if len(", ".join(keywords)) > 120:
        keywords.pop()
        break
if not keywords:
    keywords = ["technology"]

def quote(value):
    return '"' + value.replace('"', "'") + '"'

lines = [
    "---",
    "layout: episode",
    f"title: {quote(job['slug'])}",
    f"audioUrl: {job['audio_url']}",
    f"bytes: {nbytes}",
    f"duration: {duration}",
    f"episode: {job['episode']}",
    "season: 1",
    "explicit: no",
    f"summary: {quote(summary)}",
    f"keywords: {quote(', '.join(keywords))}",
]
chapters_path = Path(job["chapters"])
if chapters and len(chapters) == len(topics):
    lines.append(f"chapters: chapters/{job['slug']}.json")
lines += [
    "---",
    "",
    f"<p>Hello, I hope you're well. This is episode {job['slug']} of The Last Question. I'm Arash.</p>",
    "",
    f"<p>{html_text(second)}</p>",
    "",
    "<h2>In this episode</h2>",
    '<ol class="chapters">',
    *items,
    "</ol>",
    "",
    '<p>You can follow new episodes on ${ site.telegram ? \'<a href="\' + htmlEscape(site.telegram) + \'" rel="noopener">our Telegram channel</a>\' : \'our Telegram channel\' }.</p>',
    "",
]
post_path = Path(job["post"])
post_path.parent.mkdir(parents=True, exist_ok=True)
post_path.write_text("\n".join(lines))

if chapters and len(chapters) == len(topics):
    chapters_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {"version": "1.2", "chapters": chapters}
    chapters_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
elif chapters_path.exists():
    chapters_path.unlink()

print(f"bytes={nbytes}")
print(f"duration={duration}")
PY

post="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["post"])' "$work/job.json")"
chapters="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["chapters"])' "$work/job.json")"
slug="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["slug"])' "$work/job.json")"
audio_url="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["audio_url"])' "$work/job.json")"

post_rel="${post#"$SITE/"}"
chapters_rel="${chapters#"$SITE/"}"

paths=("$post_rel")
git -C "$SITE" add -- "$post_rel"
if [[ -f "$chapters" ]] || git -C "$SITE" ls-files --error-unmatch -- "$chapters_rel" >/dev/null 2>&1; then
  git -C "$SITE" add -- "$chapters_rel"
  paths+=("$chapters_rel")
fi
if git -C "$SITE" diff --cached --quiet -- "${paths[@]}"; then
  echo "Post unchanged."
else
  git -C "$SITE" commit -m "Publish episode ${slug}." -- "${paths[@]}" >/dev/null
  echo "Committed episode ${slug}."
fi

echo "$mp3"
echo "$cover"
echo "$post"
echo "Upload $(basename "$mp3") to $audio_url before you push."
