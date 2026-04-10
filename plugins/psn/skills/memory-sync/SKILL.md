---
name: Memory Sync
description: |
  Synchronize PSN memory databases across all storage locations — fuji SQLite, fuji PostgreSQL, and junkpile PostgreSQL. Ensures all stores have identical data.

  <example>
  Context: User wants to sync memory databases
  user: "sync memories"
  </example>

  <example>
  Context: User wants to check sync status
  user: "are memories in sync?"
  </example>

  <example>
  Context: User wants to restore from backup
  user: "restore memories from sqlite"
  </example>
version: 1.0.0
---

# Memory Sync Skill

Synchronize PSN memory across fuji SQLite, fuji PostgreSQL, and junkpile PostgreSQL.

## Quick Reference

```bash
SKILL="~/Projects/personality-plugin/skills/memory-sync/memory-sync.sh"

# Check sync status (counts + max IDs across all stores)
bash $SKILL status

# Full sync: SQLite → fuji PG → junkpile PG
bash $SKILL sync

# Sync only fuji PG from SQLite
bash $SKILL sync-local

# Sync only junkpile PG from fuji PG
bash $SKILL sync-remote

# Tag core memories in all stores
bash $SKILL tag-core
```

## Storage Locations

| Store | Path/URL | Role |
|-------|----------|------|
| Fuji SQLite | `~/.local/share/personality/main.db` | Source of truth (MCP reads/writes here) |
| Fuji PG | `postgresql://psn:psn@localhost:5432/personality` | Local PostgreSQL mirror |
| Junkpile PG | `postgresql://psn:...@10.0.0.2:5432/personality` | Remote PostgreSQL mirror |

## Prerequisites

- SQLite3 CLI
- psql (PostgreSQL 17 via Homebrew)
- SSH access to junkpile (`ssh j`)
- 1Password CLI for junkpile PG password
