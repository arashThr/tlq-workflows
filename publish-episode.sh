#!/usr/bin/env bash
# Turn a finished episode video into the mp3, the cover, and a committed site post.
# Usage: ./publish-episode.sh [--episode N] [--date YYYY-MM-DD] [--before-intro] [--dry-run] VIDEO TOPICS.txt
#
# Topic times are positions in VIDEO. The page shows each start, rounded to the
# nearest second. A topic may be a range, and the next line may be "Original source".
# --before-intro adds the intro file beside the video when the notes were taken
# before that intro was attached. --dry-run prints the chapters and writes nothing.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SITE="${TLQ_SITE:-/Users/ATAHER/Documents/workspace/personal/tlqdev}"
ASSETS="${TLQ_ASSETS:-/Users/ATAHER/Documents/workspace/personal/tlq/assets}"
TEMPLATE="${TLQ_COVER:-$ASSETS/EP02.png}"

usage() {
  echo "Usage: $0 [--episode N] [--date YYYY-MM-DD] [--before-intro] [--dry-run] VIDEO TOPICS.txt" >&2
  echo "TOPICS.txt can be - to read the topics from stdin." >&2
  exit 1
}

episode=""
publish_date=""
before_intro=0
dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --episode) episode="${2:-}"; shift 2 ;;
    --date) publish_date="${2:-}"; shift 2 ;;
    --before-intro) before_intro=1; shift ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *) break ;;
  esac
done

