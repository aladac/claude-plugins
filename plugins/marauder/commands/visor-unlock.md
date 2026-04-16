---
allowed-tools: Bash
---

Unlock the MARAUDER VISOR, allowing all sessions to write to it again.

```bash
marauder hud unlock
```

To force-unlock when locked by another session:

```bash
marauder hud unlock --force
```

## Rules

- Run the command and report the result
- Use `--force` only if the user explicitly asks to override another session's lock
