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

# EVE Screen Capture

Use the `eve_screen` MCP tool directly:

```
eve_screen(title: "EVE Online")
```

## Parameters

| Param | Description |
|-------|-------------|
| `output` | Output path (default: `/tmp/eve-screen.png`) |
| `title` | Set to post image on visor. Omit to skip. |
| `caption` | Caption for visor display. |

## How It Works

1. Finds the EVE game window via Swift + `CGWindowListCopyWindowInfo`
2. Captures with `screencapture -x -o -l <WID>`
3. Returns path for visual analysis via `Read` tool

## Prerequisites

- macOS, EVE Online client running with a character logged in
