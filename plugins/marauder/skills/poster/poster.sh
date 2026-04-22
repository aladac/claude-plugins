#!/usr/bin/env bash
# poster.sh — MARAUDER poster generator
# Creates a landscape poster with an image on the left and styled text on the right.
# Color scheme: #080c12 background, #e8872b orange accent, #c8d4de text, #4a6080 muted.
#
# Usage:
#   poster.sh --image <path> --title <title> --text <text> [--output <path>]
#   poster.sh --image <path> --title <title> --p1 <text> --p2 <text> [--p3 ...] [--p4 ...]
#   echo "text" | poster.sh --image <path> --title <title>
#
# Examples:
#   poster.sh -i mech.png -t "PROTOCOL 3" --p1 "First." --p2 "Second."
#   poster.sh -i bg.png -t "REPORT" --text "Single block of text."

set -euo pipefail

# --- Defaults ---
DIN="/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf"
DINA="/System/Library/Fonts/Supplemental/DIN Alternate Bold.ttf"
OUTPUT="${HOME}/Desktop/poster.png"
TITLE=""
IMAGE=""
TEXT=""
P1="" P2="" P3="" P4=""
ATTRIBUTION="MARAUDER  ×  BT-7274  //  $(date +%Y-%m-%d)"
BAR_TEXT="LINK ESTABLISHED  //  PILOT-TITAN NEURAL HANDSHAKE ACTIVE"

# --- Colors ---
BG="#080c12"
ACCENT="#e8872b"
TEXT_COLOR="#c8d4de"
MUTED="#4a6080"
DIVIDER="#e8872b66"

# --- Dimensions ---
WIDTH=2400
HEIGHT=1350
IMG_WIDTH=1200
TEXT_X=1380
TEXT_WIDTH=940
BAR_HEIGHT=36
FADE_WIDTH=250

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --image|-i)       IMAGE="$2"; shift 2 ;;
    --title|-t)       TITLE="$2"; shift 2 ;;
    --text)           TEXT="$2"; shift 2 ;;
    --p1)             P1="$2"; shift 2 ;;
    --p2)             P2="$2"; shift 2 ;;
    --p3)             P3="$2"; shift 2 ;;
    --p4)             P4="$2"; shift 2 ;;
    --output|-o)      OUTPUT="$2"; shift 2 ;;
    --attribution|-a) ATTRIBUTION="$2"; shift 2 ;;
    --bar|-b)         BAR_TEXT="$2"; shift 2 ;;
    --width)          WIDTH="$2"; shift 2 ;;
    --height)         HEIGHT="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,14s/^# \?//p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Validate ---
[ -z "$IMAGE" ] && { echo "ERROR: --image is required"; exit 1; }
[ ! -f "$IMAGE" ] && { echo "ERROR: Image not found: $IMAGE"; exit 1; }
[ -z "$TITLE" ] && { echo "ERROR: --title is required"; exit 1; }

# --- Resolve text ---
if [ -n "$P1" ]; then
  :
elif [ -n "$TEXT" ]; then
  P1="$TEXT"
elif [ ! -t 0 ]; then
  P1="$(cat)"
else
  echo "ERROR: Provide text via --text, --p1..--p4, or stdin"
  exit 1
fi

# --- Temp dir ---
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

BAR_TOP=$((HEIGHT - BAR_HEIGHT))

# --- Step 1: Render each paragraph to a temp PNG ---
PARAGRAPHS=("$P1" "$P2" "$P3" "$P4")
PARA_FILES=()
PARA_HEIGHTS=()

for i in "${!PARAGRAPHS[@]}"; do
  txt="${PARAGRAPHS[$i]}"
  [ -z "$txt" ] && continue
  f="$TMPDIR/p${i}.png"
  magick -size ${TEXT_WIDTH}x -background none \
    -font "$DINA" -pointsize 22 -fill "$TEXT_COLOR" -interline-spacing 6 \
    caption:"$txt" "$f"
  h=$(magick identify -format "%h" "$f")
  PARA_FILES+=("$f")
  PARA_HEIGHTS+=("$h")
done

# --- Step 2: Create canvas with title, divider, attribution, bar ---
TITLE_Y=120
DIVIDER_Y=150

magick -size ${WIDTH}x${HEIGHT} xc:"$BG" \
  -font "$DIN" -pointsize 72 -fill "$ACCENT" \
  -annotate +${TEXT_X}+${TITLE_Y} "$TITLE" \
  -stroke "$DIVIDER" -strokewidth 1 \
  -draw "line ${TEXT_X},${DIVIDER_Y} 2020,${DIVIDER_Y}" \
  -stroke none \
  -fill "$ACCENT" -draw "rectangle 0,${BAR_TOP} ${WIDTH},${HEIGHT}" \
  -font "$DIN" -pointsize 14 -fill "$BG" \
  -gravity south -annotate +0+10 "$BAR_TEXT" \
  "$TMPDIR/canvas.png"

# --- Step 3: Composite paragraphs onto canvas ---
CURRENT_Y=190
PARA_GAP=10
cp "$TMPDIR/canvas.png" "$TMPDIR/build.png"

for i in "${!PARA_FILES[@]}"; do
  magick "$TMPDIR/build.png" \
    "${PARA_FILES[$i]}" -gravity northwest -geometry +${TEXT_X}+${CURRENT_Y} -composite \
    "$TMPDIR/build.png"
  CURRENT_Y=$((CURRENT_Y + PARA_HEIGHTS[$i] + PARA_GAP))
done

# Attribution
ATTR_Y=$((CURRENT_Y + 30))
magick "$TMPDIR/build.png" \
  -font "$DIN" -pointsize 18 -fill "$MUTED" \
  -annotate +${TEXT_X}+${ATTR_Y} "$ATTRIBUTION" \
  "$TMPDIR/build.png"

# --- Step 4: Prepare image with right-edge fade ---
magick "$IMAGE" \
  -resize x${BAR_TOP}^ -gravity center -extent ${IMG_WIDTH}x${BAR_TOP} \
  \( -size ${IMG_WIDTH}x${BAR_TOP} xc:white \
     \( -size ${FADE_WIDTH}x${BAR_TOP} gradient:white-black \) \
     -gravity east -composite \
  \) -alpha off -compose CopyOpacity -composite \
  "$TMPDIR/image.png"

# --- Step 5: Composite image onto poster ---
magick "$TMPDIR/build.png" \
  "$TMPDIR/image.png" -gravity northwest -geometry +0+0 -compose over -composite \
  "$OUTPUT"

echo "Saved: $OUTPUT"
