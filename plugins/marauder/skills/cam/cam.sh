#!/usr/bin/env bash
# Camera skill - Tapo C225 PTZ control via psn-cam
# Usage: bash cam.sh <command> [args...]

set -euo pipefail

PSN_CAM="$HOME/Projects/psn-cam"
RUN="uv run --project $PSN_CAM python $PSN_CAM/main.py"

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
  info)
    $RUN info 2>&1
    ;;

  presets)
    $RUN presets 2>&1
    ;;

  goto)
    preset="${1:-}"
    if [ -z "$preset" ]; then
      echo "Usage: cam.sh goto <name|id>"
      echo "Presets: desk, room, monitors"
      exit 1
    fi
    $RUN goto "$preset" 2>&1
    ;;

  desk)
    $RUN goto desk 2>&1
    ;;

  room)
    $RUN goto room 2>&1
    ;;

  monitors)
    $RUN goto monitors 2>&1
    ;;

  move)
    x="${1:-0}"
    y="${2:-0}"
    $RUN move "$x" "$y" 2>&1
    ;;

  left)
    amount="${1:-20}"
    $RUN move "-$amount" 0 2>&1
    ;;

  right)
    amount="${1:-20}"
    $RUN move "$amount" 0 2>&1
    ;;

  up)
    amount="${1:-10}"
    $RUN move 0 "$amount" 2>&1
    ;;

  down)
    amount="${1:-10}"
    $RUN move 0 "-$amount" 2>&1
    ;;

  snap|snapshot)
    output="${1:-$PSN_CAM/snapshots/snapshot.jpg}"
    $RUN snap "$output" 2>&1
    echo "File: $output"
    ;;

  save)
    name="${1:-}"
    if [ -z "$name" ]; then
      echo "Usage: cam.sh save <preset-name>"
      exit 1
    fi
    $RUN save "$name" 2>&1
    ;;

  calibrate|home)
    $RUN calibrate 2>&1
    ;;

  look)
    # Snap a frame and return the path for visual analysis
    output="$PSN_CAM/snapshots/look_$(date +%s).jpg"
    $RUN snap "$output" 2>&1
    echo "$output"
    ;;

  sweep)
    # Quick 3x3 grid sweep — 9 snapshots covering full FOV
    out_dir="${1:-$PSN_CAM/snapshots/sweep}"
    $RUN sweep "$out_dir" 2>&1
    ;;

  help|*)
    cat <<EOF
Camera Skill Commands (Tapo C225):
  info              Camera info (model, firmware, MAC)
  presets           List all saved presets
  goto <name|id>    Move to a preset
  desk              Shortcut: goto desk
  room              Shortcut: goto room
  monitors          Shortcut: goto monitors
  move <x> <y>      Relative pan/tilt (-170..170, -35..35)
  left [amount]     Pan left (default: 20)
  right [amount]    Pan right (default: 20)
  up [amount]       Tilt up (default: 10)
  down [amount]     Tilt down (default: 10)
  snap [file.jpg]   Capture RTSP frame
  look              Snap + return path (for visual analysis)
  sweep [dir]       3x3 grid sweep (9 snapshots, full FOV)
  save <name>       Save current position as preset
  calibrate / home  Reset to factory home position
EOF
    ;;
esac
