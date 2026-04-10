#!/usr/bin/env bash
# HUD hook notifier — terminal-style top-down output on PSN HUD canvas
# Usage: hud-notify.sh <hook_name> [detail]
# Silently exits if HUD bridge is not running

BRIDGE="http://127.0.0.1:9876"
HOOK="${1:-unknown}"
DETAIL="${2:-}"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set mood based on hook type (speaking takes priority — don't override it)
CURRENT_STATE=$(curl -s -X POST "$BRIDGE/eval" -H 'Content-Type: application/json' -d '{"script": "document.title = window.PSN._avatarState || \"idle\""}' 2>/dev/null)
case "$HOOK" in
  SessionStart)     "$SCRIPT_DIR/hud-mood.sh" ready ;;
  SessionEnd)       "$SCRIPT_DIR/hud-mood.sh" ready ;;
  PreToolUse|PostToolUse)
    # Don't override speaking with working
    curl -s -X POST "$BRIDGE/eval" -H 'Content-Type: application/json' \
      -d '{"script": "if(window.PSN._avatarState!==\"speaking\"){window.PSN.avatar && window.PSN.avatar(\"working\")}"}' >/dev/null 2>&1
    # Also update SERE eye (working, unless speaking takes priority — let eye server decide)
    curl -sf -X POST "http://127.0.0.1:9877/eye/state" \
      -H 'Content-Type: application/json' \
      -d '{"state": "working"}' >/dev/null 2>&1 &
    "$SCRIPT_DIR/hud-mood.sh" working
    ;;
  UserPromptSubmit) "$SCRIPT_DIR/hud-mood.sh" thinking ;;
  Notification)     "$SCRIPT_DIR/hud-mood.sh" success ;;
  Stop)             "$SCRIPT_DIR/hud-mood.sh" ready ;;
esac

TS=$(date +"%H:%M:%S")

# Color based on hook type
case "$HOOK" in
  SessionStart|SessionEnd)  COLOR="#00ff88" ;;
  Notification)             COLOR="#ffaa00" ;;
  Stop)                     COLOR="#ff4444" ;;
  *)                        COLOR="#66cc88" ;;
esac

DETAIL_PART=""
if [ -n "$DETAIL" ]; then
  DETAIL_PART=",{\"text\":\"  $DETAIL\",\"color\":\"$COLOR\",\"font\":\"13px monospace\"}"
fi

SCRIPT="window.PSN.writeLine && window.PSN.writeLine([{\"text\":\"[$TS]  \",\"color\":\"#668877\",\"font\":\"13px monospace\"},{\"text\":\"$HOOK\",\"color\":\"#00ff88\",\"font\":\"bold 13px monospace\"}$DETAIL_PART]);"

curl -s -X POST "$BRIDGE/eval" \
  -H 'Content-Type: application/json' \
  -d "{\"script\": $(printf '%s' "$SCRIPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}" >/dev/null 2>&1

exit 0
