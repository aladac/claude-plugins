---
name: Screenshot
description: |
  Capture macOS screenshots of any display. Useful for verifying HUD state, debugging UI, or documenting visual output.

  <example>
  Context: User wants to see the HUD
  user: "screenshot the hud"
  </example>

  <example>
  Context: User wants to capture a specific display
  user: "take a screenshot of display 2"
  </example>

  <example>
  Context: User wants to see all screens
  user: "screenshot all displays"
  </example>
---

## Screenshot Capture

Use `screencapture` to capture macOS displays. The PSN HUD runs on **display 2**.

### Commands

```bash
# Capture a specific display (1-indexed)
screencapture -x -D<number> /tmp/screenshot.png

# Capture all displays into separate files
screencapture -x /tmp/screen-all.png

# Capture main display only
screencapture -x -D1 /tmp/screen-main.png
```

### Display Map

| Display | Resolution | Content |
|---------|-----------|---------|
| 1 | 5120x2880 (5K) | Main display |
| 2 | 3024x1964 (Retina) | PSN HUD (fullscreen Tauri) |
| 3 | 5120x2880 (5K) | Secondary monitor |

### Workflow

1. Run `screencapture -x -D<N> /tmp/screenshot.png`
2. Read the file with the Read tool to view it
3. Describe what you see to the Pilot

### Flags

- `-x` — no screenshot sound
- `-D<N>` — target display number
- `-R<x,y,w,h>` — capture a region
- `-l<windowID>` — capture specific window

### Notes

- Always use `-x` to suppress the shutter sound
- After capturing, use `Read` tool to view the image — Claude Code is multimodal
- For HUD verification, always capture display 2
- Screenshots are temporary — write to `/tmp/`
