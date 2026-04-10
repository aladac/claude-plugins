---
name: Dotfiles Management
description: |
  Manage dotfile symlinks and sync to GitHub. Links config files from ~/Projects/dotfiles/ to ~/, commits changes, pushes to GitHub, and pulls on junkpile to keep both machines in sync.

  <example>
  Context: User wants to check dotfile status
  user: "check my dotfiles"
  </example>

  <example>
  Context: User changed a config and wants to sync
  user: "sync dotfiles"
  </example>

  <example>
  Context: User wants to add a new config to management
  user: "add my tmux config to dotfiles"
  </example>

  <example>
  Context: User wants to fix broken symlinks
  user: "fix my dotfile links"
  </example>
version: 1.0.0
---

# Dotfiles Management Skill

Manages dotfile symlinks and git sync across fuji + junkpile.

## Quick Reference

```bash
SKILL=~/Projects/personality-plugin/skills/dotfiles/dotfiles.sh

# Check status of all symlinks + git
bash $SKILL status

# Create/fix all symlinks
bash $SKILL link

# Commit changes and push to GitHub + pull on junkpile
bash $SKILL sync "updated zshrc aliases"

# Pull latest on both machines
bash $SKILL pull

# Show uncommitted changes
bash $SKILL diff

# Add a new file to dotfiles management
bash $SKILL add .tmux.conf tmux.conf

# List managed symlink map
bash $SKILL managed
```

## Commands

### Symlinks

| Command | Description |
|---------|-------------|
| `status` | Show all managed symlinks and their state |
| `link` | Create/fix all symlinks |
| `link <name>` | Create/fix one symlink (e.g. `.zshrc`) |
| `unlink <name>` | Remove a symlink (keeps dotfiles source) |
| `add <home_path> <dotfile>` | Move a file to dotfiles and create symlink |

### Git Sync

| Command | Description |
|---------|-------------|
| `sync [message]` | Commit all + push + pull on junkpile |
| `pull` | Pull latest on both machines |
| `diff` | Show uncommitted changes |
| `log` | Show recent commits |

### Info

| Command | Description |
|---------|-------------|
| `list` | List all files in dotfiles repo |
| `managed` | Show the symlink map |

## Managed Symlinks

| Home Target | Dotfiles Source |
|-------------|-----------------|
| `~/.zshrc` | `zshrc` |
| `~/.vimrc` | `vimrc` |
| `~/.vim` | `vim` |
| `~/.skhdrc` | `skhdrc` |
| `~/.dotfiles` | (repo root) |
| `~/.gitconfig` | `gitconfig` |
| `~/.gitignore` | `gitignore` |
| `~/.gemrc` | `gemrc` |
| `~/.irbrc` | `irbrc` |
| `~/.pryrc` | `pryrc` |
| `~/.config/starship.toml` | `config/starship.toml` |

To add new entries, edit the `LINKS` map in `dotfiles.sh`.

## Sync Flow

```
edit file → bash dotfiles.sh sync "message"
  ↓
  git add -A + commit + push (fuji)
  ↓
  ssh j "git pull --rebase" (junkpile)
```

## Repo

- Local: `~/Projects/dotfiles/`
- Remote: `git@github.com:aladac/dotfiles.git`
- Both machines have the repo checked out
