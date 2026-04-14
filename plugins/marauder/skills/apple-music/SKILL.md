---
name: Apple Music Control
description: |
  Control Apple Music playback via osascript — play, pause, shuffle, search library, playlists, volume. Automatically pauses Spotify when starting Apple Music playback.

  <example>
  Context: User wants to play Apple Music
  user: "play something on Apple Music"
  </example>

  <example>
  Context: User wants a specific playlist
  user: "play my rock playlist on Apple Music"
  </example>

  <example>
  Context: User wants to search their library
  user: "find Metallica in Apple Music"
  </example>

  <example>
  Context: User asks what's playing
  user: "what's playing on Apple Music?"
  </example>
version: 1.0.0
---

# Apple Music Control Skill

Control Apple Music via `osascript` (AppleScript). Zero dependencies — built into macOS.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/apple-music/apple-music.sh"

# Play / resume
bash $SKILL play

# Play a specific playlist
bash $SKILL play "My Playlist"

# Pause
bash $SKILL pause

# Toggle play/pause
bash $SKILL toggle

# Next / previous
bash $SKILL next
bash $SKILL prev

# Current track info
bash $SKILL now

# Shuffle
bash $SKILL shuffle

# Search library and play
bash $SKILL search "Metallica"

# Volume
bash $SKILL vol 50

# List or play playlists
bash $SKILL playlist
bash $SKILL playlist "Rock"
```

## Commands

| Command | Description |
|---------|-------------|
| `play [playlist]` | Resume or play a playlist by name |
| `pause` | Pause playback |
| `toggle` | Toggle play/pause |
| `next` / `skip` | Next track |
| `prev` / `previous` | Previous track |
| `now` / `status` | Current track, artist, album, progress, volume, shuffle |
| `shuffle` | Enable shuffle and start playback |
| `vol [0-100]` | Get or set volume |
| `playlist [name]` | List all playlists, or play one by name |
| `search <query>` | Search library by name/artist, play first match |

## Cross-Player Behavior

- **Starting Apple Music automatically pauses Spotify** (play, toggle, shuffle, search, playlist)
- The Spotify skill similarly pauses Apple Music when triggered
- This prevents both players fighting over audio output

## Prerequisites

- macOS with Music.app (built-in)
- No additional installs needed — uses `osascript`
