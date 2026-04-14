---
name: Homebrew
description: |
  Cross-machine Homebrew management. Runs brew on fuji (macOS) or junkpile (Linux) transparently, routing via SSH when needed. Use for installing, updating, searching, or managing packages on either machine.

  <example>
  Context: User wants to install a package
  user: "install ripgrep with brew on junkpile"
  </example>

  <example>
  Context: User wants to install on both machines
  user: "install htop on both machines"
  </example>
---

# Brew Skill

Manages Homebrew across fuji (macOS) and junkpile (Linux) transparently.

## Usage

Run the helper script with a target machine and brew arguments:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh <target> <brew-args...>
```

### Target

| Target | Machine | Description |
|--------|---------|-------------|
| `local` | auto-detected | Run on current host |
| `fuji` | fuji (macOS) | Run on Mac, SSH if needed |
| `junkpile` | junkpile (Linux) | Run on PC, SSH if needed |
| `both` | fuji + junkpile | Run on both machines |

### Examples

```bash
# Install on current machine
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh local install ripgrep

# Install on fuji specifically
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh fuji install node

# Install on junkpile specifically
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh junkpile install cloudflared

# List installed on both machines
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh both list

# Search everywhere
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh local search qemu

# Update and upgrade on junkpile
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh junkpile update
bash ${CLAUDE_PLUGIN_ROOT}/skills/brew/brew.sh junkpile upgrade
```

## Machine Reference

| Host | OS | Brew Path | SSH Alias |
|------|----|-----------|-----------|
| fuji | macOS (Darwin) | `/opt/homebrew/bin/brew` | `f` or `fuji` |
| junkpile | Linux | `/home/linuxbrew/.linuxbrew/bin/brew` | `j` or `junkpile` |

## Notes

- The script auto-detects whether SSH is needed based on hostname
- When targeting `both`, output is prefixed with `[fuji]` / `[junkpile]` labels
- SSH aliases `f` (fuji) and `j` (junkpile) are used for routing
- All brew subcommands are passed through unchanged