[[ $# -eq 2 ]] || usage
video="$1"
topics="$2"

for cmd in ffmpeg ffprobe python3; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
if [[ "$dry" -eq 0 ]]; then
  for cmd in swiftc git; do
    command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
  done
  [[ -f "$TEMPLATE" ]] || { echo "Cover template not found: $TEMPLATE" >&2; exit 1; }
  git -C "$SITE" rev-parse --is-inside-work-tree >/dev/null
fi

[[ -f "$video" ]] || { echo "Video not found: $video" >&2; exit 1; }
[[ -d "$SITE/site/content" ]] || { echo "Site content folder not found: $SITE/site/content" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [[ "$topics" == "-" ]]; then
  cat > "$work/topics.txt"
  topics="$work/topics.txt"
fi
[[ -f "$topics" ]] || { echo "Topics file not found: $topics" >&2; exit 1; }

cat > "$work/publish.py" << 'PY'
import json, re, subprocess, sys
from datetime import date
from pathlib import Path

TIME = r"\d{1,2}:\d{2}(?::\d{2})?(?:\.\d+)?"
TIMED = re.compile(
    rf"^(?:\d+\.\s+)?({TIME})(?:\s*[-–—]\s*{TIME})?(?:\s*[·•]\s*|\s+)(.*)$"
)
SOURCE = re.compile(r"(?i)^original source\b")
NOISE = re.compile(
    r"(?i)\s*(?:additional original-source context|original visual asset|original pdf, page \d+\.?|silent source-video excerpt:.*)\s*"
)
CLARIFY = re.compile(r"(?i)\s*editor clarification:\s*(.*)$")

def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)

def duration(path):
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    )
    return float(probe.stdout.strip())

def parse_time(text):
    parts = text.split(":")
    try:
        if len(parts) == 2:
            hours, minutes, seconds = 0, int(parts[0]), float(parts[1])
        elif len(parts) == 3:
            hours, minutes, seconds = int(parts[0]), int(parts[1]), float(parts[2])
        else:
            fail(f"Bad time: {text}")
    except ValueError:
        fail(f"Bad time: {text}")
    if hours < 0 or minutes < 0 or seconds < 0 or seconds >= 60 or (len(parts) == 3 and minutes >= 60):
        fail(f"Bad time: {text}")
    return hours * 3600 + minutes * 60 + seconds

def clock(seconds):
    minutes, secs = divmod(int(seconds), 60)
    return f"{minutes:02d}:{secs:02d}"

def round_half_up(seconds):
    return int(seconds + 0.5)

def covered(part, title):
    part, title = part.lower(), title.lower()
    if part in title:
        return True
    words = [word for word in re.findall(r"[a-z0-9]+", part) if len(word) > 2]
    return bool(words) and all(word in title for word in words)

def clean_credit(line, title):
    text = re.sub(r"(?i)^original source\s*[·•]\s*", "", line).strip()
    clarification = ""
    found = CLARIFY.search(text)
    if found:
        clarification = found.group(1).strip(" .")
        text = text[:found.start()]
    text = NOISE.sub(" ", text)
    parts = []
    for part in re.split(r"\s*[·•]\s*", text):
        part = part.strip(" .")
        if part and not covered(part, title):
            parts.append(part)
    credit = ", ".join(parts)
    if clarification:
        credit = f"{credit}. {clarification}" if credit else clarification
    return credit.strip(" .")

def split_urls(text):
    tokens = text.split()
    urls = []
    while tokens and re.fullmatch(r"https?://\S+", tokens[-1]):
        urls.insert(0, tokens.pop())
    return " ".join(tokens).strip(), urls

def parse_topics(path):
    topics = []
    for raw in Path(path).read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if SOURCE.match(line):
            if not topics:
                fail(f"Source line has no topic: {raw}")
            credit = clean_credit(line, topics[-1]["name"])
            if credit:
                previous = topics[-1]["credit"]
                topics[-1]["credit"] = f"{previous}. {credit}" if previous else credit
            continue
        match = TIMED.fullmatch(line)
        if match:
            name, urls = split_urls(match.group(2).strip())
            if not name:
                fail(f"Missing topic title: {raw}")
            topics.append({
                "start": parse_time(match.group(1)),
                "name": name,
                "credit": "",
                "urls": urls,
            })
            continue
        if re.match(r"^\d+\.\s+", line) or re.search(TIME, line):
            fail(f"Could not read the time on this line: {raw}")
        name, urls = split_urls(line)
        if not name:
            fail(f"Missing topic title: {raw}")
        topics.append({"start": None, "name": name, "credit": "", "urls": urls})
    if not topics:
        fail("The topics file is empty")
    return topics

def display_title(topic):
    credit = topic["credit"].strip(" .")
    if not credit:
        return topic["name"]
    return f"{topic['name']} — {credit}."

def episode_in(name):
    match = re.search(r"(?i)(?:^|[^a-z])ep\s*-?\s*(\d+)", name)
    return int(match.group(1)) if match else None

def find_intro(video, episode):
    folder = video.parent
    names = [f"EP{episode:02d}-Intro.mp4", f"EP{episode}-Intro.mp4", "intro.mp4"]
    for name in names:
        path = folder / name
        if path.is_file() and path.resolve() != video.resolve():
            return path
    for path in folder.iterdir():
        if path.is_file() and path.resolve() != video.resolve() and "intro" in path.stem.lower() and path.suffix.lower() == ".mp4":
            return path
    return None

def html_text(value):
    return (value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                 .replace("`", "&#96;").replace("$", "&#36;"))

def attr(value):
    return html_text(value).replace('"', "&quot;")

def pt(seconds):
    hours, rem = divmod(int(seconds), 3600)
    minutes, secs = divmod(rem, 60)
    body = f"{hours}H" if hours else ""
    if minutes or hours:
        body += f"{minutes}M"
    return "PT" + body + f"{secs}S"

def link_body(title, urls):
    visible = html_text(title)
    if len(urls) == 1:
        return f'<a href="{attr(urls[0])}" rel="noopener">{visible}</a>'
    if urls:
        links = [f'<a href="{attr(urls[0])}" rel="noopener">{visible}</a>']
        links += [f'<a href="{attr(url)}" rel="noopener">{attr(url.split("/")[2])}</a>' for url in urls[1:]]
        if len(links) == 2:
            return " and ".join(links)
        return ", ".join(links[:-1]) + ", and " + links[-1]
    return visible

def plan(args):
    video, topics_path, episode_arg, date_arg, site, job_path, before_flag = args
    site, video = Path(site), Path(video)
    before = before_flag == "1"

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

    topics = parse_topics(topics_path)
    intro = find_intro(video, episode)
    offset = 0.0
    if before:
        if intro is None:
            fail(f"No intro file next to the video. Expected EP{episode:02d}-Intro.mp4")
        offset = duration(intro)
    elif intro is not None:
        print(f"Intro {intro.name} is {duration(intro):.1f}s and was not added. Pass --before-intro if the notes were taken before it.")

    video_len = duration(video)
    previous = -1
    for topic in topics:
        topic["title"] = display_title(topic)
        if topic["start"] is None:
            topic["seconds"] = None
            topic["shown"] = None
            continue
        seconds = round_half_up(topic["start"] + offset)
        if seconds <= previous:
            fail(f"Topics are out of time order after rounding: {topic['title']}")
        if seconds >= video_len:
            fail(f"{topic['title']} starts at {clock(seconds)}, past the end of the video")
        previous = seconds
        topic["seconds"] = seconds
        topic["shown"] = clock(seconds)
    if before:
        print(f"Added {offset:.1f}s from {intro.name} to each chapter.")

    slug = f"{episode:02d}"
    content = site / "site/content"
    for post in content.glob("*.md"):
        text = post.read_text()
        if re.search(rf'(?m)^episode:\s*"?{episode}"?\s*$', text) and not post.name.endswith(f"-{slug}.md"):
            fail(f"{post.name} is already episode {episode}")
    matches = sorted(content.glob(f"*-{slug}.md"))
    post_path = matches[-1] if matches else content / f"{publish_date}-{slug}.md"

    for topic in topics:
        if topic["seconds"] is None:
            print(f"--  {topic['title']}")
        else:
            print(f"{topic['shown']}  {topic['seconds']}  {topic['title']}")

    job = {
        "episode": episode,
        "slug": slug,
        "year": post_path.name[:4],
        "topics": topics,
        "mp3": str(video.with_name(f"TLQ-EP{slug}.mp3")),
        "cover": str(video.with_name(f"EP{slug}.png")),
        "post": str(post_path),
        "chapters": str(site / "site/statics/chapters" / f"{slug}.json"),
        "audio_url": f"https://audio.tlq.dev/TLQ-EP{slug}.mp3",
        "tag_title": f"TLQ {slug}",
    }
    Path(job_path).write_text(json.dumps(job))

def page(args):
    job_path, mp3_path = args
    job = json.loads(Path(job_path).read_text())
    mp3 = Path(mp3_path)
    topics = job["topics"]
    total = round_half_up(duration(mp3))
    hours, rem = divmod(total, 3600)
    minutes, seconds = divmod(rem, 60)
    length = f"{hours:02d}:{minutes:02d}:{seconds:02d}"

    items = []
    chapters = []
    for topic in topics:
        body = link_body(topic["title"], topic["urls"])
        if topic["seconds"] is None:
            items.append(f"  <li><span>{body}</span></li>")
            continue
        items.append(
            f'  <li><time datetime="{pt(topic["seconds"])}" data-start="{topic["seconds"]}">'
            f'{html_text(topic["shown"])}</time><span>{body}</span></li>'
        )
        if html_text(topic["title"]) == topic["title"]:
            chapters.append({"startTime": topic["seconds"], "title": topic["title"]})

    names = [topic["name"] for topic in topics]
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

    extra = ""
    has_time = any(topic["seconds"] is not None for topic in topics)
    has_link = any(topic["urls"] for topic in topics)
    if has_time and has_link:
        extra = " The time is where each one starts, and the link goes to the original."
    elif has_time:
        extra = " The time is where each one starts."
    elif has_link:
        extra = " The link goes to the original."

    def quote(value):
        return '"' + value.replace('"', "'") + '"'

    lines = [
        "---",
        "layout: episode",
        f"title: {quote(job['slug'])}",
        f"audioUrl: {job['audio_url']}",
        f"bytes: {mp3.stat().st_size}",
        f"duration: {length}",
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
        f"<p>Amin and I go through a series of topics in this episode.{extra}</p>",
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
        chapters_path.write_text(json.dumps({"version": "1.2", "chapters": chapters}, indent=2, ensure_ascii=False) + "\n")
    elif chapters_path.exists():
        chapters_path.unlink()
    print(f"bytes={mp3.stat().st_size}")
    print(f"duration={length}")

if sys.argv[1] == "plan":
    plan(sys.argv[2:])
elif sys.argv[1] == "page":
    page(sys.argv[2:])
else:
    fail("Unknown publish command")
PY

python3 "$work/publish.py" plan "$video" "$topics" "$episode" "$publish_date" "$SITE" "$work/job.json" "$before_intro"

if [[ "$dry" -eq 1 ]]; then
  exit 0
fi

# shellcheck disable=SC2046
eval "$(python3 - "$work/job.json" << 'PY'
import json, shlex, sys
job = json.load(open(sys.argv[1]))
for key in ("mp3", "cover", "tag_title", "year", "episode", "post", "chapters", "slug", "audio_url"):
    print(f"{key}={shlex.quote(str(job[key]))}")
PY
)"

bin="/tmp/tlq-cover-number"
if [[ ! -x "$bin" || "$ROOT/cover.swift" -nt "$bin" ]]; then
  swiftc -O -o "$bin" "$ROOT/cover.swift"
fi
"$bin" "$TEMPLATE" "$cover" "$episode"

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

python3 "$work/publish.py" page "$work/job.json" "$mp3"

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
