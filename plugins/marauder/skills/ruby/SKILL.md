---
name: Ruby
description: |
  Cross-machine Ruby execution (NOT coding practices). Runs ruby on fuji (macOS) or junkpile (Linux) transparently via SSH. Execute scripts, one-liners, and version checks on either machine.

  <example>
  Context: User wants to run a Ruby script remotely
  user: "run this ruby script on junkpile"
  </example>

  <example>
  Context: User wants to check Ruby version
  user: "what ruby version is on junkpile?"
  </example>
---

# Ruby Skill

Manages Homebrew-installed Ruby across fuji and junkpile transparently.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/ruby/ruby.sh <target> <ruby-args...>
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
# Check version on both
bash ${CLAUDE_PLUGIN_ROOT}/skills/ruby/ruby.sh both --version

# Run a script on junkpile
bash ${CLAUDE_PLUGIN_ROOT}/skills/ruby/ruby.sh junkpile script.rb

# One-liner on fuji
bash ${CLAUDE_PLUGIN_ROOT}/skills/ruby/ruby.sh fuji -e "puts RUBY_PLATFORM"
```

## Machine Reference

| Host | Ruby Path | SSH Alias |
|------|-----------|-----------|
| fuji | `/opt/homebrew/opt/ruby/bin/ruby` | `f` |
| junkpile | `/home/linuxbrew/.linuxbrew/opt/ruby/bin/ruby` | `j` |
