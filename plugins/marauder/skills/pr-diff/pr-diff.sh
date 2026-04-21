#!/usr/bin/env bash
# PR Diff Preview — GitHub-style HTML diff rendering
set -euo pipefail

STYLE="line"
OUTPUT="/tmp/pr-diff"
OPEN=true
WATERFALL=false
RANGES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --side)       STYLE="side"; shift ;;
    --waterfall)  WATERFALL=true; shift ;;
    --no-open)    OPEN=false; shift ;;
    --output)     OUTPUT="$2"; shift 2 ;;
    -*)           echo "Unknown option: $1" >&2; exit 1 ;;
    *)            RANGES+=("$1"); shift ;;
  esac
done

if [[ ${#RANGES[@]} -eq 0 ]]; then
  echo "Usage: pr-diff.sh [--side] [--waterfall] [--no-open] [--output DIR] <base>..<head> [...]" >&2
  exit 1
fi

# Waterfall: rewrite ranges so each diffs from the root base
# Input:  A..B  B..C  C..D
# Output: A..B  A..C  A..D
if $WATERFALL && [[ ${#RANGES[@]} -gt 1 ]]; then
  root="${RANGES[0]%..*}"
  WATERFALL_RANGES=()
  for range in "${RANGES[@]}"; do
    head="${range#*..}"
    WATERFALL_RANGES+=("${root}..${head}")
  done
  RANGES=("${WATERFALL_RANGES[@]}")
fi

if ! command -v diff2html &>/dev/null; then
  echo "diff2html-cli not found. Install with: npm install -g diff2html-cli" >&2
  exit 1
fi

rm -rf "$OUTPUT"
mkdir -p "$OUTPUT"

FILES=()

for range in "${RANGES[@]}"; do
  base="${range%..*}"
  head="${range#*..}"
  name="${head//\//-}"

  diff_file="$OUTPUT/${name}.diff"
  html_file="$OUTPUT/${name}.html"

  git diff "$range" > "$diff_file"

  stat=$(git diff --shortstat "$range")
  files_changed=$(echo "$stat" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo "0")
  insertions=$(echo "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
  deletions=$(echo "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")

  diff2html -i file -s "$STYLE" -F "$html_file" -- "$diff_file"

  FILES+=("${name}.html|${head}|${files_changed}|+${insertions}/-${deletions}")
  echo "Generated: $html_file ($stat)"
done

if [[ ${#FILES[@]} -gt 1 ]]; then
  MODE_LABEL="PR Diff Preview"
  $WATERFALL && MODE_LABEL="PR Diff Preview (waterfall)"

  cat > "$OUTPUT/index.html" << HEADER
<!DOCTYPE html>
<html><head><title>${MODE_LABEL}</title>
<style>
body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 700px; margin: 40px auto; padding: 20px; color: #1f2328; }
h2 { border-bottom: 1px solid #d0d7de; padding-bottom: 8px; }
a { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; margin: 8px 0; background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px; text-decoration: none; color: #0969da; }
a:hover { background: #ddf4ff; }
.meta { color: #57606a; font-size: 0.9em; }
.add { color: #1a7f37; } .del { color: #cf222e; }
</style></head>
<body><h2>${MODE_LABEL}</h2>
HEADER

  for entry in "${FILES[@]}"; do
    IFS='|' read -r file branch files stat <<< "$entry"
    add=$(echo "$stat" | cut -d/ -f1)
    del=$(echo "$stat" | cut -d/ -f2)
    cat >> "$OUTPUT/index.html" << EOF
<a href="${file}"><span>${branch}</span><span class="meta">${files} files <span class="add">${add}</span> <span class="del">${del}</span></span></a>
EOF
  done

  echo "</body></html>" >> "$OUTPUT/index.html"
  ENTRY="$OUTPUT/index.html"
else
  ENTRY="$OUTPUT/${FILES[0]%%|*}"
fi

if $OPEN; then
  open "$ENTRY"
  echo "Opened: $ENTRY"
else
  echo "Output: $ENTRY"
fi
