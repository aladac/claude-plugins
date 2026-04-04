#!/usr/bin/env bash
# Spotify skill - common operations via spotify-cli
# Usage: bash spotify.sh <command> [args...]

set -euo pipefail

CLI="spotify-cli"
USER_COLLECTION="spotify:user:1167656834:collection"

pause_apple_music() {
  # Silently pause Apple Music if it's running
  osascript -e 'tell application "Music" to pause' 2>/dev/null || true
}

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
  shuffle)
    # Shuffle liked songs
    pause_apple_music
    $CLI player shuffle on 2>/dev/null
    $CLI player play --uri "$USER_COLLECTION" 2>/dev/null
    sleep 1
    $CLI player status 2>&1
    ;;

  now|status)
    # Current playback status
    $CLI player status 2>&1
    ;;

  find|play)
    # Search and play first match
    pause_apple_music
    query="$*"
    if [ -z "$query" ]; then
      echo "Usage: spotify.sh find <query>"
      exit 1
    fi
    $CLI search "$query" --type track --limit 1 --play 2>&1
    sleep 1
    $CLI player status 2>&1
    ;;

  pause)
    $CLI player pause 2>&1
    ;;

  resume)
    pause_apple_music
    $CLI player play 2>&1
    ;;

  toggle)
    pause_apple_music
    $CLI player toggle 2>&1
    ;;

  next|skip)
    $CLI player next 2>&1
    sleep 1
    $CLI player status 2>&1
    ;;

  prev|previous)
    $CLI player previous 2>&1
    sleep 1
    $CLI player status 2>&1
    ;;

  liked)
    # List liked songs
    limit="${1:-20}"
    offset="${2:-0}"
    $CLI library list --limit "$limit" --offset "$offset" 2>&1
    ;;

  vol|volume)
    level="${1:-}"
    if [ -z "$level" ]; then
      echo "Usage: spotify.sh vol <0-100>"
      exit 1
    fi
    $CLI player volume "$level" 2>&1
    ;;

  devices)
    $CLI player devices list 2>&1
    ;;

  queue)
    $CLI player queue list 2>&1
    ;;

  help|*)
    cat <<EOF
Spotify Skill Commands:
  shuffle          Shuffle liked songs
  now / status     Current playback status
  find <query>     Search and play first match
  pause            Pause playback
  resume           Resume playback
  toggle           Toggle play/pause
  next / skip      Next track
  prev / previous  Previous track
  liked [n] [off]  List liked songs (default: 20)
  vol <0-100>      Set volume
  devices          List playback devices
  queue            View playback queue
EOF
    ;;
esac
