---
name: UV
description: |
  Cross-machine uv (Python) package management (NOT coding practices). Runs uv on fuji (macOS) or junkpile (Linux) transparently via SSH. Manage environments, pip installs, and tools.

  <example>
  Context: User wants to install a Python package
  user: "uv pip install numpy on junkpile"
  </example>

  <example>
  Context: User wants to run a Python tool
  user: "run whisper on junkpile with uv"
  </example>
---

# UV Skill

Manages uv (Astral Python toolchain) across fuji and junkpile transparently.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/uv/uv.sh <target> <uv-args...>
```

### Target

| Target | Description |
|--------|-------------|
| `local` | Auto-detect current host |
| `fuji` | Run on Mac, SSH if needed |
| `junkpile` | Run on PC, SSH if needed |
| `both` | Run on both machines |

### Examples

```bash
# Install a tool locally
bash ${CLAUDE_PLUGIN_ROOT}/skills/uv/uv.sh local tool install ruff

# Pip install on junkpile
bash ${CLAUDE_PLUGIN_ROOT}/skills/uv/uv.sh junkpile pip install torch

# Check versions on both
bash ${CLAUDE_PLUGIN_ROOT}/skills/uv/uv.sh both --version

# Create venv on fuji
bash ${CLAUDE_PLUGIN_ROOT}/skills/uv/uv.sh fuji venv .venv
```

## Machine Reference

| Host | UV Path | SSH Alias |
|------|---------|-----------|
| fuji | `/opt/homebrew/bin/uv` | `f` |
| junkpile | `/home/chi/.local/bin/uv` | `j` |
