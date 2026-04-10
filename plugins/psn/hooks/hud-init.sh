#!/usr/bin/env bash
# HUD init — draws the full layout + avatar on session start
# Usage: hud-init.sh
# Silently exits if HUD bridge is not running

BRIDGE="http://127.0.0.1:9876"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

# Load and send layout
python3 -c "
import json
with open('$SCRIPT_DIR/hud-layout.js') as f:
    layout = f.read()
with open('$SCRIPT_DIR/hud-avatar.js') as f:
    avatar = f.read()
print(json.dumps({'script': layout + '\n' + avatar}))
" | curl -s -X POST "$BRIDGE/eval" -H 'Content-Type: application/json' -d @- >/dev/null 2>&1

exit 0
