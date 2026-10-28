#!/usr/bin/env bash
# Add cover art and basic metadata to an MP3 for TLQ
# Usage: ./add-metadata.sh input.mp3 cover.jpg [output.mp3]

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 input.mp3 cover.jpg [output.mp3]"
  exit 1
fi

INPUT="$1"
COVER="$2"
OUTPUT="${3:-${INPUT%.*}-meta.mp3}"

read -rp "Title: " TITLE
read -rp "Artist (default: TLQ / Arash & Amin): " ARTIST
ARTIST=${ARTIST:-"TLQ / Arash & Amin"}
read -rp "Album (default: The Last Question): " ALBUM
ALBUM=${ALBUM:-"The Last Question"}
read -rp "Year (default: 2026): " YEAR
YEAR=${YEAR:-"2026"}

ffmpeg -y -i "$INPUT" -i "$COVER" \
  -map 0 -map 1 \
  -c copy \
  -id3v2_version 3 \
  -metadata title="$TITLE" \
  -metadata artist="$ARTIST" \
  -metadata album="$ALBUM" \
  -metadata date="$YEAR" \
  -metadata:s:v title="Cover" \
  -metadata:s:v comment="Cover (front)" \
  "$OUTPUT"

echo "Done → $OUTPUT"
