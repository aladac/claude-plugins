#!/usr/bin/env bash
# HUD sweep — camera room sweep displayed on marauder-visor viewport
# Usage: hud-sweep.sh

set -uo pipefail

BRIDGE="http://127.0.0.1:9876"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CAM_SKILL="$HOME/Projects/marauder-plugin/skills/cam/cam.sh"
SWEEP_DIR="/tmp/sweep_$$"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

mkdir -p "$SWEEP_DIR"

"$SCRIPT_DIR/hud-notify.sh" "Sweep" "Initiating room scan"
"$SCRIPT_DIR/hud-mood.sh" working

# Capture 9 frames
bash "$CAM_SKILL" sweep "$SWEEP_DIR" 2>/dev/null

# Find the timestamp
TS=$(ls "$SWEEP_DIR"/sweep_*_0_C.jpg 2>/dev/null | sed 's/.*sweep_\([0-9]*\)_.*/\1/')
if [ -z "$TS" ]; then
  "$SCRIPT_DIR/hud-notify.sh" "Sweep" "FAILED — no frames captured"
  "$SCRIPT_DIR/hud-mood.sh" error
  rm -rf "$SWEEP_DIR"
  exit 1
fi

"$SCRIPT_DIR/hud-notify.sh" "Sweep" "9 frames captured, tinting"

# Green tint all frames
for f in "$SWEEP_DIR"/sweep_*.jpg; do
  base=$(basename "$f" .jpg)
  magick "$f" -modulate 100,0,100 -fill "#00ff8830" -colorize 60 -brightness-contrast 0,-20 "$SWEEP_DIR/${base}_green.jpg"
done

# Create 3x3 montage
magick montage \
  "$SWEEP_DIR/sweep_${TS}_1_TL_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_2_T_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_3_TR_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_8_L_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_0_C_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_4_R_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_7_BL_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_6_B_green.jpg" \
  "$SWEEP_DIR/sweep_${TS}_5_BR_green.jpg" \
  -tile 3x3 -geometry 320x240+2+2 -background "#1d232a" \
  "$SWEEP_DIR/grid.png" 2>/dev/null

# Compress
magick "$SWEEP_DIR/grid.png" -resize 960x720 -quality 60 "$SWEEP_DIR/grid_small.jpg"

"$SCRIPT_DIR/hud-notify.sh" "Sweep" "Displaying on viewport"

# Display via /image endpoint
curl -s -X POST "$BRIDGE/image" \
  -H 'Content-Type: application/json' \
  -d "{\"source\": \"file://$SWEEP_DIR/grid_small.jpg\", \"title\": \"SWEEP 3x3\", \"tint\": true}" >/dev/null 2>&1

"$SCRIPT_DIR/hud-mood.sh" ready
"$SCRIPT_DIR/hud-notify.sh" "Sweep" "Complete"

rm -rf "$SWEEP_DIR"
