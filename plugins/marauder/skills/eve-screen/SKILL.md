---
name: EVE Screen Capture
description: |
  Capture the EVE Online client window for visual analysis. Takes screenshots of the game window by ID using macOS screencapture, returns path for reading with the Read tool.

  <example>
  Context: User wants to see EVE screen
  user: "what's on my EVE screen"
  </example>

  <example>
  Context: User wants a screenshot
  user: "screenshot EVE"
  </example>

  <example>
  Context: User asks what they're doing in game
  user: "where am I in EVE"
  </example>
version: 1.0.0
---

# EVE Screen Capture Skill

Capture the EVE Online game window for visual analysis.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/eve-screen/eve-screen.rb"

# Capture game window (timestamped, returns path)
ruby $SKILL capture

# Capture to specific file
ruby $SKILL capture /tmp/eve.png

# Capture and return path only (for piping)
ruby $SKILL snap
```

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `capture` | `[path]` | Capture game window, print path for Read tool |
| `snap` | `[path]` | Same as capture (alias) |

## Visual Analysis Pattern

```bash
# Step 1: Capture
path=$(ruby $SKILL snap)

# Step 2: Read the image with Claude's vision
# Use the Read tool on the returned path
```

## How It Works

1. Uses Swift + `CGWindowListCopyWindowInfo` to find the EVE game window (title starts with "EVE - ")
2. Gets the window ID (WID)
3. Runs `screencapture -x -o -l <WID> <path>` to capture just that window
4. Returns the file path for visual analysis via the Read tool

## Prerequisites

- macOS (uses screencapture + CoreGraphics)
- EVE Online client running with a character logged in
