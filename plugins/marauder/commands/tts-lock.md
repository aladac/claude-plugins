---
allowed-tools: Bash
---

Lock TTS and output to the current Claude Code session. Other sessions' TTS and hook notifications will be silently dropped until unlocked.

```bash
marauder hud lock
```

## Rules

- Run the command and report the result
- If already locked to this session, confirm it
- If locked by another session, report who holds it
