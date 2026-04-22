#!/usr/bin/env bash
# worktree-rm — safely remove a git worktree and its branch
# Usage: worktree-rm.sh [worktree-name-or-path] [--force] [--keep-branch]
set -euo pipefail

FORCE=0
KEEP_BRANCH=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --force)        FORCE=1 ;;
    --keep-branch)  KEEP_BRANCH=1 ;;
    *)              TARGET="$arg" ;;
  esac
done

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

# Prune stale worktree metadata first (handles already-deleted dirs)
git worktree prune 2>/dev/null || true

# List worktrees (skip first line = main worktree)
WORKTREES=$(git worktree list --porcelain | grep "^worktree " | tail -n +2 | sed 's/^worktree //')

if [ -z "$WORKTREES" ]; then
  echo "No worktrees to remove."
  exit 0
fi

# If no target given, list and prompt
if [ -z "$TARGET" ]; then
  echo "Available worktrees:"
  i=1
  while IFS= read -r wt; do
    BRANCH=$(git worktree list --porcelain | grep -A2 "^worktree $wt" | grep "^branch" | sed 's/^branch refs\/heads\///' || echo "detached")
    echo "  [$i] $wt  ($BRANCH)"
    i=$((i+1))
  done <<< "$WORKTREES"
  echo ""
  printf "Enter number or path: "
  read -r SELECTION
  if [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
    TARGET=$(echo "$WORKTREES" | sed -n "${SELECTION}p")
  else
    TARGET="$SELECTION"
  fi
fi

# Resolve relative .claude/worktrees/<name> shorthand
if [[ "$TARGET" != /* ]] && [[ "$TARGET" != ./* ]]; then
  REPO_ROOT=$(git rev-parse --show-toplevel)
  CANDIDATE="$REPO_ROOT/.claude/worktrees/$TARGET"
  if [ -d "$CANDIDATE" ] || git worktree list --porcelain | grep -q "^worktree $CANDIDATE"; then
    TARGET="$CANDIDATE"
  fi
fi

# Verify it's a registered worktree
if ! git worktree list --porcelain | grep -q "^worktree $TARGET"; then
  echo "ERROR: '$TARGET' is not a registered worktree" >&2
  echo ""
  echo "Registered worktrees:"
  git worktree list
  exit 1
fi

# Get the branch name before removal
BRANCH=$(git worktree list --porcelain | grep -A5 "^worktree $TARGET" | grep "^branch" | sed 's|^branch refs/heads/||' || true)

# Check for uncommitted changes
DIRTY=""
if [ -d "$TARGET" ]; then
  DIRTY=$(git -C "$TARGET" status --porcelain 2>/dev/null || true)
fi

if [ -n "$DIRTY" ] && [ "$FORCE" -eq 0 ]; then
  echo "WARNING: Worktree has uncommitted changes:"
  echo "$DIRTY"
  echo ""
  printf "Remove anyway? [y/N]: "
  read -r CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
  FORCE=1
fi

# Remove the worktree
if [ "$FORCE" -eq 1 ]; then
  git worktree remove --force "$TARGET"
else
  git worktree remove "$TARGET"
fi

echo "Removed worktree: $TARGET"

# Delete the branch
if [ -n "$BRANCH" ] && [ "$KEEP_BRANCH" -eq 0 ]; then
  # Try graceful delete first, fall back to force
  if git branch -d "$BRANCH" 2>/dev/null; then
    echo "Deleted branch: $BRANCH"
  elif git branch -D "$BRANCH" 2>/dev/null; then
    echo "Force-deleted branch: $BRANCH (was not merged to HEAD)"
  else
    echo "Note: could not delete branch '$BRANCH' — may not exist locally"
  fi
fi

echo ""
echo "Remaining worktrees:"
git worktree list
