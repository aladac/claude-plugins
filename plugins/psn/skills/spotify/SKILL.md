---
name: Spotify Control
description: |
  Control Spotify playback — shuffle liked songs, search and play tracks, check what's playing, skip, pause, volume. Uses spotify-cli wrapping the Spotify Web API.

  <example>
  Context: User wants to shuffle their music
  user: "shuffle my liked songs"
  </example>

  <example>
  Context: User asks what's playing
  user: "what's playing on Spotify?"
  </example>

  <example>
  Context: User wants a specific song
  user: "play Run DMC Walk This Way"
  </example>

  <example>
  Context: User wants to skip
  user: "next track"
  </example>

  <example>
  Context: User wants to pause
  user: "pause the music"
  </example>
version: 1.0.0
---

# Spotify Control Skill

Control Spotify playback via `spotify-cli` wrapper script.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/spotify/spotify.sh"

# Shuffle liked songs
bash $SKILL shuffle

# What's playing?
bash $SKILL now

# Search and play
bash $SKILL find "Run DMC Walk This Way"

# Playback controls
bash $SKILL pause
bash $SKILL resume
bash $SKILL toggle
bash $SKILL next
bash $SKILL prev

# Browse liked songs
bash $SKILL liked        # first 20
bash $SKILL liked 50     # first 50
bash $SKILL liked 20 40  # 20 tracks starting at offset 40

# Volume
bash $SKILL vol 50

# Queue and devices
bash $SKILL queue
bash $SKILL devices
```

## Commands

| Command | Description |
|---------|-------------|
| `shuffle` | Enable shuffle + play liked songs collection |
| `now` / `status` | Current track, artist, progress, device |
| `find <query>` / `play <query>` | Search and play first match |
| `pause` | Pause playback |
| `resume` | Resume playback |
| `toggle` | Toggle play/pause |
| `next` / `skip` | Skip to next track |
| `prev` / `previous` | Go to previous track |
| `liked [limit] [offset]` | List liked songs (paginated) |
| `vol <0-100>` | Set volume level |
| `devices` | List available playback devices |
| `queue` | View current playback queue |

## Prerequisites

- `spotify-cli` installed (`cargo install spotify-cli`)
- Authenticated (`spotify-cli auth login`)
- Spotify app open on at least one device (API needs an active device)
- Spotify Premium account required

## Config

- Config: `~/.config/spotify-cli/config.toml`
- User ID: `1167656834`
- Liked songs URI: `spotify:user:1167656834:collection`

## Notes

- Spotify must be open on a device for playback commands to work
- `play` is an alias for `find` — both search and play the first result
- Spotify is the default player for unqualified music requests (e.g. "play some music")
- `shuffle` enables shuffle mode then starts the liked songs collection
- All commands are thin wrappers around `spotify-cli` subcommands
