#!/usr/bin/env bash
# plugin-reinstall.sh — Full PSN plugin reinstall via marketplace
# Usage: bash plugin-reinstall.sh [command]
#   (no args)  Full reinstall: bump + sync + uninstall + install
#   sync       Sync source to marketplace repo only
#   status     Compare versions across source, marketplace, cache, gem
set -euo pipefail

SOURCE="${CLAUDE_PLUGIN_ROOT}"
MARKETPLACE="$HOME/Projects/claude-plugins"
CACHE="$HOME/.claude/plugins/marketplaces/aladac/plugins/psn"
GEM_VERSION_FILE="$HOME/Projects/personality/lib/personality/version.rb"

get_gem_base() {
  grep 'VERSION' "$GEM_VERSION_FILE" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
}

get_source_version() {
  python3 -c "import json; print(json.load(open('$SOURCE/.claude-plugin/plugin.json'))['version'])"
}

get_cache_version() {
  if [ -f "$CACHE/.claude-plugin/plugin.json" ]; then
    python3 -c "import json; print(json.load(open('$CACHE/.claude-plugin/plugin.json'))['version'])"
  else
    echo "not installed"
  fi
}

get_marketplace_version() {
  if [ -f "$MARKETPLACE/plugins/psn/.claude-plugin/plugin.json" ]; then
    python3 -c "import json; print(json.load(open('$MARKETPLACE/plugins/psn/.claude-plugin/plugin.json'))['version'])"
  else
    echo "not found"
  fi
}

cmd_status() {
  echo "PSN Plugin Version Status"
  echo "========================="
  echo "Gem base:     $(get_gem_base)"
  echo "Source:       $(get_source_version)"
  echo "Marketplace:  $(get_marketplace_version)"
  echo "Cache:        $(get_cache_version)"
}

cmd_sync() {
  echo "==> Syncing source to marketplace..."
  rsync -av --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.venv' \
    --exclude='target' \
    --exclude='__pycache__' \
    "$SOURCE/" "$MARKETPLACE/plugins/psn/" 2>&1 | tail -3

  cd "$MARKETPLACE"
  if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "Marketplace already up to date"
  else
    VERSION=$(get_source_version)
    git add -A
    git commit -m "Sync psn plugin to ${VERSION}"
    git push
    echo "==> Marketplace pushed: ${VERSION}"
  fi
}

cmd_reinstall() {
  # Step 1: Bump plugin version
  echo "==> Bumping plugin version..."
  cd "$SOURCE"
  just bump 2>&1 | tail -1

  # Step 2: Commit and push source
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git add -A
    VERSION=$(get_source_version)
    git commit -m "Bump version to ${VERSION}"
    git push
    echo "==> Source pushed: ${VERSION}"
  else
    echo "==> Source already committed"
  fi

  # Step 3: Sync to marketplace
  cmd_sync

  # Step 4: Update marketplace git cache
  echo "==> Updating marketplace git cache..."
  MARKET_CACHE="$HOME/.claude/plugins/marketplaces/aladac"
  if [ -d "$MARKET_CACHE/.git" ]; then
    cd "$MARKET_CACHE"
    git pull --rebase 2>&1 | tail -3
  fi

  # Step 5: Uninstall old
  echo "==> Uninstalling old plugin..."
  claude plugin uninstall psn@aladac --keep-data 2>&1 || true

  # Step 6: Install new
  echo "==> Installing new plugin..."
  claude plugin install psn@aladac 2>&1

  # Step 6: Report
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
    echo "  (no args)   Full reinstall: bump + sync + uninstall + install"
    echo "  sync        Sync source to marketplace repo only"
    echo "  status      Compare versions across source, marketplace, cache, gem"
    ;;
esac
