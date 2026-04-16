---
name: Cargo
description: |
  Cross-machine Cargo operations (NOT coding practices). Runs cargo on fuji (macOS) or junkpile (Linux) transparently via SSH. Build, test, install crates on either machine.

  <example>
  Context: User wants to install a Rust tool
  user: "cargo install ripgrep on junkpile"
  </example>

  <example>
  Context: User wants to build on both machines
  user: "cargo build on both"
  </example>
---

# Cargo Skill

Manages Cargo (Rust toolchain) across fuji and junkpile transparently.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/cargo/cargo.sh <target> <cargo-args...>
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
# Build locally
bash ${CLAUDE_PLUGIN_ROOT}/skills/cargo/cargo.sh local build --release

# Install a tool on both machines
bash ${CLAUDE_PLUGIN_ROOT}/skills/cargo/cargo.sh both install ripgrep

# Check versions on both
bash ${CLAUDE_PLUGIN_ROOT}/skills/cargo/cargo.sh both --version

# Run tests on junkpile
bash ${CLAUDE_PLUGIN_ROOT}/skills/cargo/cargo.sh junkpile test

# Install from crates.io on fuji
bash ${CLAUDE_PLUGIN_ROOT}/skills/cargo/cargo.sh fuji install cargo-watch
```

## Machine Reference

| Host | Cargo Path | SSH Alias |
|------|------------|-----------|
| fuji | `/Users/chi/.cargo/bin/cargo` | `f` |
| junkpile | `/home/chi/.cargo/bin/cargo` | `j` |
