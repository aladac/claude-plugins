# SSH → MQTT Migration — TODO

## Estimates

| Phase | Naive | Coop | Sessions | Notes |
|-------|-------|------|----------|-------|
| 1. Junkpile service control | 20 min | ~5 min | 1 | Two scripts, 2-3 ssh calls each → mesh send |
| 2. Dotfiles sync | 15 min | ~3 min | 1 | One ssh call → mesh send |
| 3. Moto-kitty hybrid | 30 min | ~10 min | 1 | Start/stop → MQTT, status checks stay SSH |
| 4. SERE display hybrid | 30 min | ~10 min | 1 | Fire-and-forget → MQTT, ls parsing stays SSH |
| **Total** | **~1h 35m** | **~28 min** | **1** | All mechanical find-replace |

## Tasks

### Phase 1: Junkpile service control
- [ ] `junkpile-server-mode.sh` — replace `ssh j "sudo systemctl stop/start"` with `marauder mesh send junkpile exec`
- [ ] `junkpile-desktop-mode.sh` — same pattern
- [ ] Test: run both scripts, verify services toggle on junkpile

### Phase 2: Dotfiles sync
- [ ] `dotfiles.sh` — replace junkpile `ssh j "cd ... && git pull"` with mesh send exec
- [ ] Test: push dotfiles, run sync, verify pull on junkpile

### Phase 3: Moto-kitty hybrid
- [ ] `mk.sh start` — replace `ssh_cmd "nohup ..."` and `ssh_cmd "am start ..."` with mesh send
- [ ] `mk.sh stop` — replace `ssh_cmd "pkill ..."` and `ssh_cmd "am force-stop ..."` with mesh send
- [ ] `mk.sh status` — keep SSH for pgrep/dumpsys (needs stdout)
- [ ] Test: start/stop/status cycle

### Phase 4: SERE display hybrid
- [ ] `sere-display.sh start` — replace keep-awake and process launch with mesh send
- [ ] `sere-display.sh stop` — replace pkill and restore-sleep with mesh send
- [ ] `sere-display.sh status` — keep SSH for pgrep/settings get
- [ ] Test: full start/stop cycle
