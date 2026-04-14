---
description: "Git Add Commit Push — stage all, commit, and push in one shot"
allowed-tools:
  - Bash
---

# Git Add Commit Push (gacp)

Stage all changes, commit with a single sentence message, and push to remote. The full fast-track.

## Arguments

Optional commit message after `/gacp`. If omitted, the script auto-generates one from the staged changes.

Examples:
- `/gacp fix typo in README`
- `/gacp` (auto-generates message)

## Execution

```bash
bash ${CLAUDE_PLUGIN_ROOT}/commands/gacp.sh "<commit message>"
```

## Rules

- Use the user's message EXACTLY as provided — do not rewrite, expand, or add Co-Authored-By
- If no message provided, run without arguments — the script auto-generates one
- Do NOT ask for confirmation — just run it
- If no upstream is set, push with `-u origin <branch>` automatically
- After success, show the one-line git log and remote info
- If nothing to commit, say so
