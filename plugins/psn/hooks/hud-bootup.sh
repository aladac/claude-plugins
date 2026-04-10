#!/usr/bin/env bash
# HUD bootup sequence — animated startup then normal layout
BRIDGE="http://127.0.0.1:9876"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

# Fire animation and schedule reinit in background — don't block the hook
(
  # Run bootup animation
  python3 -c "
import json
with open('$SCRIPT_DIR/hud-bootup.js') as f:
    script = f.read()
print(json.dumps({'script': script}))
" | curl -s -X POST "$BRIDGE/eval" -H 'Content-Type: application/json' -d @- >/dev/null 2>&1

  # Wait for animation to finish, then reinit for live hooks
  sleep 8
  "$SCRIPT_DIR/hud-init.sh"
) &

exit 0
