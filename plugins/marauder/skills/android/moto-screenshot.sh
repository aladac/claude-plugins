#!/usr/bin/env bash
# moto-screenshot.sh — Capture Moto G52 screen via ADB over WiFi through junkpile
# Returns the local path to the screenshot PNG.
set -euo pipefail

MOTO_ADB="192.168.88.155:5555"
JUNKPILE="j"
OUTPUT="${1:-/tmp/moto_screen.png}"
ADB_PATH="/home/linuxbrew/.linuxbrew/bin/adb"

# Connect + screencap in one SSH call. Suppress connect noise.
ssh "$JUNKPILE" "
  $ADB_PATH connect $MOTO_ADB >/dev/null 2>&1
  $ADB_PATH -s $MOTO_ADB exec-out screencap -p
" > "$OUTPUT"

# Verify we got a valid PNG (at least 1KB).
SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT" 2>/dev/null || echo 0)
if [ "$SIZE" -lt 1000 ]; then
  echo "ERROR: screenshot too small (${SIZE} bytes) — ADB may have failed" >&2
  rm -f "$OUTPUT"
  exit 1
fi

echo "$OUTPUT"
