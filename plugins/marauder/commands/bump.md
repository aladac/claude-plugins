---
description: Build marauder-os, install on both machines, report version with git hash
---

Build and install marauder-os (Rust binary) on fuji and junkpile.

## Instructions

Run the bump script:

```bash
~/.claude/bump.sh
```

The script automatically:
1. Reads version from `Cargo.toml` + appends `+<short-git-hash>` (e.g., `0.2.1+c4be2ee`)
2. Builds release binary (`cargo build --release`)
3. Installs locally (`cargo install --path .`)
4. Pulls and builds on the other machine via SSH (j↔f)
5. Reports installed version on both machines

After the script completes, show the user the version and confirm both machines match.

**Note:** No files are modified — the git hash is display-only, not written to Cargo.toml.
