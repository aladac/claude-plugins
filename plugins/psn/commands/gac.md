---
description: "Git Add Commit — stage all changes and commit with a one-line message"
allowed-tools:
  - Bash
---

# Git Add Commit (gac)

Stage all changes and commit with a single sentence message. Fast-track for when the diff is obvious and you don't need a detailed breakdown.

## Arguments

The user provides a commit message after `/gac`. Examples:
- `/gac fix typo in README`
- `/gac add gac command to plugin`
- `/gac update destroy to clean up Docker containers`

## Execution

```bash
bash ${CLAUDE_PLUGIN_ROOT}/commands/gac.sh "<commit message>"
```

## Rules

- Use the user's message EXACTLY as provided — do not rewrite, expand, or add Co-Authored-By
- If the user provides no message, ask for one
- Do NOT ask for confirmation — just run it
- After success, show the one-line git log result
- If nothing to commit, say so
