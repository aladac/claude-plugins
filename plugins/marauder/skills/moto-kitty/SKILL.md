---
name: moto-kitty
description: |
  Start, stop, and check status of the SERE Kitty X11 stack on the Moto G52. Manages the full launch sequence: Termux X11 server, Android X11 activity, Openbox WM, and Kitty terminal.

  <example>
  Context: User wants to start Kitty on the Moto
  user: "start kitty on the moto"
  </example>

  <example>
  Context: User wants to stop the SERE display
  user: "stop the moto display"
  </example>

  <example>
  Context: User wants to check if Kitty is running
  user: "is kitty running on the moto?"
  </example>
---

# Moto Kitty — SERE X11 Stack Manager

Manages the full Kitty display stack on the Moto G52 via SSH (alias `m`).

## Commands

```bash
MK="${CLAUDE_PLUGIN_ROOT}/skills/moto-kitty/mk.sh"

# Check what's running
bash $MK status

# Start the full stack (idempotent — skips already-running components)
bash $MK start

# Stop everything (reverse order teardown)
bash $MK stop
```

## Stack Components (launch order)

| # | Component | What |
|---|-----------|------|
| 1 | termux-x11 | X11 server on :0 |
| 2 | x11-activity | Android activity (com.termux.x11/.MainActivity) |
| 3 | openbox | Window manager (fullscreen, no decorations) |
| 4 | kitty | Terminal with remote control socket |

## Remote Control

After start, Kitty is controllable via its socket. **All remote commands must use `--to` with the full socket path.**

```bash
SOCK="unix:/data/data/com.termux/files/usr/tmp/mykitty"

# Send a command (include \r for Enter)
ssh m "kitten @ --to $SOCK send-text --match id:1 'echo hello\r'"

# Send keystrokes
ssh m "kitten @ --to $SOCK send-key --match id:1 ctrl+l"    # clear screen
ssh m "kitten @ --to $SOCK send-key --match id:1 ctrl+c"    # interrupt

# Read pane content
ssh m "kitten @ --to $SOCK get-text --match id:1 --extent screen"

# List windows/panes
ssh m "kitten @ --to $SOCK ls"

# Create a split pane
ssh m "kitten @ --to $SOCK launch --location hsplit"

# Bring X11 activity to foreground (if behind launcher)
ssh m 'su -c "am start -n com.termux.x11/.MainActivity"'
```

### ANSI Status Banners

Use `send-text` with ANSI escapes for visual feedback on the Moto display:

```bash
# Red recording banner
ssh m "kitten @ --to $SOCK send-text --match id:1 \"\$(echo -e '\033[1;41;97m ● RECORDING \033[0m\n')\""

# Green done banner
ssh m "kitten @ --to $SOCK send-text --match id:1 \"\$(echo -e '\033[1;42;97m ✓ DONE \033[0m\n')\""

# Blue processing banner
ssh m "kitten @ --to $SOCK send-text --match id:1 \"\$(echo -e '\033[1;44;97m ■ PROCESSING \033[0m\n')\""
```

### Important

- The local `kitty @` skill (without `--to`) only works on fuji — it uses the local socket
- For the Moto, always SSH + `kitten @ --to $SOCK`
- Use `send-key` for control sequences (Ctrl+L, Ctrl+C), `send-text` for typed input
- `send-text` with `\r` simulates Enter

## Notes

- Start is idempotent — safe to run if parts are already up
- Stop tears down in reverse order
- SSH alias `m` must be configured (see ~/.ssh/config)
- Requires: termux-x11, openbox, kitty, libxcursor on the Moto
