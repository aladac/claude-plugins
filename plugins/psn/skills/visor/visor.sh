#!/usr/bin/env bash
# Visor Snapshot — capture MARAUDER VISOR TUI via Kitty remote control
# Usage: bash visor.sh [snap|status|find]

set -euo pipefail

# Find the visor pane ID by matching title or process
find_visor_pane() {
  # Try to find by title containing "just dev" or "marauder-visor"
  kitten @ ls 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for w in data:
  for t in w['tabs']:
    for win in t['windows']:
      title = win.get('title', '')
      fg = ' '.join(win.get('foreground_processes', [{}])[0].get('cmdline', []))
      if 'just dev' in title or 'marauder-visor' in title or 'marauder-visor' in fg or 'cargo-watch' in fg:
        print(win['id'])
        sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

cmd="${1:-snap}"

case "$cmd" in
  snap|s)
    pane_id=$(find_visor_pane) || {
      echo "ERROR: Visor pane not found in Kitty"
      echo "Is 'just dev' running in a Kitty pane?"
      exit 1
    }
    echo "==> Visor pane: id=$pane_id"
    echo ""
    kitten @ get-text --match "id:$pane_id" 2>/dev/null
    ;;

  status|st)
    if curl -sf http://127.0.0.1:9876/status 2>/dev/null; then
      echo ""
      echo "Visor bridge: UP"
    else
      echo "Visor bridge: DOWN (port 9876 not responding)"
      exit 1
    fi
    ;;

  find|f)
    pane_id=$(find_visor_pane) || {
      echo "Visor pane not found"
      exit 1
    }
    echo "Visor pane ID: $pane_id"
    # Show all panes for context
    echo ""
    echo "All Kitty panes:"
    kitten @ ls 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for w in data:
  for t in w['tabs']:
    for win in t['windows']:
      marker = ' <-- VISOR' if win['id'] == $pane_id else ''
      print(f\"  id={win['id']} title={win.get('title', '?')}{marker}\")
" 2>/dev/null
    ;;

  help|*)
    cat <<'EOF'
Visor Snapshot — MARAUDER VISOR TUI Capture

  snap    Capture visor pane text content (default)
  status  Check if visor HTTP bridge is running
  find    Find the visor pane ID in Kitty
  help    This message

Requires Kitty with remote control enabled.
EOF
    ;;
esac
