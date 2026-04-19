#!/usr/bin/env bash
# moto-kitty — start/stop/status for the SERE Kitty X11 stack on Moto G52
# Usage: bash mk.sh {start|stop|status}

set -euo pipefail

SSH_HOST="m"
DISPLAY_NUM=":0"
TMPDIR_MOTO="/data/data/com.termux/files/usr/tmp"
KITTY_SOCKET="unix:${TMPDIR_MOTO}/mykitty"
X11_ACTIVITY="com.termux.x11/.MainActivity"

ssh_cmd() { ssh -o ConnectTimeout=5 "$SSH_HOST" "$@"; }

# Check if a process is running on the moto
is_running() {
  ssh_cmd "pgrep -f '$1'" >/dev/null 2>&1
}

status() {
  echo "=== SERE Kitty Stack Status ==="

  # Termux X11 server (process name is com.termux.x11.Loader or Xwayland)
  if is_running "termux-x11" || is_running "com.termux.x11"; then
    echo "  termux-x11 : UP"
  else
    echo "  termux-x11 : DOWN"
  fi

  # Openbox
  if is_running "openbox"; then
    echo "  openbox    : UP"
  else
    echo "  openbox    : DOWN"
  fi

  # Kitty
  if is_running "kitty"; then
    echo "  kitty      : UP"
  else
    echo "  kitty      : DOWN"
  fi

  # X11 Activity (Android side)
  local focus
  focus=$(ssh_cmd "dumpsys window | grep -o 'com.termux.x11[^ ]*'" 2>/dev/null || true)
  if [[ -n "$focus" ]]; then
    echo "  x11-activity: VISIBLE"
  else
    echo "  x11-activity: BACKGROUND"
  fi

  # Rotation lock
  local auto_rotate
  auto_rotate=$(ssh_cmd "settings get system accelerometer_rotation" 2>/dev/null || echo "?")
  if [[ "$auto_rotate" == "0" ]]; then
    echo "  rotation   : LOCKED (portrait)"
  else
    echo "  rotation   : AUTO-ROTATE"
  fi
}

start() {
  echo "=== Starting SERE Kitty Stack ==="

  # 0. Lock portrait mode, disable auto-rotate
  ssh_cmd "settings put system accelerometer_rotation 0; settings put system user_rotation 0" 2>/dev/null || true
  echo "  rotation   : locked portrait"

  # 1. Termux X11 server
  if is_running "termux-x11" || is_running "com.termux.x11"; then
    echo "  termux-x11 : already running"
  else
    echo "  termux-x11 : starting..."
    ssh_cmd "nohup termux-x11 ${DISPLAY_NUM} >/dev/null 2>&1 &"
    sleep 1
    if is_running "termux-x11"; then
      echo "  termux-x11 : UP"
    else
      echo "  termux-x11 : FAILED TO START"
      exit 1
    fi
  fi

  # 2. X11 Activity (Android side)
  echo "  x11-activity: launching..."
  ssh_cmd "am start -n ${X11_ACTIVITY}" >/dev/null 2>&1 || true
  echo "  x11-activity: LAUNCHED"

  # 3. Openbox
  if is_running "openbox"; then
    echo "  openbox    : already running"
  else
    echo "  openbox    : starting..."
    ssh_cmd "export DISPLAY=${DISPLAY_NUM}; nohup openbox >/dev/null 2>&1 &"
    sleep 0.5
    if is_running "openbox"; then
      echo "  openbox    : UP"
    else
      echo "  openbox    : FAILED TO START"
      exit 1
    fi
  fi

  # 4. Kitty
  if is_running "kitty"; then
    echo "  kitty      : already running"
  else
    echo "  kitty      : starting..."
    ssh_cmd "export DISPLAY=${DISPLAY_NUM}; nohup kitty --listen-on ${KITTY_SOCKET} -o font_size=24 >/dev/null 2>&1 &"
    sleep 1
    if is_running "kitty"; then
      echo "  kitty      : UP"
    else
      echo "  kitty      : FAILED TO START"
      exit 1
    fi
  fi

  echo "=== SERE Stack Ready ==="
}

stop() {
  echo "=== Stopping SERE Kitty Stack ==="

  # Reverse order: kitty → openbox → x11 activity → termux-x11
  if is_running "kitty"; then
    ssh_cmd "pkill -f kitty" 2>/dev/null || true
    echo "  kitty      : stopped"
  else
    echo "  kitty      : not running"
  fi

  if is_running "openbox"; then
    ssh_cmd "pkill -f openbox" 2>/dev/null || true
    echo "  openbox    : stopped"
  else
    echo "  openbox    : not running"
  fi

  # Stop X11 activity
  ssh_cmd "am force-stop com.termux.x11" 2>/dev/null || true
  echo "  x11-activity: stopped"

  if is_running "termux-x11" || is_running "com.termux.x11"; then
    ssh_cmd "pkill -f 'termux-x11|com.termux.x11'" 2>/dev/null || true
    echo "  termux-x11 : stopped"
  else
    echo "  termux-x11 : not running"
  fi

  # Restore auto-rotate
  ssh_cmd "settings put system accelerometer_rotation 1" 2>/dev/null || true
  echo "  rotation   : restored auto-rotate"

  echo "=== SERE Stack Stopped ==="
}

case "${1:-status}" in
  start)  start  ;;
  stop)   stop   ;;
  status) status ;;
  *)
    echo "Usage: bash mk.sh {start|stop|status}"
    exit 1
    ;;
esac
