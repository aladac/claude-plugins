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

# Screenshot

Use the `screenshot` MCP tool directly:

```
screenshot(display: 1, title: "Display 1")
```

## Parameters

| Param | Description |
|-------|-------------|
| `display` | Display number (1-indexed). Omit for main display. |
| `output` | Output path (default: `/tmp/screenshot.png`) |
| `title` | Set to post image on visor. Omit to skip. |
| `caption` | Caption for visor display. |

## Notes

- Uses macOS `screencapture -x` (no shutter sound)
- After capture, use `Read` tool to view — Claude Code is multimodal
- Set `title` to automatically display on the visor
