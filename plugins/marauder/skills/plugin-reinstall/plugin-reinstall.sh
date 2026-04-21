#!/usr/bin/env bash
# plugin-reinstall.sh — Marauder plugin reinstall via local-dev
# Usage: bash plugin-reinstall.sh [command]
#   (no args)  Full reinstall: sync + uninstall + install
#   sync       Sync source to marketplace repo only
#   status     Show current version info
set -euo pipefail

SOURCE="${CLAUDE_PLUGIN_ROOT:-/home/chi/Projects/marauder-plugin}"
MARKETPLACE="$HOME/Projects/claude-plugins"
MARKETPLACE_DEST="$MARKETPLACE/plugins/marauder"
CACHE="$HOME/.claude/plugins/cache/local-dev/marauder"
PLUGIN_ID="marauder@local-dev"

get_source_version() {
  python3 -c "import json; print(json.load(open('$SOURCE/.claude-plugin/plugin.json'))['version'])"
}

get_cache_version() {
  local latest
  latest=$(ls -1t "$CACHE" 2>/dev/null | head -1)
  if [ -n "$latest" ] && [ -f "$CACHE/$latest/.claude-plugin/plugin.json" ]; then
    python3 -c "import json; print(json.load(open('$CACHE/$latest/.claude-plugin/plugin.json'))['version'])"
  else
    echo "not installed"
  fi
}

get_marketplace_version() {
  if [ -f "$MARKETPLACE_DEST/.claude-plugin/plugin.json" ]; then
    python3 -c "import json; print(json.load(open('$MARKETPLACE_DEST/.claude-plugin/plugin.json'))['version'])"
  else
    echo "not found"
  fi
}

cmd_status() {
  echo "Marauder Plugin Version Status"
  echo "==============================="
  echo "Source:       $(get_source_version)"
  echo "Marketplace:  $(get_marketplace_version)"
  echo "Cache:        $(get_cache_version)"
}

cmd_sync() {
  # Push source if dirty
  cd "$SOURCE"
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    # Commit first, then stamp version with the new commit hash
    OS_VERSION=$(grep '^version' /home/chi/Projects/marauder-os/Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')
    git add -A
    git commit -m "Update marauder plugin"
    HASH=$(git rev-parse --short HEAD)
    STAMPED="${OS_VERSION}-${HASH}"
    python3 -c "
import json, pathlib
p = pathlib.Path('$SOURCE/.claude-plugin/plugin.json')
d = json.loads(p.read_text())
d['version'] = '${STAMPED}'
p.write_text(json.dumps(d, indent=2) + '\n')
"
    git add -A
    git commit --amend -m "Update marauder plugin ${STAMPED}"
    git push --force-with-lease
    echo "==> Source pushed: ${STAMPED}"
  else
    echo "==> Source already clean"
  fi

  # Sync to marketplace
  echo "==> Syncing source to marketplace..."
  rsync -av --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.venv' \
    --exclude='target' \
    --exclude='__pycache__' \
    "$SOURCE/" "$MARKETPLACE_DEST/" 2>&1 | tail -3

  cd "$MARKETPLACE"
  if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "Marketplace already up to date"
  else
    VERSION=$(get_source_version)
    git add -A
    git commit -m "Sync marauder plugin to ${VERSION}"
    git push
    echo "==> Marketplace pushed: ${VERSION}"
  fi
}

cmd_reinstall() {
  # Step 1: Sync to marketplace
  cmd_sync

  # Step 2: Uninstall old
  echo "==> Uninstalling old plugin..."
  claude plugin uninstall "$PLUGIN_ID" --keep-data 2>&1 || true

  # Step 3: Install new
  echo "==> Installing new plugin..."
  claude plugin install "$PLUGIN_ID" 2>&1

  # Step 4: Report
  echo ""
  echo "==> Done!"
  cmd_status
  echo ""
  echo "Run /reload-plugins or restart session (/cc) to activate."
}

# --- Main ---
case "${1:-reinstall}" in
  status)
    cmd_status
    ;;
  sync)
    cmd_sync
    ;;
  reinstall|"")
    cmd_reinstall
    ;;
  *)
    echo "Usage: bash plugin-reinstall.sh [status|sync|reinstall]"
    echo ""
    echo "Commands:"
    echo "  (no args)   Full reinstall: sync + uninstall + install"
    echo "  sync        Sync source to marketplace repo only"
    echo "  status      Show current version info"
    ;;
esac
