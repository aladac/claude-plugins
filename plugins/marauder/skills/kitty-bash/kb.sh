#!/usr/bin/env bash
# kb.sh — KittyBash: route shell commands to a Kitty preview pane
# Usage:
#   kb.sh set <pane_id>       — set the active preview pane
#   kb.sh get                 — show the active pane ID
#   kb.sh detect              — list candidate panes (non-focused, idle shells)
#   kb.sh run <command>       — send command to pane, wait, read output
#   kb.sh read [lines]        — read pane content (default: tail 15 lines)
#   kb.sh send <text>         — send raw text (no \r)
#   kb.sh clear               — clear the pane
set -euo pipefail

PANE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/marauder/kitty-pane"
WAIT="${KB_WAIT:-2}"

get_pane() {
  if [ -f "$PANE_FILE" ]; then
    cat "$PANE_FILE"
  else
    echo ""
  fi
}

require_pane() {
  local pane
  pane=$(get_pane)
  if [ -z "$pane" ]; then
    echo "ERROR: No preview pane set. Run: kb.sh detect or kb.sh set <pane_id>" >&2
    exit 1
  fi
  # Verify pane still exists
  if ! kitty @ ls 2>/dev/null | python3 -c "
import sys, json
ids = [w['id'] for osw in json.load(sys.stdin) for t in osw.get('tabs',[]) for w in t.get('windows',[])]
sys.exit(0 if $pane in ids else 1)
" 2>/dev/null; then
    echo "ERROR: Pane id:$pane no longer exists. Run: kb.sh detect" >&2
    exit 1
  fi
  echo "$pane"
}

# Detect candidate panes: non-focused, running a shell (idle).
# Output: one line per candidate — "id:N  title:TITLE"
# Exit 0 if candidates found, 1 if none.
detect_panes() {
  kitty @ ls 2>/dev/null | python3 -c "
import sys, json, subprocess

shells = {'zsh', 'bash', 'fish', 'sh'}
candidates = []
for osw in json.load(sys.stdin):
    for tab in osw.get('tabs', []):
        for win in tab.get('windows', []):
            if win.get('is_focused', False):
                continue
            # Check foreground process — idle shells are candidates
            fg = win.get('foreground_processes', [])
            fg_cmds = set()
            for proc in fg:
                for arg in proc.get('cmdline', []):
                    # Strip path and leading dash (login shell: -zsh → zsh)
                    name = arg.rsplit('/')[-1].lstrip('-')
                    fg_cmds.add(name)
            # A pane is idle if its only foreground process is a shell
            if fg_cmds and fg_cmds.issubset(shells):
                candidates.append((win['id'], win.get('title', '(untitled)')))

if not candidates:
    print('NO_CANDIDATES')
    sys.exit(1)

for wid, title in candidates:
    print(f'id:{wid}  title:{title}')
"
}

case "${1:-help}" in
  set)
    mkdir -p "$(dirname "$PANE_FILE")"
    echo "${2:?Usage: kb.sh set <pane_id>}" > "$PANE_FILE"
    echo "Preview pane set to id:${2}"
    ;;

  get)
    pane=$(get_pane)
    if [ -n "$pane" ]; then
      echo "id:$pane"
    else
      echo "No pane set"
    fi
    ;;

  detect)
    detect_panes
    ;;

  run)
    pane=$(require_pane)
    shift
    cmd="$*"
    kitty @ send-text --match "id:$pane" "${cmd}\r"
    sleep "$WAIT"
    kitty @ get-text --match "id:$pane" --extent screen | tail -"${KB_LINES:-15}"
    ;;

  read)
    pane=$(require_pane)
    lines="${2:-15}"
    kitty @ get-text --match "id:$pane" --extent screen | tail -"$lines"
    ;;

  send)
    pane=$(require_pane)
    shift
    kitty @ send-text --match "id:$pane" "$*"
    ;;

  clear)
    pane=$(require_pane)
    kitty @ send-text --match "id:$pane" 'clear\r'
    ;;

  help|*)
    echo "KittyBash — route commands to a Kitty preview pane"
    echo ""
    echo "  kb.sh set <id>      Set preview pane"
    echo "  kb.sh get           Show active pane ID"
    echo "  kb.sh detect        List idle shell panes (candidates for preview)"
    echo "  kb.sh run <cmd>     Send command + read output"
    echo "  kb.sh read [lines]  Read pane (default 15 lines)"
    echo "  kb.sh send <text>   Send raw text (no enter)"
    echo "  kb.sh clear         Clear the pane"
    echo ""
    echo "Env: KB_WAIT=2 (seconds to wait after run), KB_LINES=15 (tail lines)"
    ;;
esac
