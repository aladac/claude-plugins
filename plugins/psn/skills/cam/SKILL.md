---
name: Camera Control
description: |
  Control the Tapo C225 PTZ camera — move to presets, pan/tilt, capture snapshots, visual lookups. Wraps the psn-cam Python CLI.

  <example>
  Context: User wants to check the room
  user: "look at the room"
  </example>

  <example>
  Context: User wants a snapshot
  user: "take a picture"
  </example>

  <example>
  Context: User wants to move the camera
  user: "point the camera at my desk"
  </example>

  <example>
  Context: User wants to pan
  user: "pan the camera left"
  </example>

  <example>
  Context: User wants a full room scan
  user: "scan the room"
  </example>
version: 1.0.0
---

# Camera Control Skill

Control the Tapo C225 PTZ camera via the psn-cam Python CLI.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/cam/cam.sh"

# Preset shortcuts
bash $SKILL desk
bash $SKILL room
bash $SKILL monitors

# Any preset by name or ID
bash $SKILL goto desk

# Directional nudge
bash $SKILL left
bash $SKILL right 30
bash $SKILL up 15
bash $SKILL down

# Relative move (pan, tilt)
bash $SKILL move 50 -10

# Capture snapshot
bash $SKILL snap
bash $SKILL snap ~/Desktop/capture.jpg

# Snap for visual analysis (timestamped)
bash $SKILL look

# 3x3 grid sweep (9 frames, full FOV)
bash $SKILL sweep

# Camera info
bash $SKILL info

# Manage presets
bash $SKILL presets
bash $SKILL save "new-position"

# Reset to factory home
bash $SKILL calibrate
```

## Commands

| Command | Description |
|---------|-------------|
| `info` | Camera info (model, firmware, MAC) |
| `presets` | List all saved presets |
| `goto <name\|id>` | Move to a preset |
| `desk` / `room` / `monitors` | Preset shortcuts |
| `move <x> <y>` | Relative pan/tilt (-170..170, -35..35) |
| `left` / `right` / `up` / `down` [amount] | Directional nudge (defaults: 20 pan, 10 tilt) |
| `snap [file.jpg]` | Capture RTSP frame |
| `look` | Snap timestamped frame, return path (for reading with Read tool) |
| `sweep [dir]` | 3x3 grid sweep — 9 snapshots covering full FOV, returns to start |
| `save <name>` | Save current position as preset |
| `calibrate` / `home` | Reset to factory home |

## Presets

| Name | Description |
|------|-------------|
| desk | Pilot's desk (default view) |
| room | Wide room view |
| monitors | Monitor area |

## Camera Specs

- **Model**: Tapo C225
- **IP**: 192.168.88.137
- **RTSP**: stream1 (2688x1520 H.264, 15fps), stream2 (low-res)
- **PTZ**: Pan -170..170, Tilt -35..35 (relative only)
- **moveMotor is RELATIVE** — use presets for absolute positioning

## Visual Analysis Pattern

```bash
# Snap a frame, then read it with the Read tool
path=$(bash $SKILL look)
# Then use Read tool on the returned path to see the image
```

## Prerequisites

- psn-cam project at ~/Projects/psn-cam
- uv installed (Python package manager)
- Camera online at 192.168.88.137
- ffmpeg installed (for snapshots)
