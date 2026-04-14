#!/usr/bin/env bash
# HUD hook notifier — sends log lines and avatar state to marauder-visor
# Usage: hud-notify.sh <hook_name> [detail]
# Silently exits if HUD bridge is not running

BRIDGE="http://127.0.0.1:9876"
HOOK="${1:-unknown}"
DETAIL="${2:-}"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set mood/avatar based on hook type
case "$HOOK" in
  SessionStart)     "$SCRIPT_DIR/hud-mood.sh" ready ;;
  SessionEnd)       "$SCRIPT_DIR/hud-mood.sh" ready ;;
  PreToolUse|PostToolUse)
    # Set working avatar unless speaking takes priority
    curl -s -X POST "$BRIDGE/avatar" -H 'Content-Type: application/json' \
      -d '{"state": "working"}' >/dev/null 2>&1
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

# Build segments JSON
if [ -n "$DETAIL" ]; then
  SEGMENTS="[{\"text\":\"[$TS]  \",\"color\":\"#668877\"},{\"text\":\"$HOOK\",\"color\":\"#00ff88\",\"bold\":true},{\"text\":\"  $DETAIL\",\"color\":\"$COLOR\"}]"
else
  SEGMENTS="[{\"text\":\"[$TS]  \",\"color\":\"#668877\"},{\"text\":\"$HOOK\",\"color\":\"#00ff88\",\"bold\":true}]"
fi

curl -s -X POST "$BRIDGE/log" \
  -H 'Content-Type: application/json' \
  -d "{\"segments\": $SEGMENTS}" >/dev/null 2>&1

exit 0
