---
name: Visor Snapshot
description: |
  Capture the MARAUDER VISOR TUI state via Kitty remote control. Returns the full text content of the visor pane including identity panel, SERE eye, activity log, and viewport. Use to verify visor state, check what's displayed, or debug rendering.

  <example>
  Context: Need to see current visor state
  user: "check the visor"
  </example>

  <example>
  Context: Verify a visor change after code edit
  user: "did the viewport update?"
  </example>

  <example>
  Context: Debug visor rendering
  user: "what does the visor look like right now?"
  </example>
---

# Visor Snapshot

Use the `visor_snap` MCP tool directly:

```
visor_snap()
```

Returns the full TUI text content including identity panel, SERE eye, activity log, and viewport.

## Also available

- `visor_code(code, language, title)` — display syntax-highlighted code
- `visor_image(source, title, caption)` — display an image
- `visor_markdown(content, title)` — display rendered markdown

## HTTP Bridge

The visor REST API is also available at `http://127.0.0.1:9876/status` for direct queries.

## Notes

- Requires Kitty with remote control enabled
- Finds the visor pane by matching process name or title
