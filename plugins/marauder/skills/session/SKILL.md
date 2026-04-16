---
name: Session Management
description: |
  This skill should be used when saving or restoring conversation sessions, managing session state, or resuming previous work. Triggers on questions about saving progress, restoring context, or continuing where left off.

  <example>
  Context: User is stepping away
  user: "Save this session, I'll continue later"
  </example>

  <example>
  Context: User returns to previous work
  user: "Restore my morning session"
  </example>
version: 2.0.0
---

# Session Management

Use the `session_save` and `session_restore` MCP tools directly.

## Save

```
session_save(label: "visor-debug", summary: "Fixing TTS visor sync issue")
```

Captures: cwd, git branch, uncommitted changes, recent commits, session ID.

| Param | Description |
|-------|-------------|
| `label` | Session name for later recall (e.g. `tengu-refactor`) |
| `summary` | Brief description of current work |

## Restore

```
session_restore(label: "visor-debug")
```

Finds the session by exact subject match (`session.{label}`), falls back to semantic search.

| Param | Description |
|-------|-------------|
| `label` | Session label to restore |

## How It Works

Sessions are stored as memories with subject `session.{label}`. The save tool automatically captures git state and working directory context. Restore retrieves and presents the full context for resuming work.

## Related Commands

| Command | Purpose |
|---------|---------|
| `/session-save` | Save current session |
| `/session-restore` | Restore a session |
