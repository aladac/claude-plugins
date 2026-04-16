#!/usr/bin/env bash
# Image generation skill - tsr CLI + HUD display
# Usage: bash tsr.sh <command> [args...]

set -euo pipefail

TSR="/Users/chi/.local/bin/tsr"
HUD_URL="http://127.0.0.1:9876"
DEFAULT_NEG="blurry, low quality, text, watermark, deformed, ugly"

cmd="${1:-help}"
shift 2>/dev/null || true

# --- Helpers ---

hud_check() {
  curl -sf "$HUD_URL/status" >/dev/null 2>&1
}

hud_show_image() {
  local file="$1"
  local title="${2:-IMAGE}"
  local caption="${3:-}"
  local classification="${4:-[ GENERATED ]}"
  local tint="${5:-true}"

  if ! hud_check; then
    echo "HUD not running, skipping display"
    return 0
  fi

  # POST to visor /image endpoint — supports file:// paths directly
  HUD_TITLE="$title" HUD_CAPTION="$caption" HUD_CLASS="$classification" \
  HUD_TINT="$tint" HUD_FILE="$file" HUD_URL="$HUD_URL" \
  python3 << 'PYEOF'
import json, urllib.request, os

payload = json.dumps({
    "source": f"file://{os.environ['HUD_FILE']}",
    "title": os.environ.get("HUD_TITLE", "IMAGE") or None,
    "caption": os.environ.get("HUD_CAPTION", "") or None,
    "classification": os.environ.get("HUD_CLASS", "[ GENERATED ]") or None,
    "tint": os.environ.get("HUD_TINT", "true") == "true",
}).encode()

url = os.environ.get("HUD_URL", "http://127.0.0.1:9876")
req = urllib.request.Request(f"{url}/image", data=payload, headers={"Content-Type": "application/json"})
urllib.request.urlopen(req)
PYEOF
}

hud_show_grid() {
  # All config via env vars — no positional arg confusion
  local files=("$@")

  if ! hud_check; then
    echo "HUD not running, skipping display"
    return 0
  fi

  # POST to visor /image/grid endpoint — supports file:// paths directly
  python3 - "${files[@]}" << 'PYEOF'
import json, urllib.request, sys, os

files = sys.argv[1:]
images = []
for f in files:
    caption = os.path.basename(f).rsplit(".", 1)[0]
    images.append({"source": f"file://{os.path.abspath(f)}", "caption": caption})

payload = json.dumps({
    "images": images,
    "title": os.environ.get("GRID_TITLE", "GALLERY") or None,
    "classification": os.environ.get("GRID_CLASS", "[ GENERATED ]") or None,
    "tint": os.environ.get("GRID_TINT", "true") == "true",
    "columns": int(os.environ["GRID_COLUMNS"]) if os.environ.get("GRID_COLUMNS") else None,
}).encode()

url = os.environ.get("HUD_URL", "http://127.0.0.1:9876")
req = urllib.request.Request(f"{url}/image/grid", data=payload, headers={"Content-Type": "application/json"})
urllib.request.urlopen(req)
PYEOF
}

# --- Commands ---

