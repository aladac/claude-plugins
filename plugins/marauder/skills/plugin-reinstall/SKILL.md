---
name: Plugin Reinstall
description: |
  Reinstall the marauder plugin via local-dev. Syncs source to marketplace repo, pushes, uninstalls old, installs new. Run this after any changes to agents, skills, hooks, or commands.

  <example>
  Context: User changed an agent or skill
  user: "reinstall the plugin"
  </example>

  <example>
  Context: New agent not showing up
  user: "aura agent is missing"
  </example>

  <example>
  Context: User wants to update the plugin
  user: "update marauder plugin"
  </example>

  <example>
  Context: After adding new skills
  user: "sync and reinstall plugin"
  </example>
version: 1.1.0
---

# Plugin Reinstall Skill

Reinstall the marauder plugin from local-dev.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/plugin-reinstall/plugin-reinstall.sh"

# Full reinstall (sync marketplace + uninstall + install)
bash $SKILL

# Sync only (update marketplace repo, no reinstall)
bash $SKILL sync

# Version check
bash $SKILL status
```

## What It Does

1. Commits and pushes marauder-plugin source
2. Syncs source to ~/Projects/claude-plugins marketplace repo (as `plugins/marauder/`)
3. Commits and pushes marketplace repo
4. Uninstalls old plugin (`claude plugin uninstall marauder@local-dev`)
5. Installs new plugin from local dev path
6. Reports version

## Repos Involved

| Repo | Role | Path |
|------|------|------|
| marauder-plugin | Source | ${CLAUDE_PLUGIN_ROOT} |
| claude-plugins | Marketplace | ~/Projects/claude-plugins |
| Cache | Runtime | ~/.claude/plugins/cache/local-dev/marauder/ |

## Install Details

- Plugin name: `marauder`
- Marketplace: `local-dev`
- Scope: `project` (installed at `/Users/chi`)
- Source path: `/Users/chi/Projects/marauder-plugin`

## After Running

Restart the Claude Code session (`/cc`) or run `/reload-plugins` for changes to take effect.

## Prerequisites

- git access to both repos
- `claude` CLI available
