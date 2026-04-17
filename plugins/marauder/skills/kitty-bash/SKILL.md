---
name: kitty-bash
description: |
  Route shell commands to the Kitty preview pane instead of running inline. Use this for all Bash output the Pilot should see live — git, builds, tests, deploys.

  <example>
  Context: Running a command for the Pilot to see
  user: "run the tests"
  </example>

  <example>
  Context: Checking output on the preview pane
  user: "what's showing on the pane?"
  </example>
---

# KittyBash — Preview Pane Shell

Route shell commands to the Kitty preview pane. The Pilot sees output live on pane; you read it back when needed.

## Setup

```bash
KB="${CLAUDE_PLUGIN_ROOT}/skills/kitty-bash/kb.sh"

# Detect available panes (idle shells, excludes focused)
bash $KB detect
```

### Pane Selection Logic

1. Run `bash $KB detect` to find idle shell panes
2. If **one** candidate → auto-set with `bash $KB set <id>`
3. If **multiple** candidates → use `AskUserQuestion` to let the Pilot choose, then `bash $KB set <id>`
4. If **zero** candidates → tell the Pilot no idle panes found

The stored pane is validated on each `run` — if stale, re-detect automatically.

## Commands

```bash
# Detect idle panes
bash $KB detect

# Set the preview pane
bash $KB set 3

# Run a command on the preview pane and read output
bash $KB run "git status"

# Read current pane content (default 15 lines, or specify)
bash $KB read
bash $KB read 30

# Send raw text without Enter
bash $KB send "some text"

# Clear the pane
bash $KB clear

# Check which pane is set
bash $KB get
```

## Environment

| Var | Default | What |
|-----|---------|------|
| `KB_WAIT` | 2 | Seconds to wait after `run` before reading |
| `KB_LINES` | 15 | Lines to tail on `run` output |

For slow commands (builds, SSH): `KB_WAIT=10 bash $KB run "cargo build --release"`

## When to Use

**Use KittyBash instead of inline Bash for:**
- Git operations (status, diff, log, commit, push)
- Build output (cargo, npm, bundle)
- Test runs
- Deploy commands
- Any output the Pilot wants to see live

**Keep using inline Bash for:**
- File content checks (grep, cat) where you need the result internally
- Silent operations (mkdir, cp, mv)
- JSON parsing / data extraction for your own logic

## Pane ID Storage

Stored at `~/.config/marauder/kitty-pane`. Persists across sessions. Validated on use — if the pane is gone, `run` will error with a message to re-detect.
