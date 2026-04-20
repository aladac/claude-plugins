---
description: "Clean, build, and deploy marauder-os binary to all mesh nodes (fuji, junkpile, moto, tachikoma). Cleans artifacts, builds native + cross-compiles, deploys via SCP."
---

Build and deploy marauder-os to all 4 MARAUDER mesh nodes.

## Nodes

| Node | Arch | Build Method | Deploy |
|------|------|-------------|--------|
| fuji | aarch64-apple-darwin | Native `cargo build` | `cargo install` |
| junkpile | x86_64-unknown-linux-gnu | Native `cargo build` via SSH | `cargo install` via SSH |
| moto | aarch64-linux-android | Cross-compile on fuji (NDK linker) | SCP to `/data/data/com.termux/files/usr/bin/` |
| tachikoma | armv7-unknown-linux-gnueabihf | Cross-compile on fuji (`cargo zigbuild`) | SCP + `sudo mv` to `/usr/local/bin/` |

## Usage

Run the bump script — do NOT run it yourself, hand the path to the Pilot:

```bash
~/.claude/bump.sh
```

## What it does

1. `cargo clean` in marauder-os
2. Build + install on fuji (native)
3. SSH to junkpile: git pull, clean, build, install (native)
4. Cross-compile aarch64-linux-android, SCP to moto
5. Cross-compile armv7-linux-gnueabihf (zigbuild), SCP to tachikoma
6. Print version summary for all 4 nodes

## After completion

Report the version string and confirm all 4 nodes show the same version. If any node failed, flag it explicitly.
