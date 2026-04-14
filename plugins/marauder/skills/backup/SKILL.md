---
name: Protocol 5 Backup
description: |
  Verify all Protocol 5 backup destinations in a single pass. Checks local storage, Documents, Git LFS, Google Drive (both accounts), Moto G52, 1Password, database health, and size anomalies across fuji and junkpile.

  <example>
  Context: User wants to check backup status
  user: "check the backups"
  </example>

  <example>
  Context: User asks about Protocol 5
  user: "how are the Protocol 5 backups doing"
  </example>

  <example>
  Context: Daily verification
  user: "run backup verification"
  </example>
---

# Protocol 5 — Backup Verification Skill

Single-pass verification of all backup destinations via `marauder backup`.

## Usage

```bash
marauder backup status        # Full verification of all destinations
marauder backup destinations  # List all configured destinations
marauder backup run           # Execute backup to all destinations
marauder backup run --dest X  # Backup to specific destination only
marauder backup snapshot      # Create snapshot only (JSON output)
```

### Commands

| Command | Description |
|---------|-------------|
| `status` | Full verification of all destinations (default) |
| `destinations` | List all configured destinations |
| `run` | Execute backup to all destinations |
| `run --dest X` | Backup to specific destination (local, documents, git, gdrive, moto, vault) |
| `snapshot` | Create snapshot only, print JSON with path/checksum |

### What It Checks

| # | Destination | Method |
|---|-------------|--------|
| 1 | Local (backup dir) | File count + latest dump size |
| 2 | Documents | File count |
| 3 | Git LFS | Latest commit check |
| 4 | Google Drive (gmail) | gog CLI folder listing |
| 5 | Google Drive (sazabi) | gog CLI folder listing |
| 6 | Moto G52 | SSH to Termux (port 8022) |
| 7 | 1Password | op CLI item search in DEV vault |
| 8 | Database (local) | SQLite size + memory counts + integrity |
| 9 | Database (remote) | SSH to remote machine |
| 10 | Anomaly detection | Size jump detection in recent dumps |

### Output

Each destination gets a status icon:
- `✓` — verified, data current
- `–` — skipped (unreachable or tool missing)
- `✗` — failed (no data or missing)

Final summary shows pass/skip/fail counts.

Use `--json` flag for machine-readable output.
