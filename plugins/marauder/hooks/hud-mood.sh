#!/usr/bin/env bash
# HUD mood indicator — sets mood and avatar state via marauder-visor REST API
# Usage: hud-mood.sh <mood>
# Moods: ready, thinking, working, speaking, success, warning, error, fun, focused, proud

BRIDGE="http://127.0.0.1:9876"
MOOD="${1:-ready}"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

# Set mood
curl -s -X POST "$BRIDGE/mood" \
  -H 'Content-Type: application/json' \
  -d "{\"mood\": \"$MOOD\"}" >/dev/null 2>&1

# Map mood to avatar state
case "$MOOD" in
  speaking) AVATAR="speaking" ;;
  thinking) AVATAR="thinking" ;;
  working|focused) AVATAR="working" ;;
  *) AVATAR="idle" ;;
esac

# Set avatar
curl -s -X POST "$BRIDGE/avatar" \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"$AVATAR\"}" >/dev/null 2>&1

exit 0
