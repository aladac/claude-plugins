---
name: RubyGems
description: |
  Cross-machine RubyGems operations (Homebrew-installed). Runs gem on fuji (macOS) or junkpile (Linux) transparently, routing via SSH when needed. Supports gem install/update/list and running gem-installed executables via exec subcommand.

  <example>
  Context: User wants to install a gem
  user: "install the personality gem on both machines"
  </example>

  <example>
  Context: User wants to run a gem executable
  user: "run psn-mcp on junkpile"
  </example>
---

# Gem Skill

Manages RubyGems across fuji and junkpile transparently. Includes an `exec` subcommand for running gem-installed executables.

## Usage

```bash
# Standard gem commands
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh <target> <gem-args...>

# Run a gem-installed executable
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh <target> exec <executable> [args...]
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
# Install a gem on both machines
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh both install puma

# List installed gems on junkpile
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh junkpile list

# Run a gem executable (e.g. psn-mcp) on junkpile
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh junkpile exec psn-mcp --help

# Run puma on fuji
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh fuji exec puma -p 3000

# Update a gem on both
bash ${CLAUDE_PLUGIN_ROOT}/skills/gem/gem.sh both update psn
```

## Machine Reference

| Host | Gem Path | Gem Bin Dir | SSH Alias |
|------|----------|-------------|-----------|
| fuji | `/opt/homebrew/opt/ruby/bin/gem` | `/opt/homebrew/lib/ruby/gems/4.0.0/bin` | `f` |
| junkpile | `/home/linuxbrew/.linuxbrew/opt/ruby/bin/gem` | `/home/linuxbrew/.linuxbrew/lib/ruby/gems/4.0.0/bin` | `j` |

## Gem Executables

Installed gem executables (psn, psn-mcp, puma, etc.) live in the gem bin directory. Use `exec` to run them:

```bash
gem.sh <target> exec <name> [args...]
```

This resolves to the correct gem bin path on the target machine automatically.
