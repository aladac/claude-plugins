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

# Visor Snapshot Skill

Captures the MARAUDER VISOR TUI pane content via Kitty remote control (`kitten @`).

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/visor/visor.sh [command]
```

### Commands

| Command | Description |
|---------|-------------|
| `snap` | Capture visor pane text (default) |
| `status` | Check if visor HTTP bridge is running |
| `find` | Find the visor pane ID in Kitty |

### Workflow

1. Run `bash visor.sh snap` to capture the visor pane content
2. Read the output — it's the full TUI text including box-drawing characters
3. Describe what you see (panels, eye state, activity log entries, viewport content)

### Examples

```bash
# Snapshot the visor
bash ${CLAUDE_PLUGIN_ROOT}/skills/visor/visor.sh snap

# Check if visor is running
bash ${CLAUDE_PLUGIN_ROOT}/skills/visor/visor.sh status

# Find which Kitty pane has the visor
bash ${CLAUDE_PLUGIN_ROOT}/skills/visor/visor.sh find
```

## Notes

- Requires Kitty with remote control enabled (`allow_remote_control yes`)
- Finds the visor pane by matching the `just dev` title or the process name
- Falls back to checking all panes if title matching fails
- The visor HTTP bridge on :9876 is checked via `status` subcommand
