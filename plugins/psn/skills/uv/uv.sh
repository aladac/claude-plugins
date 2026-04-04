#!/usr/bin/env bash
set -euo pipefail

# Cross-machine uv wrapper
# Usage: uv.sh <target> <uv-args...>
# Targets: local, fuji, junkpile, both

FUJI_UV="/opt/homebrew/bin/uv"
JUNKPILE_UV="/home/chi/.local/bin/uv"

HOSTNAME="$(hostname)"
TARGET="${1:-local}"
shift || { echo "Usage: uv.sh <local|fuji|junkpile|both> <uv-args...>"; exit 1; }

if [[ $# -eq 0 ]]; then
    echo "Usage: uv.sh <local|fuji|junkpile|both> <uv-args...>"
    exit 1
fi

run_fuji() {
    if [[ "$HOSTNAME" == "fuji" ]]; then
        "$FUJI_UV" "$@"
    else
        ssh f "$FUJI_UV $*"
    fi
}

run_junkpile() {
    if [[ "$HOSTNAME" == "junkpile" ]]; then
        "$JUNKPILE_UV" "$@"
    else
        ssh j "$JUNKPILE_UV $*"
    fi
}

if [[ "$TARGET" == "local" ]]; then
    case "$HOSTNAME" in
        fuji)     TARGET="fuji" ;;
        junkpile) TARGET="junkpile" ;;
        *)        echo "Unknown host: $HOSTNAME" >&2; exit 1 ;;
    esac
fi

case "$TARGET" in
    fuji)
        run_fuji "$@"
        ;;
    junkpile)
        run_junkpile "$@"
        ;;
    both)
        echo "=== [fuji] ==="
        run_fuji "$@" || echo "[fuji] failed with exit code $?"
        echo ""
        echo "=== [junkpile] ==="
        run_junkpile "$@" || echo "[junkpile] failed with exit code $?"
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Valid targets: local, fuji, junkpile, both"
        exit 1
        ;;
esac
