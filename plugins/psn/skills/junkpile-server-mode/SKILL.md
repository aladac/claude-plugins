---
name: junkpile-server-mode
description: Switch junkpile to server mode by stopping GDM, GNOME Shell, X11, and desktop services. Frees GPU VRAM for compute workloads like Ollama and ComfyUI.
agent: junkpile
---

# Junkpile Server Mode

Stops the graphical desktop environment on junkpile, freeing GPU memory and CPU resources for compute-heavy workloads. This is useful when you need maximum GPU VRAM for LLM inference (Ollama), image generation (ComfyUI), or other CUDA workloads.

## What It Does

1. Sets the systemd default target to `multi-user.target` (persists across reboots)
2. Stops GDM (GNOME Display Manager), which terminates X11, GNOME Shell, and all graphical sessions
3. Stops desktop-adjacent services: gnome-remote-desktop, colord, switcheroo-control, power-profiles-daemon, accounts-daemon, CUPS
4. Reports GPU memory state after shutdown

## Services Affected

| Service | Purpose | GPU Impact |
|---------|---------|------------|
| `gdm.service` | Display manager (starts X11 + GNOME) | Xorg + gnome-shell use ~200-400 MB VRAM |
| `gnome-remote-desktop.service` | RDP access | Minor |
| `colord.service` | Color profile management | None (CPU only) |
| `switcheroo-control.service` | GPU switching proxy | None |
| `power-profiles-daemon.service` | Power management | None |
| `accounts-daemon.service` | User account service | None |
| `cups.service` | Print server | None |
| `cups-browsed.service` | Remote printer discovery | None |

## Important Notes

- SSH access remains fully functional (not affected)
- All server services continue running: Caddy, PostgreSQL, Docker, Ollama, Tengu, Samba
- The user will lose their active graphical session (any unsaved work in GUI apps)
- GNOME Remote Desktop will be unavailable until desktop mode is restored
- The script is idempotent -- safe to run if already in server mode

## Script

Run the script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/junkpile-server-mode/junkpile-server-mode.sh
```

## Restoring Desktop

To bring back the GUI, use the companion skill `junkpile-desktop-mode`.
