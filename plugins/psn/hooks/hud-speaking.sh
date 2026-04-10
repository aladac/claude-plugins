#!/usr/bin/env bash
# HUD TTS indicator — terminal-style top-down line on PSN HUD canvas
# Usage: hud-speaking.sh start|stop
# Silently exits if HUD bridge is not running

BRIDGE="http://127.0.0.1:9876"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TS=$(date +"%H:%M:%S")

case "${1:-}" in
  start)
    DETAIL="  >> Speaking"
    DETAIL_COLOR="#66cc88"
    "$SCRIPT_DIR/hud-mood.sh" speaking
    ;;
  stop)
    DETAIL="  -- Stopped"
    DETAIL_COLOR="#668877"
    "$SCRIPT_DIR/hud-mood.sh" ready
    ;;
  *)
    exit 0
    ;;
esac

SCRIPT="window.PSN.writeLine && window.PSN.writeLine([{\"text\":\"[$TS]  \",\"color\":\"#668877\",\"font\":\"13px monospace\"},{\"text\":\"TTS\",\"color\":\"#00ff88\",\"font\":\"bold 13px monospace\"},{\"text\":\"$DETAIL\",\"color\":\"$DETAIL_COLOR\",\"font\":\"13px monospace\"}]);"

curl -s -X POST "$BRIDGE/eval" \
  -H 'Content-Type: application/json' \
  -d "{\"script\": $(printf '%s' "$SCRIPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}" >/dev/null 2>&1

exit 0
