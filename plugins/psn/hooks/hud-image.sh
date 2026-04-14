#!/usr/bin/env bash
# HUD image display — show an image on the marauder-visor viewport
# Usage: hud-image.sh <path_or_url> [label]
# Supports: local files, remote files (scp from junkpile), URLs

set -euo pipefail

BRIDGE="http://127.0.0.1:9876"
INPUT="${1:-}"
LABEL="${2:-}"

if [ -z "$INPUT" ]; then
  echo "Usage: hud-image.sh <image_path> [label]"
  exit 1
fi

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

TMPFILE="/tmp/hud-image-display.png"

# Resolve input to a local file
if [[ "$INPUT" == http* ]]; then
  curl -sL "$INPUT" -o "$TMPFILE" 2>/dev/null
elif [[ "$INPUT" == j:* ]]; then
  REMOTE_PATH="${INPUT#j:}"
  scp "j:$REMOTE_PATH" "$TMPFILE" 2>/dev/null
elif [ -f "$INPUT" ]; then
  TMPFILE="$INPUT"
else
  echo "File not found: $INPUT"
  exit 1
fi

if [ ! -s "$TMPFILE" ]; then
  echo "Empty file"
  exit 1
fi

# Send to visor via /image endpoint with file:// source
curl -s -X POST "$BRIDGE/image" \
  -H 'Content-Type: application/json' \
  -d "{\"source\": \"file://$TMPFILE\", \"title\": \"${LABEL:-Image}\", \"tint\": true}" >/dev/null 2>&1

# Clean up only if we created a temp copy
if [[ "$TMPFILE" == "/tmp/hud-image-display.png" ]]; then
  rm -f "$TMPFILE" 2>/dev/null
fi
