#!/usr/bin/env bash
# HUD image display — show an image on the PSN HUD canvas
# Usage: hud-image.sh <path_or_url> [label]
# Supports: local files, remote files (scp from junkpile), URLs
# Silently exits if HUD bridge is not running

set -euo pipefail

BRIDGE="http://127.0.0.1:9876"
INPUT="${1:-}"
LABEL="${2:-}"

if [ -z "$INPUT" ]; then
  echo "Usage: hud-image.sh <image_path> [label]"
  echo "  hud-image.sh /tmp/photo.png"
  echo "  hud-image.sh j:/home/comfyui/output/img.png 'ComfyUI output'"
  echo "  hud-image.sh https://example.com/image.png 'From web'"
  exit 1
fi

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

TMPFILE="/tmp/hud-image-display.png"

# Resolve input to a local file
if [[ "$INPUT" == http* ]]; then
  # URL — download
  curl -sL "$INPUT" -o "$TMPFILE" 2>/dev/null
elif [[ "$INPUT" == j:* ]]; then
  # Junkpile remote path — scp
  REMOTE_PATH="${INPUT#j:}"
  scp "j:$REMOTE_PATH" "$TMPFILE" 2>/dev/null
elif [ -f "$INPUT" ]; then
  # Local file
  cp "$INPUT" "$TMPFILE"
else
  echo "File not found: $INPUT"
  exit 1
fi

# Verify we got an image
if [ ! -s "$TMPFILE" ]; then
  echo "Empty file"
  exit 1
fi

# Base64 encode and send to HUD
python3 -c "
import json, base64, sys

with open('$TMPFILE', 'rb') as f:
    b64 = base64.b64encode(f.read()).decode()

label = '$LABEL' or 'Image'
label_js = label.replace(\"'\", \"\\\\\'\")

script = f'''var img = new Image();
img.onload = function() {{
    var c = window.PSN.canvas;
    var cv = c.canvas;
    var scale = Math.min(cv.width / img.width, cv.height / img.height) * 0.85;
    var w = img.width * scale;
    var h = img.height * scale;
    var x = (cv.width - w) / 2;
    var y = (cv.height - h) / 2;
    window.PSN.clear();
    c.drawImage(img, x, y, w, h);
    c.font = 'bold 13px monospace';
    c.fillStyle = '#00ff88';
    c.fillText('{label_js}', 50, cv.height - 15);
    window.PSN._cursorY = cv.height - 30;
}};
img.src = 'data:image/png;base64,{b64}';'''

print(json.dumps({'script': script}))
" | curl -s -X POST "$BRIDGE/eval" \
  -H 'Content-Type: application/json' -d @-

rm -f "$TMPFILE" 2>/dev/null
