#!/usr/bin/env bash
# Dotfiles skill — symlink management + git sync
# Usage: bash dotfiles.sh <command> [args...]

set -euo pipefail

DOTFILES="$HOME/Projects/dotfiles"

# Symlink map: "target_in_home:source_in_dotfiles"
# .dotfiles links to repo root (empty source = repo root)
LINKS=(
  ".zshrc:zshrc"
  ".vimrc:vimrc"
  ".vim:vim"
  ".skhdrc:skhdrc"
  ".dotfiles:"
  ".gitconfig:gitconfig"
  ".gitignore:gitignore"
  ".gemrc:gemrc"
  ".irbrc:irbrc"
  ".pryrc:pryrc"
  ".config/starship.toml:config/starship.toml"
)

usage() {
  cat <<'EOF'
Dotfiles Skill Commands:

  Symlinks
    status                    Show all managed symlinks and their state
    link                      Create/fix all symlinks
    unlink <name>             Remove a symlink (keeps source)
    add <home_path> <dotfile> Add a new file to management

  Git Sync
    sync [message]            Commit all changes and push to GitHub
    pull                      Pull latest from GitHub
    diff                      Show uncommitted changes
    log                       Show recent commits

  Info
    list                      List all files in dotfiles repo
    managed                   List the symlink map
EOF
}

link_one() {
  local target="$1"
  local source="$2"
  local home_path="$HOME/$target"
  local dotfile_path="$DOTFILES/$source"
  [ -z "$source" ] && dotfile_path="$DOTFILES"

  if [ -L "$home_path" ]; then
    local current
    current=$(readlink "$home_path")
    if [ "$current" = "$dotfile_path" ]; then
      echo "  ✓ ~/$target"
      return 0
    else
      ln -sfn "$dotfile_path" "$home_path"
      echo "  ✓ ~/$target (relinked)"
    fi
  elif [ -e "$home_path" ]; then
    echo "  ✗ ~/$target exists but is not a symlink"
    return 1
  else
    mkdir -p "$(dirname "$home_path")"
    ln -sfn "$dotfile_path" "$home_path"
    echo "  ✓ ~/$target (created)"
  fi
}

CMD="${1:-help}"
shift 2>/dev/null || true
ARGS=("$@")

case "$CMD" in
  status)
    echo "Dotfiles: $DOTFILES"
    echo "Remote:   $(git -C "$DOTFILES" remote get-url origin 2>/dev/null)"
    echo ""
    echo "Managed symlinks:"
    for entry in "${LINKS[@]}"; do
      target="${entry%%:*}"
      source="${entry#*:}"
      home_path="$HOME/$target"
      dotfile_path="$DOTFILES/$source"
      [ -z "$source" ] && dotfile_path="$DOTFILES"

      if [ -L "$home_path" ]; then
        current=$(readlink "$home_path")
        if [ "$current" = "$dotfile_path" ]; then
          echo "  ✓ ~/$target → $source"
        else
          echo "  ⚠ ~/$target → $(basename "$current") (expected: $source)"
        fi
      elif [ -e "$home_path" ]; then
        echo "  ✗ ~/$target exists (not a symlink)"
      else
        echo "  ○ ~/$target (not linked)"
      fi
    done
    echo ""
    changes=$(git -C "$DOTFILES" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    branch=$(git -C "$DOTFILES" branch --show-current 2>/dev/null)
    echo "Git: $branch | $changes uncommitted"
    ;;

  link)
    echo "Linking all managed dotfiles:"
    for entry in "${LINKS[@]}"; do
      target="${entry%%:*}"
      source="${entry#*:}"
      link_one "$target" "$source" || true
    done
    ;;

  unlink)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: dotfiles.sh unlink <target>"
      exit 1
    fi
    target="${ARGS[0]}"
    home_path="$HOME/$target"
    if [ -L "$home_path" ]; then
      rm "$home_path"
      echo "Unlinked: $target"
    else
      echo "$target is not a symlink"
    fi
    ;;

  add)
    if [ ${#ARGS[@]} -lt 2 ]; then
      echo "Usage: dotfiles.sh add <home_path> <dotfile_name>"
      echo "  e.g.: dotfiles.sh add .tmux.conf tmux.conf"
      exit 1
    fi
    target="${ARGS[0]}"
    source="${ARGS[1]}"
    home_path="$HOME/$target"
    dotfile_path="$DOTFILES/$source"

    if [ -e "$home_path" ] && [ ! -L "$home_path" ]; then
      mkdir -p "$(dirname "$dotfile_path")"
      cp -r "$home_path" "$dotfile_path"
      rm -rf "$home_path"
      ln -sfn "$dotfile_path" "$home_path"
      echo "Moved ~/$target → dotfiles/$source and linked"
      echo ""
      echo "Add to LINKS array in dotfiles.sh:"
      echo "  \"$target:$source\""
    elif [ -L "$home_path" ]; then
      echo "$target is already a symlink"
    else
      echo "$target doesn't exist in home"
    fi
    ;;

  sync)
    msg="${ARGS[*]:-dotfiles sync}"
    cd "$DOTFILES"
    if [ -z "$(git status --porcelain)" ]; then
      echo "Nothing to commit"
      git push 2>&1 || echo "(nothing to push)"
    else
      echo "Changes:"
      git status --short
      echo ""
      git add -A
      git commit -m "$msg"
      git push
      echo ""
      echo "Synced to GitHub"
    fi
    echo ""
    echo "Pulling on junkpile via mesh..."
    marauder mesh send junkpile exec '{"command":"cd ~/Projects/dotfiles && git pull --rebase"}' 2>/dev/null || echo "  (junkpile mesh sync failed)"
    ;;

  pull)
    cd "$DOTFILES"
    git pull --rebase
    echo ""
    echo "Pulling on junkpile via mesh..."
    marauder mesh send junkpile exec '{"command":"cd ~/Projects/dotfiles && git pull --rebase"}' 2>/dev/null || echo "  (junkpile mesh sync failed)"
    ;;

  diff)
    git -C "$DOTFILES" diff
    ;;

  log)
    git -C "$DOTFILES" log --oneline -15
    ;;

  list)
    ls -1 "$DOTFILES" | grep -v "^\.git$"
    ;;

  managed)
    echo "Symlink map:"
    for entry in "${LINKS[@]}"; do
      target="${entry%%:*}"
      source="${entry#*:}"
      [ -z "$source" ] && source="(repo root)"
      printf "  %-30s → %s\n" "~/$target" "$source"
    done
    ;;

  help|--help|-h|*)
    usage
    ;;
esac
