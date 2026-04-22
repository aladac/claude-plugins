---
description: Clean, build, and deploy marauder-os to all 4 mesh nodes
allowed-tools:
  - AskUserQuestion
---

Build and deploy marauder-os to fuji, junkpile, moto, and tachikoma.

## Standing Restrictions

- NEVER deploy to production mesh nodes without presenting the version and target nodes via AskUserQuestion first and receiving explicit approval.
- NEVER deploy without verifying the build succeeded.

## Instructions

Present the current version from `Cargo.toml` and the target nodes (fuji, junkpile, moto, tachikoma) via AskUserQuestion before proceeding. Only continue after approval.

Run the bump script:

```bash
~/.claude/bump.sh
```

The script automatically:
1. Cleans all build artifacts (`cargo clean`)
2. Reads version from `Cargo.toml` + appends `+<short-git-hash>` (e.g., `0.2.1+c4be2ee`)
3. Builds and installs natively on **fuji** (macOS ARM64)
4. Pulls, cleans, builds, and installs natively on **junkpile** (x86_64 Linux via SSH)
5. Cross-compiles for **moto** (aarch64-linux-android) and deploys via SCP
6. Cross-compiles for **tachikoma** (armv7-linux-gnueabihf via zigbuild) and deploys via SCP
7. Reports installed version on all 4 nodes

After the script completes, show the user the version summary and confirm all nodes match.

**Note:** No files are modified — the git hash is display-only, not written to Cargo.toml.