case "$cmd" in
  generate|gen|g)
    prompt="${1:?Usage: tsr.sh generate <prompt> [options]}"
    shift

    # Parse options
    extra_args=()
    hud=false
    hud_title="GENERATED"
    hud_caption="$prompt"
    hud_class="[ GENERATED ]"
    hud_tint="true"
    output="/tmp/tsr-$(date +%s).png"
    neg=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --hud) hud=true; shift ;;
        --title) hud_title="$2"; shift 2 ;;
        --caption) hud_caption="$2"; shift 2 ;;
        --classification) hud_class="$2"; shift 2 ;;
        --no-tint) hud_tint="false"; shift ;;
        --negative|-n) neg="$2"; shift 2 ;;
        --output|-o) output="$2"; shift 2 ;;
        *) extra_args+=("$1"); shift ;;
      esac
    done

    [ -z "$neg" ] && neg="$DEFAULT_NEG"

    echo "Generating: $prompt"
    $TSR generate "$prompt" --remote junkpile -o "$output" -n "$neg" ${extra_args[@]+"${extra_args[@]}"} 2>&1

    if [ -f "$output" ]; then
      echo "Saved: $output"
      if [ "$hud" = true ]; then
        hud_show_image "$output" "$hud_title" "$hud_caption" "$hud_class" "$hud_tint"
        echo "Displayed on HUD"
      fi
    else
      echo "ERROR: Generation failed"
      exit 1
    fi
    ;;

  batch|b)
    prompt="${1:?Usage: tsr.sh batch <prompt> [options]}"
    shift

    count=4
    hud=false
    hud_title="GALLERY"
    hud_class="[ GENERATED ]"
    hud_tint="true"
    columns=""
    neg=""
    extra_args=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --count|-c) count="$2"; shift 2 ;;
        --hud) hud=true; shift ;;
        --title) hud_title="$2"; shift 2 ;;
        --classification) hud_class="$2"; shift 2 ;;
        --columns) columns="$2"; shift 2 ;;
        --no-tint) hud_tint="false"; shift ;;
        --negative|-n) neg="$2"; shift 2 ;;
        *) extra_args+=("$1"); shift ;;
      esac
    done

    [ -z "$neg" ] && neg="$DEFAULT_NEG"

    echo "Generating $count images: $prompt"
    files=()
    pids=()
    for i in $(seq 1 "$count"); do
      output="/tmp/tsr-batch-$$-${i}.png"
      $TSR generate "$prompt" --remote junkpile -o "$output" -n "$neg" ${extra_args[@]+"${extra_args[@]}"} &
      pids+=($!)
      files+=("$output")
      sleep 0.2  # stagger slightly
    done

    # Wait for all
    for pid in "${pids[@]}"; do
      wait "$pid" 2>/dev/null || true
    done

    # Report results
    generated=()
    for f in "${files[@]}"; do
      if [ -f "$f" ]; then
        generated+=("$f")
        echo "Saved: $f"
      fi
    done

    echo "Generated ${#generated[@]}/$count images"

    if [ "$hud" = true ] && [ ${#generated[@]} -gt 0 ]; then
      export HUD_URL GRID_TITLE="$hud_title" GRID_CLASS="$hud_class" GRID_TINT="$hud_tint"
      [ -n "$columns" ] && export GRID_COLUMNS="$columns"
      hud_show_grid "${generated[@]}"
      echo "Displayed grid on HUD"
    fi
    ;;

  hud|show|display)
    file="${1:?Usage: tsr.sh hud <file> [--title T] [--caption C]}"
    shift

    title="IMAGE"
    caption="$(basename "$file")"
    classification="[ RECON ]"
    tint="true"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --title) title="$2"; shift 2 ;;
        --caption) caption="$2"; shift 2 ;;
        --classification) classification="$2"; shift 2 ;;
        --no-tint) tint="false"; shift ;;
        *) echo "Warning: unknown option: $1" >&2; shift ;;
      esac
    done

    hud_show_image "$file" "$title" "$caption" "$classification" "$tint"
    echo "Displayed on HUD: $file"
    ;;

  grid)
    files=()
    title="GALLERY"
    classification="[ RECON ]"
    columns=""
    tint="true"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --title) title="$2"; shift 2 ;;
        --classification) classification="$2"; shift 2 ;;
        --columns) columns="$2"; shift 2 ;;
        --no-tint) tint="false"; shift ;;
        *) files+=("$1"); shift ;;
      esac
    done

    if [ ${#files[@]} -eq 0 ]; then
      echo "Usage: tsr.sh grid <file1> <file2> ... [--title T] [--columns N]"
      exit 1
    fi

    export HUD_URL GRID_TITLE="$title" GRID_CLASS="$classification" GRID_TINT="$tint"
    [ -n "$columns" ] && export GRID_COLUMNS="$columns"
    hud_show_grid "${files[@]}"
    echo "Displayed ${#files[@]} images on HUD"
    ;;

  models|m)
    echo "Available models on junkpile:"
    $TSR models --remote junkpile 2>&1
    ;;

  status|s)
    echo "Checking tensors API on junkpile..."
    curl -sf "http://10.0.0.2:5003/api/status" 2>&1 || echo "ERROR: tensors API not responding"
    echo ""
    echo "HUD bridge:"
    curl -sf "$HUD_URL/status" 2>&1 || echo "HUD not running"
    ;;

  help|h|*)
    echo "tsr.sh — Image generation via ComfyUI on junkpile"
    echo ""
    echo "Commands:"
    echo "  generate <prompt> [opts]  Generate a single image"
    echo "  batch <prompt> [opts]     Generate multiple images"
    echo "  hud <file> [opts]         Display image on HUD"
    echo "  grid <files...> [opts]    Display image grid on HUD"
    echo "  models                    List available models"
    echo "  status                    Check ComfyUI/HUD status"
    echo ""
    echo "Options: --hud --title --caption --model -m --steps --count -c --columns --no-tint"
    ;;
esac
