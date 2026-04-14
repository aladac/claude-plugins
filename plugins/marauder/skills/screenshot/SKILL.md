---
name: Screenshot
description: |
  Multi-display screenshot capture for macOS. Detects all connected displays and captures each separately. Use to verify UI state, check the HUD, debug visual output, or see what's on any screen.

  <example>
  Context: User asks to check something visual
  user: "screenshot and check"
  </example>

  <example>
  Context: User wants a specific display
  user: "screenshot display 3"
  </example>

  <example>
  Context: Need to verify a UI change
  user: "take a screenshot to confirm"
  </example>
---

# Screenshot Skill

Captures macOS displays using `screencapture`. Auto-detects display count.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/screenshot/screenshot.sh [command]
```

### Commands

| Command | Description |
|---------|-------------|
| `all` | Capture all displays (default) |
| `<N>` | Capture display N only (1-indexed) |
| `list` | Show connected displays and resolutions |
| `clean` | Remove captured screenshots |

### Workflow

1. Run `bash screenshot.sh all` to capture every display
2. Read output to find file paths
3. Use the `Read` tool on each file to view them
4. Pick the relevant display and describe what you see

### Examples

```bash
# Capture all displays
bash ${CLAUDE_PLUGIN_ROOT}/skills/screenshot/screenshot.sh all

# Capture only display 3 (where Kitty usually is)
bash ${CLAUDE_PLUGIN_ROOT}/skills/screenshot/screenshot.sh 3

# Check what displays are connected
bash ${CLAUDE_PLUGIN_ROOT}/skills/screenshot/screenshot.sh list
```

## Notes

- Files written to `/tmp/psn-screenshots/` with timestamps
- Always uses `-x` flag (no shutter sound)
- After capturing, use `Read` tool to view — Claude Code is multimodal
- Run `clean` to purge old screenshots
