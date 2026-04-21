#!/usr/bin/env bash
# sere-display.sh — Launch or stop the full SERE display stack on Moto G52
# Combines: keep-awake + X11 stack + marauder display in fullscreen Kitty
# Hybrid: MQTT for fire-and-forget, SSH for status queries and kitten @ ls.
# Usage: bash sere-display.sh {start|stop|status}
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MK_SCRIPT="${SCRIPT_DIR}/../moto-kitty/mk.sh"
MESH="marauder mesh send moto exec"
SSH_HOST="m"
KITTY_SOCKET="unix:/data/data/com.termux/files/usr/tmp/mykitty"

ssh_cmd() { ssh -o ConnectTimeout=5 "$SSH_HOST" "$@"; }

start() {
  echo "=== Starting SERE Display ==="

  # 1. Keep-awake (MQTT — fire-and-forget)
  echo "  keep-awake : enabling..."
  $MESH '{"command":"su -c \"svc power stayon true && settings put system screen_off_timeout 2147483647\""}' 2>/dev/null || true
  echo "  keep-awake : ON"

  # 2. X11 + Kitty stack (mk.sh already uses MQTT for start)
  bash "$MK_SCRIPT" start

  # 3. Wait for Kitty socket (needs stdout → SSH)
  echo "  display    : waiting for Kitty..."
  for i in $(seq 1 10); do
    if ssh_cmd "test -S /data/data/com.termux/files/usr/tmp/mykitty" 2>/dev/null; then
      break
    fi
    sleep 1
  done

  # 4. Get existing pane IDs (needs stdout → SSH for kitten @ ls JSON)
  echo "  display    : launching marauder display..."
  local pane_ids
  pane_ids=$(ssh_cmd "kitten @ --to $KITTY_SOCKET ls 2>/dev/null" | python3 -c "
import json,sys
data = json.load(sys.stdin)
for w in data:
  for t in w['tabs']:
    for win in t['windows']:
      print(win['id'])
" 2>/dev/null || true)

  # 5. Launch display in new window (MQTT — fire-and-forget)
  $MESH "{\"command\":\"kitten @ --to $KITTY_SOCKET launch --type=window marauder display\"}" 2>/dev/null || true
  sleep 1

  # 6. Close old panes (MQTT — fire-and-forget)
  for pid in $pane_ids; do
    $MESH "{\"command\":\"kitten @ --to $KITTY_SOCKET close-window --match id:$pid\"}" 2>/dev/null || true
  done

  echo "  display    : UP"
  echo "=== SERE Display Ready ==="
}

stop() {
  echo "=== Stopping SERE Display ==="

  # All stop commands batched into single MQTT exec
  $MESH '{"command":"pkill -f \"marauder display\" 2>/dev/null; su -c \"svc power stayon false && settings put system screen_off_timeout 60000\"; echo done"}' 2>/dev/null || true
  echo "  display    : stopped"
  echo "  keep-awake : OFF"

  # Stop X11 stack (mk.sh already uses MQTT for stop)
  bash "$MK_SCRIPT" stop

  echo "=== SERE Display Stopped ==="
}

status() {
  bash "$MK_SCRIPT" status
  echo ""
  # Status queries need stdout → SSH
  if ssh_cmd "pgrep -f 'marauder display'" >/dev/null 2>&1; then
    echo "  display    : RUNNING"
  else
    echo "  display    : NOT RUNNING"
  fi

  local stayon
  stayon=$(ssh_cmd "su -c 'settings get global stay_on_while_plugged_in'" 2>/dev/null || echo "?")
  echo "  keep-awake : $stayon"
}

case "${1:-status}" in
  start)  start  ;;
  stop)   stop   ;;
  status) status ;;
  *)
    echo "Usage: bash sere-display.sh {start|stop|status}"
    exit 1
    ;;
esac
