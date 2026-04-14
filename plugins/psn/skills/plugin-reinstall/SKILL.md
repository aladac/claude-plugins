---
name: Plugin Reinstall
description: |
  Reinstall the PSN plugin via the marketplace. Syncs source to marketplace repo, pushes, uninstalls old, installs new. Run this after any changes to agents, skills, hooks, or commands.

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
  user: "update psn plugin"
  </example>

  <example>
  Context: After adding new skills
  user: "sync and reinstall plugin"
  </example>
version: 1.0.0
---

# Plugin Reinstall Skill

Full reinstall of the PSN plugin via the aladac marketplace.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/plugin-reinstall/plugin-reinstall.sh"

# Full reinstall (bump + sync + uninstall + install)
bash $SKILL

# Sync only (no reinstall — just update marketplace repo)
bash $SKILL sync

# Version check (compare source vs cache vs gem)
bash $SKILL status
```

## What It Does

1. Bumps plugin version to match gem base version + current git hash
2. Commits and pushes marauder-plugin
3. Syncs source to ~/Projects/claude-plugins (marketplace repo)
4. Commits and pushes marketplace repo
5. Uninstalls old plugin (`claude plugin uninstall psn@aladac --keep-data`)
6. Installs new plugin (`claude plugin install psn@aladac`)
7. Reports versions

## Three Repos Involved

| Repo | Role | Path |
|------|------|------|
| marauder-plugin | Source | ${CLAUDE_PLUGIN_ROOT} |
| claude-plugins | Marketplace | ~/Projects/claude-plugins |
| Cache | Runtime | ~/.claude/plugins/marketplaces/aladac/plugins/psn/ |

## After Running

Restart the Claude Code session (`/cc`) or run `/reload-plugins` for changes to take effect.

## Prerequisites

- git access to both repos
- `claude` CLI available
- `just` installed (for version bump)
