---
name: EVE Client Detection
description: |
  Detect and manage the EVE Online client process on macOS. Find running clients, get window info, check if logged in, and manage client state.

  <example>
  Context: User wants to know if EVE is running
  user: "is EVE running"
  </example>

  <example>
  Context: User wants client details
  user: "EVE client info"
  </example>

  <example>
  Context: User wants to focus EVE window
  user: "bring EVE to front"
  </example>
version: 1.0.0
---

# EVE Client Detection Skill

Detect and interact with the EVE Online client on macOS.

## Quick Reference

```bash
SKILL="~/Projects/personality-plugin/skills/eve-client/eve-client.rb"

# Check if EVE is running
ruby $SKILL status

# Detailed process info
ruby $SKILL info

# List all EVE windows
ruby $SKILL windows

# Bring EVE to foreground
ruby $SKILL focus

# Get the window ID (for screenshots)
ruby $SKILL window-id
```

## Commands

| Command | Description |
|---------|-------------|
| `status` | Quick check — running or not, PID, uptime |
| `info` | Detailed process info (CPU, memory, threads) |
| `windows` | List all EVE windows with IDs and titles |
| `focus` | Bring EVE window to foreground |
| `window-id` | Output just the window ID (for piping to screencapture) |

## Prerequisites

- macOS (uses AppKit/CoreGraphics via osascript and system_profiler)
- EVE Online client installed
