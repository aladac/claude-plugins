#!/usr/bin/env bash
# HUD mood indicator — shows current mood emoji in top-right corner
# Usage: hud-mood.sh <mood>
# Moods: ready, thinking, working, speaking, success, warning, error, fun, focused, proud
# Silently exits if HUD bridge is not running

BRIDGE="http://127.0.0.1:9876"
MOOD="${1:-ready}"

# Bail silently if bridge is down
curl -sf "$BRIDGE/status" >/dev/null 2>&1 || exit 0

case "$MOOD" in
  ready)    ICON="⬡"; COLOR="#00ff88" ;;
  thinking) ICON="◉"; COLOR="#00ff88" ;;
  working)  ICON="⚡"; COLOR="#00ff88" ;;
  speaking) ICON="◈"; COLOR="#00ff88" ;;
  success)  ICON="✦"; COLOR="#00ff88" ;;
  warning)  ICON="△"; COLOR="#ffaa00" ;;
  error)    ICON="✕"; COLOR="#ff4444" ;;
  fun)      ICON="◇"; COLOR="#00ff88" ;;
  focused)  ICON="◆"; COLOR="#00ff88" ;;
  proud)    ICON="★"; COLOR="#00ff88" ;;
  *)        ICON="⬡"; COLOR="#00ff88" ;;
esac

# Draw mood icon in top-right corner + update avatar state
case "$MOOD" in
  speaking) AVATAR="speaking" ;;
  thinking) AVATAR="thinking" ;;
  working|focused) AVATAR="working" ;;
  *) AVATAR="idle" ;;
esac

SCRIPT="var c=window.PSN.canvas; var cv=c.canvas; c.fillStyle='#1d232a'; c.fillRect(cv.width-60,5,55,30); c.font='22px monospace'; c.fillStyle='$COLOR'; c.fillText('$ICON',cv.width-45,26); if(window.PSN.avatar){ var skip=('$AVATAR'==='working'||'$AVATAR'==='thinking')&&window.PSN._avatarState==='speaking'; if(!skip) window.PSN.avatar('$AVATAR'); }"

curl -s -X POST "$BRIDGE/eval" \
  -H 'Content-Type: application/json' \
  -d "{\"script\": \"$SCRIPT\"}" >/dev/null 2>&1

# Also update SERE eye
curl -sf -X POST "http://127.0.0.1:9877/eye/state" \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"$AVATAR\"}" >/dev/null 2>&1 &

exit 0
