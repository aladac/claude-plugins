# SSH → MQTT Migration for Mesh Scripts

**Date:** 2026-04-20
**Goal:** Replace SSH remote execution with MQTT `exec` commands in 5 skill scripts. Eliminates SSH auth failures, shell escaping issues, and agent key dependencies.

## Why

- SSH agent failures (`sign_and_send_pubkey`) observed during bump deployments
- MQTT exec is already deployed on all 4 nodes with authenticated users
- No shell escaping needed (binary protocol)
- Uniform command interface — `marauder mesh send <node> exec '{"command":"..."}'`

## Scripts to Migrate

| Script | Target | SSH calls | MQTT replacement |
|--------|--------|-----------|-----------------|
| `moto-kitty/mk.sh` | moto | `ssh m "pgrep/nohup/am start/pkill"` | `marauder mesh send moto exec` |
| `android/sere-display.sh` | moto | `ssh m "su -c/pgrep/kitten @"` | `marauder mesh send moto exec` |
| `junkpile-desktop-mode` | junkpile | `ssh j "sudo systemctl start"` | `marauder mesh send junkpile exec` |
| `junkpile-server-mode` | junkpile | `ssh j "sudo systemctl stop"` | `marauder mesh send junkpile exec` |
| `dotfiles/dotfiles.sh` | junkpile | `ssh j "cd ~/Projects/dotfiles && git pull"` | `marauder mesh send junkpile exec` |

## Pattern

Replace:
```bash
ssh m "pgrep -f kitty"
```

With:
```bash
marauder mesh send moto exec '{"command":"pgrep -f kitty"}'
```

### Response handling

Current MQTT `exec` is fire-and-forget — result publishes to `marauder/{node}/log` but `mesh send` doesn't wait. For scripts that check exit codes or capture stdout (pgrep, settings get), we use a **hybrid approach**:

- **Fire-and-forget** → MQTT: nohup, pkill, am start, systemctl, git pull
- **Needs stdout** → SSH (kept): pgrep, dumpsys, settings get, kitten @ ls

Mark `marauder mesh send --wait` as a future enhancement that would eliminate the remaining SSH calls.

## Phases

### Phase 1: Junkpile service control
`junkpile-desktop-mode.sh` and `junkpile-server-mode.sh` — pure fire-and-forget systemctl calls. No stdout needed.

### Phase 2: Dotfiles sync
`dotfiles.sh` junkpile sync — git pull is fire-and-forget.

### Phase 3: Moto process management (hybrid)
`moto-kitty/mk.sh` — MQTT for start/stop (nohup, pkill, am start). Keep SSH for status (pgrep, dumpsys).

### Phase 4: SERE display orchestration (hybrid)
`sere-display.sh` — MQTT for keep-awake, process kill, kitten @ launch. Keep SSH for Kitty ls JSON parsing.

## Not Changing

- `android/moto-screenshot.sh` — binary ADB pipe, not text exec
- `bump.sh` — streaming cargo build output
- `cargo/brew/uv/gem/ruby` — streaming stdout needed
