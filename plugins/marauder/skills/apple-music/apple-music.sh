#!/usr/bin/env bash
# Apple Music skill - control via osascript
# Usage: bash apple-music.sh <command> [args...]
# Automatically pauses Spotify when starting playback

set -euo pipefail

pause_spotify() {
  # Silently pause Spotify if it's running
  spotify-cli player pause 2>/dev/null || true
}

tell_music() {
  osascript -e "tell application \"Music\" to $1" 2>&1
}

cmd="${1:-help}"
shift 2>/dev/null || true

case "$cmd" in
  play)
    pause_spotify
    if [ $# -gt 0 ]; then
      # Play a specific playlist by name
      playlist="$*"
      tell_music "play playlist \"$playlist\""
      sleep 1
      echo "▶ Playing playlist: $playlist"
      echo "  Track: $(tell_music 'name of current track')"
      echo "  Artist: $(tell_music 'artist of current track')"
    else
      tell_music "play"
      sleep 1
      echo "▶ Resumed playback"
      echo "  Track: $(tell_music 'name of current track')"
      echo "  Artist: $(tell_music 'artist of current track')"
    fi
    ;;

  pause)
    tell_music "pause"
    echo "⏸ Paused"
    ;;

  toggle)
    pause_spotify
    tell_music "playpause"
    sleep 1
    state=$(tell_music 'player state as string')
    track=$(tell_music 'name of current track' 2>/dev/null || echo "unknown")
    artist=$(tell_music 'artist of current track' 2>/dev/null || echo "unknown")
    echo "State: $state"
    echo "  Track: $track"
    echo "  Artist: $artist"
    ;;

  next|skip)
    tell_music "next track"
    sleep 1
    echo "⏭ Skipped"
    echo "  Track: $(tell_music 'name of current track')"
    echo "  Artist: $(tell_music 'artist of current track')"
    echo "  Album: $(tell_music 'album of current track')"
    ;;

  prev|previous)
    tell_music "previous track"
    sleep 1
    echo "⏮ Previous"
    echo "  Track: $(tell_music 'name of current track')"
    echo "  Artist: $(tell_music 'artist of current track')"
    echo "  Album: $(tell_music 'album of current track')"
    ;;

  now|status)
    state=$(tell_music 'player state as string')
    if [ "$state" = "stopped" ]; then
      echo "⏹ Stopped"
    else
      track=$(tell_music 'name of current track')
      artist=$(tell_music 'artist of current track')
      album=$(tell_music 'album of current track')
      pos=$(tell_music 'player position as integer')
      dur=$(tell_music 'duration of current track as integer')
      dur_int=${dur%.*}
      pos_min=$((pos / 60))
      pos_sec=$((pos % 60))
      dur_min=$((dur_int / 60))
      dur_sec=$((dur_int % 60))
      shuffle=$(tell_music 'shuffle enabled')
      vol=$(tell_music 'sound volume')
      symbol="▶"
      [ "$state" = "paused" ] && symbol="⏸"
      printf "%s %s - %s\n" "$symbol" "$track" "$artist"
      printf "  Album: %s\n" "$album"
      printf "  Progress: %d:%02d / %d:%02d\n" "$pos_min" "$pos_sec" "$dur_min" "$dur_sec"
      printf "  Volume: %s  Shuffle: %s\n" "$vol" "$shuffle"
    fi
    ;;

  shuffle)
    pause_spotify
    tell_music "set shuffle enabled to true"
    tell_music "play"
    sleep 1
    echo "🔀 Shuffle enabled"
    echo "  Track: $(tell_music 'name of current track')"
    echo "  Artist: $(tell_music 'artist of current track')"
    ;;

  vol|volume)
    level="${1:-}"
    if [ -z "$level" ]; then
      current=$(tell_music 'sound volume')
      echo "Volume: $current"
    else
      tell_music "set sound volume to $level"
      echo "Volume set to $level"
    fi
    ;;

  playlist)
    # Play a specific playlist
    name="$*"
    if [ -z "$name" ]; then
      # List playlists
      osascript -e 'tell application "Music" to get name of every playlist' 2>&1
    else
      pause_spotify
      tell_music "play playlist \"$name\""
      sleep 1
      echo "▶ Playing playlist: $name"
      echo "  Track: $(tell_music 'name of current track')"
      echo "  Artist: $(tell_music 'artist of current track')"
    fi
    ;;

  search)
    query="$*"
    if [ -z "$query" ]; then
      echo "Usage: apple-music.sh search <query>"
      exit 1
    fi
    pause_spotify
    osascript <<EOF
tell application "Music"
  set results to (every track whose name contains "$query" or artist contains "$query")
  if (count of results) > 0 then
    play item 1 of results
  else
    return "No results found for: $query"
  end if
end tell
EOF
    sleep 1
    echo "▶ $(tell_music 'name of current track') - $(tell_music 'artist of current track')"
    ;;

  help|*)
    cat <<EOF
Apple Music Skill Commands:
  play [playlist]  Resume or play a playlist by name
  pause            Pause playback
  toggle           Toggle play/pause
  next / skip      Next track
  prev / previous  Previous track
  now / status     Current playback status
  shuffle          Enable shuffle and play
  vol [0-100]      Get or set volume
  playlist [name]  List playlists or play one by name
  search <query>   Search library and play first match

Note: Starting playback auto-pauses Spotify.
EOF
    ;;
esac
