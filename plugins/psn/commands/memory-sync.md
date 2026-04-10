---
description: Sync PSN memories across all databases (SQLite + PostgreSQL on fuji and junkpile)
---

Synchronize PSN memory stores. Source of truth is fuji SQLite.

## Instructions

Run the requested sync operation:

```bash
# Check sync status
bash ~/Projects/personality-plugin/skills/memory-sync/memory-sync.sh status

# Full sync (SQLite → fuji PG → junkpile PG)
bash ~/Projects/personality-plugin/skills/memory-sync/memory-sync.sh sync

# Tag core memories across all stores
bash ~/Projects/personality-plugin/skills/memory-sync/memory-sync.sh tag-core
```

If $ARGUMENTS is empty, run `status` first, then `sync` if out of sync.
If $ARGUMENTS contains "status", run status only.
If $ARGUMENTS contains "core" or "tag", run tag-core.
