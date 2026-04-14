#!/usr/bin/env bash
# LaTeX skill — build CVs, cover letters, and generate skill pills
# Usage: bash latex.sh <command> [args...]
# Requires: pdflatex (TeX Live), ImageMagick (magick), Ruby

set -euo pipefail

PDFLATEX="/Library/TeX/texbin/pdflatex"
CV_DIR="$HOME/Projects/cv"
IMG_DIR="$CV_DIR/img"
GENERATOR="$CV_DIR/generate_label/generate_label.rb"

usage() {
  cat <<'EOF'
LaTeX Skill Commands:

  Build
    build [file]              Build a .tex file (default: cv.tex)
    build-cv                  Build cv.pdf
    build-cover               Build cover.pdf
    build-dist                Build cv-dist.pdf

  Pills
    pill <icon> <label> [-o name.png]   Generate a skill pill image
    pill-list                            List all existing pill images

  Info
    check                     Verify TeX Live and dependencies installed
    open [file]               Open PDF in Preview (default: cv.pdf)
    list                      List all .tex files
    clean                     Remove build artifacts

  Watch
    watch [file]              Watch and rebuild on change (default: cv.tex)
EOF
}

CMD="${1:-help}"
shift 2>/dev/null || true
ARGS=("$@")

case "$CMD" in
  build)
    file="${ARGS[0]:-cv.tex}"
    cd "$CV_DIR"
    "$PDFLATEX" -interaction=nonstopmode "$file" 2>&1 | grep -E "^(Output|!|.*Error)" || true
    rm -f *.png 2>/dev/null || true
    base="${file%.tex}"
    if [ -f "$base.pdf" ]; then
      echo "Built: $CV_DIR/$base.pdf"
    else
      echo "Build failed. Run with verbose:"
      echo "  $PDFLATEX $file"
    fi
    ;;

  build-cv)
    cd "$CV_DIR"
    "$PDFLATEX" -interaction=nonstopmode cv.tex 2>&1 | grep -E "^(Output|!|.*Error)" || true
    rm -f *.png 2>/dev/null || true
    echo "Built: $CV_DIR/cv.pdf"
    ;;

  build-cover)
    cd "$CV_DIR"
    "$PDFLATEX" -interaction=nonstopmode cover.tex 2>&1 | grep -E "^(Output|!|.*Error)" || true
    echo "Built: $CV_DIR/cover.pdf"
    ;;

  build-dist)
    cd "$CV_DIR"
    if [ -f cv-dist.tex ]; then
      "$PDFLATEX" -interaction=nonstopmode cv-dist.tex 2>&1 | grep -E "^(Output|!|.*Error)" || true
      rm -f *.png 2>/dev/null || true
      echo "Built: $CV_DIR/cv-dist.pdf"
    else
      echo "cv-dist.tex not found — build cv.tex instead"
    fi
    ;;

  pill)
    if [ ${#ARGS[@]} -lt 2 ]; then
      echo "Usage: latex.sh pill <icon.png> <Label Text> [-o output.png]"
      echo ""
      echo "Examples:"
      echo "  latex.sh pill ruby.png Ruby"
      echo "  latex.sh pill docker.png Docker -o img/docker.png"
      echo ""
      echo "All pills are grayscale, 2200px wide. Icon source should be in generate_label/ or provide full path."
      exit 1
    fi
    icon="${ARGS[0]}"
    label="${ARGS[1]}"
    output=""
    if [ ${#ARGS[@]} -ge 4 ] && [ "${ARGS[2]}" = "-o" ]; then
      output="${ARGS[3]}"
    else
      slug=$(echo "$label" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
      output="$IMG_DIR/$slug.png"
    fi
    cd "$CV_DIR"
    ruby "$GENERATOR" -i "$icon" -t "$label" -w 2200 -o "$output" --grayscale
    echo "Generated: $output"
    ;;

  pill-list)
    echo "Skill pills in $IMG_DIR:"
    ls -1 "$IMG_DIR"/*.png 2>/dev/null | while read -r f; do
      basename "$f" .png
    done | sort | column
    echo ""
    total=$(ls -1 "$IMG_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    echo "Total: $total pills"
    ;;

  check)
    echo "TeX Live:"
    if [ -x "$PDFLATEX" ]; then
      "$PDFLATEX" --version 2>&1 | head -1
    else
      echo "  NOT FOUND at $PDFLATEX"
    fi
    echo ""
    echo "ImageMagick:"
    if command -v magick &>/dev/null; then
      magick --version 2>&1 | head -1
    else
      echo "  NOT FOUND (needed for pill generation)"
    fi
    echo ""
    echo "Ruby:"
    if command -v ruby &>/dev/null; then
      ruby --version
    else
      echo "  NOT FOUND (needed for pill generation)"
    fi
    echo ""
    echo "fswatch:"
    if command -v fswatch &>/dev/null; then
      echo "  installed ($(which fswatch))"
    else
      echo "  NOT FOUND (needed for just watch)"
    fi
    echo ""
    echo "just:"
    if command -v just &>/dev/null; then
      echo "  installed ($(which just))"
    else
      echo "  NOT FOUND"
    fi
    ;;

  open)
    file="${ARGS[0]:-cv.pdf}"
    open "$CV_DIR/$file"
    ;;

  list)
    echo "TeX files in $CV_DIR:"
    ls -1 "$CV_DIR"/*.tex 2>/dev/null | while read -r f; do
      basename "$f"
    done
    ;;

  clean)
    cd "$CV_DIR"
    rm -f *.aux *.log *.out *.fdb_latexmk *.fls *.synctex.gz
    echo "Cleaned build artifacts"
    ;;

  watch)
    file="${ARGS[0]:-cv.tex}"
    echo "Watching $CV_DIR/$file..."
    cd "$CV_DIR"
    while true; do
      fswatch -1 "$file"
      echo "Rebuilding..."
      "$PDFLATEX" -interaction=nonstopmode "$file" 2>&1 | grep -E "^(Output|!|.*Error)" || true
      rm -f *.png 2>/dev/null || true
    done
    ;;

  help|--help|-h|*)
    usage
    ;;
esac
