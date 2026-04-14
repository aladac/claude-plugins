#!/usr/bin/env bash
# HUD generate — generate an image via ComfyUI and display on HUD
# Usage: hud-generate.sh <prompt> [options]
# Generates via tsr on junkpile, pulls result, displays on HUD canvas

set -euo pipefail

BRIDGE="http://127.0.0.1:9876"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT="${1:-}"
shift 2>/dev/null || true

if [ -z "$PROMPT" ]; then
  echo "Usage: hud-generate.sh <prompt> [-W width] [-H height] [--steps N] [-m model]"
  echo "  hud-generate.sh 'a cat on a windowsill'"
  echo "  hud-generate.sh 'cyberpunk city' -W 768 -H 512 --steps 25"
  exit 1
fi

# Defaults
WIDTH="${WIDTH:-512}"
HEIGHT="${HEIGHT:-512}"
STEPS="${STEPS:-15}"
EXTRA_ARGS=("${@+$@}")

echo "Generating: $PROMPT"
echo "  Size: ${WIDTH}x${HEIGHT}, Steps: $STEPS"

# Notify HUD
"$SCRIPT_DIR/hud-notify.sh" "Generate" "$PROMPT"

# Generate via tsr remote
OUTPUT_JSON=$(tsr generate "$PROMPT" \
  --remote junkpile \
  -W "$WIDTH" -H "$HEIGHT" \
  --steps "$STEPS" \
  ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} \
  -j 2>&1)

# Parse the output filename
FILENAME=$(echo "$OUTPUT_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['images'][0])" 2>/dev/null)

if [ -z "$FILENAME" ]; then
  echo "Generation failed:"
  echo "$OUTPUT_JSON"
  "$SCRIPT_DIR/hud-notify.sh" "Generate" "FAILED"
  exit 1
fi

REMOTE_PATH="/home/comfyui/output/$FILENAME"
echo "Generated: $FILENAME"

# Display on HUD
"$SCRIPT_DIR/hud-image.sh" "j:$REMOTE_PATH" "Generated: $PROMPT"

echo "Displayed on HUD"
