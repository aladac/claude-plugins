---
name: worktree-rm
description: Safely remove a git worktree and its branch. Handles stale worktrees, uncommitted changes, and branch cleanup.
allowed-tools: ["Bash", "Read"]
---

# Worktree Remove

Remove a git worktree and its associated branch cleanly.

## Arguments

Optional worktree name or path after `/worktree-rm`. If omitted, lists all worktrees for selection.

Flags:
- `--force` — remove even if uncommitted changes exist
- `--keep-branch` — remove the worktree but keep the branch

Examples:
- `/worktree-rm keen-gelgoog`
- `/worktree-rm --force`
- `/worktree-rm keen-gelgoog --keep-branch`

## Execution

```bash
bash /Users/chi/Projects/marauder-plugin/commands/worktree-rm.sh <args>
```

## Rules

- Run the script with the user's arguments
- If no arguments, run without arguments — the script lists and prompts
- Show the output to the Pilot
- Do NOT ask for confirmation — the script handles it
