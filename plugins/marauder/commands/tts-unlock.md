---
allowed-tools: Bash
---

Unlock TTS and output, allowing all sessions to speak again.

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
