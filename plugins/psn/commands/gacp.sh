#!/usr/bin/env bash
# gacp — Git Add Commit Push
# Usage: gacp.sh "commit message"
set -euo pipefail

MSG="${1:-}"

# Check we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

# Check for changes
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "Nothing to commit — working tree clean"
  exit 0
fi

# Stage all changes
git add -A

# Auto-generate message if none provided
if [ -z "$MSG" ]; then
  FILES=$(git diff --cached --numstat | wc -l | tr -d ' ')
  ADDITIONS=$(git diff --cached --numstat | awk '{s+=$1} END {print s+0}')
  FILELIST=$(git diff --cached --name-only | sed 's/^/- /')
  MSG="[Updated] Files: ${FILES}, Lines: ${ADDITIONS}
${FILELIST}"
fi

# Show what's being committed
echo "=== Staged ==="
git diff --cached --stat
UNTRACKED=$(git diff --cached --diff-filter=A --name-only)
if [ -n "$UNTRACKED" ]; then
  echo ""
  echo "=== New files ==="
  echo "$UNTRACKED"
fi

echo ""

# Commit
git commit -m "$MSG"

echo ""

# Push — detect upstream or set it
BRANCH=$(git symbolic-ref --short HEAD)
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push
else
  echo "No upstream set — pushing with -u origin $BRANCH"
  git push -u origin "$BRANCH"
fi

echo ""
echo "=== Result ==="
git log --oneline -1
echo "Pushed to $(git remote get-url origin 2>/dev/null || echo 'origin') @ $BRANCH"
