---
name: junkpile-desktop-mode
description: Switch junkpile to desktop mode by starting GDM, GNOME Shell, X11, and desktop services. Restores the full graphical environment.
agent: junkpile
---

# Junkpile Desktop Mode

Starts the graphical desktop environment on junkpile, restoring the GNOME desktop with X11. Use this after server mode to bring back the GUI for interactive use, or if the desktop needs to be restarted.

## What It Does

1. Sets the systemd default target to `graphical.target` (persists across reboots)
2. Starts desktop-adjacent services: accounts-daemon, power-profiles-daemon, switcheroo-control, colord, gnome-remote-desktop, CUPS
3. Starts GDM (GNOME Display Manager), which launches X11 and the GNOME login screen
4. Waits for initialization and reports session state

## Services Started

| Service | Purpose |
|---------|---------|
| `accounts-daemon.service` | User account service (needed by GDM) |
| `power-profiles-daemon.service` | Power management profiles |
| `switcheroo-control.service` | GPU switching proxy |
| `colord.service` | Color profile management |
| `gnome-remote-desktop.service` | RDP access to desktop |
| `cups.service` | Print server |
| `cups-browsed.service` | Remote printer discovery |
| `gdm.service` | Display manager (starts X11 + GNOME login) |

## Important Notes

- After GDM starts, the user must log in at the console or via GNOME Remote Desktop
- X11 and GNOME Shell will consume ~200-400 MB of GPU VRAM once a session is active
- The script is idempotent -- safe to run if already in desktop mode
- GNOME user services (pipewire, settings daemons, tracker, etc.) start automatically when a user logs in

## Script

Run the script:

```bash
bash ~/Projects/personality-plugin/skills/junkpile-desktop-mode/junkpile-desktop-mode.sh
```

## Switching to Server Mode

To free GPU resources by stopping the desktop, use the companion skill `junkpile-server-mode`.
