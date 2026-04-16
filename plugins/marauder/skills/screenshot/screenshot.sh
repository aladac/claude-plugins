#!/usr/bin/env bash
# Screenshot skill — multi-display capture for macOS
# Detects connected displays and captures each one separately.
# Usage: bash screenshot.sh [display_number|all|list]

set -euo pipefail

OUT_DIR="/tmp/marauder-screenshots"
mkdir -p "$OUT_DIR"

# Count connected displays via system_profiler
count_displays() {
  system_profiler SPDisplaysDataType 2>/dev/null \
    | grep -c "Resolution:" || echo 0
}

# Get display info table
display_info() {
  local idx=0
  system_profiler SPDisplaysDataType 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" =~ Resolution:\ (.+) ]]; then
      idx=$((idx + 1))
      res="${BASH_REMATCH[1]}"
      echo "$idx|$res"
    fi
  done
}

# Capture a single display
capture_one() {
  local display="$1"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local file="$OUT_DIR/display${display}-${ts}.png"
  screencapture -x -D "$display" "$file" 2>/dev/null
  echo "$file"
}

# Main
cmd="${1:-all}"

case "$cmd" in
  list|info)
    count=$(count_displays)
    echo "Displays: $count"
    echo ""
    display_info | while IFS='|' read -r idx res; do
      echo "  Display $idx: $res"
    done
    ;;

  all)
    count=$(count_displays)
    if [ "$count" -eq 0 ]; then
      echo "ERROR: No displays detected"
      exit 1
    fi
    echo "Capturing $count displays..."
    files=""
    for i in $(seq 1 "$count"); do
      file=$(capture_one "$i")
      echo "  Display $i: $file"
      files="$files $file"
    done
    echo ""
    echo "FILES:$files"
    ;;

  [0-9]*)
    file=$(capture_one "$cmd")
    echo "Display $cmd: $file"
    echo ""
    echo "FILES: $file"
    ;;

  clean)
    rm -f "$OUT_DIR"/display*.png 2>/dev/null
    echo "Cleaned $OUT_DIR"
    ;;

  help|*)
    cat <<'EOF'
Screenshot Skill — Multi-Display Capture

  all             Capture all connected displays (default)
  <N>             Capture display N only (1-indexed)
  list            Show connected displays and resolutions
  clean           Remove captured screenshots
  help            This message

Files are written to /tmp/marauder-screenshots/
EOF
    ;;
esac
