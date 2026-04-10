#!/usr/bin/env bash
# HUD sweep — camera room sweep with green tint displayed on HUD viewport
# Usage: hud-sweep.sh
# Captures 3x3 PTZ sweep, green-tints, montages, displays on viewport with scanlines

set -uo pipefail

BRIDGE="http://127.0.0.1:9876"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CAM_SKILL="$HOME/Projects/personality-plugin/skills/cam/cam.sh"
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

# Create 3x3 montage: TL T TR / L C R / BL B BR
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

# Compress for HUD bridge
magick "$SWEEP_DIR/grid.png" -resize 960x720 -quality 60 "$SWEEP_DIR/grid_small.jpg"

"$SCRIPT_DIR/hud-notify.sh" "Sweep" "Displaying on viewport"

# Display on HUD viewport with scanline overlay
python3 -c "
import json, base64

with open('$SWEEP_DIR/grid_small.jpg', 'rb') as f:
    b64 = base64.b64encode(f.read()).decode()

script = f'''var img = new Image();
img.onload = function() {{
    var c = window.PSN.canvas;
    var cv = c.canvas;
    var W = cv.width; var H = cv.height;
    var pad = 20; var midX = Math.floor(W * 0.45); var botY = H - 50;
    var avBoxW = 100; var avX = Math.floor(W / 2);
    var rightLeft = avX + avBoxW/2 + 15;
    var rightW = W - rightLeft - pad;
    var vpad = 12;
    var vx1 = rightLeft+vpad+5, vy1 = pad+50, vx2 = rightLeft+rightW-vpad-5, vy2 = botY-pad-vpad-5;
    var vw = vx2-vx1; var vh = vy2-vy1;
    c.fillStyle = \"#1d232a\";
    c.fillRect(vx1, vy1, vw, vh);
    var scale = Math.min(vw / img.width, vh / img.height);
    var iw = img.width * scale; var ih = img.height * scale;
    var ix = vx1 + (vw - iw) / 2; var iy = vy1 + (vh - ih) / 2;
    c.drawImage(img, ix, iy, iw, ih);
    c.strokeStyle = \"rgba(0,255,136,0.04)\";
    c.lineWidth = 1;
    for (var s = iy; s < iy+ih; s += 3) {{
        c.beginPath(); c.moveTo(ix, s); c.lineTo(ix+iw, s); c.stroke();
    }}
    c.fillStyle = \"#00ff88\"; c.font = \"bold 10px monospace\";
    c.fillText(\"SWEEP 3x3 — \" + new Date().toLocaleTimeString(\"en-GB\"), vx1+5, vy2-5);
}};
img.src = \"data:image/jpeg;base64,{b64}\";'''

print(json.dumps({'script': script}))
" | curl -s -X POST "$BRIDGE/eval" -H 'Content-Type: application/json' -d @- >/dev/null 2>&1

"$SCRIPT_DIR/hud-mood.sh" ready
"$SCRIPT_DIR/hud-notify.sh" "Sweep" "Complete"

# Cleanup
rm -rf "$SWEEP_DIR"
