#!/usr/bin/env bash
set -euo pipefail

# Cross-machine cargo wrapper
# Usage: cargo.sh <target> <cargo-args...>
# Targets: local, fuji, junkpile, both

FUJI_CARGO="/Users/chi/.cargo/bin/cargo"
JUNKPILE_CARGO="/home/chi/.cargo/bin/cargo"

HOSTNAME="$(hostname)"
TARGET="${1:-local}"
shift || { echo "Usage: cargo.sh <local|fuji|junkpile|both> <cargo-args...>"; exit 1; }

if [[ $# -eq 0 ]]; then
    echo "Usage: cargo.sh <local|fuji|junkpile|both> <cargo-args...>"
    exit 1
fi

run_fuji() {
    if [[ "$HOSTNAME" == "fuji" ]]; then
        "$FUJI_CARGO" "$@"
    else
        ssh f "$FUJI_CARGO $*"
    fi
}

run_junkpile() {
    if [[ "$HOSTNAME" == "junkpile" ]]; then
        "$JUNKPILE_CARGO" "$@"
    else
        ssh j "$JUNKPILE_CARGO $*"
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
