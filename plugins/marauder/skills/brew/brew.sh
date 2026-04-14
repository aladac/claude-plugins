#!/usr/bin/env bash
set -euo pipefail

# Cross-machine Homebrew wrapper
# Usage: brew.sh <target> <brew-args...>
# Targets: local, fuji, junkpile, both

FUJI_BREW="/opt/homebrew/bin/brew"
JUNKPILE_BREW="/home/linuxbrew/.linuxbrew/bin/brew"

HOSTNAME="$(hostname)"
TARGET="${1:-local}"
shift || { echo "Usage: brew.sh <local|fuji|junkpile|both> <brew-args...>"; exit 1; }

if [[ $# -eq 0 ]]; then
    echo "Usage: brew.sh <local|fuji|junkpile|both> <brew-args...>"
    exit 1
fi

# Run brew on fuji
run_fuji() {
    if [[ "$HOSTNAME" == "fuji" ]]; then
        "$FUJI_BREW" "$@"
    else
        ssh f "$FUJI_BREW $*"
    fi
}

# Run brew on junkpile
run_junkpile() {
    if [[ "$HOSTNAME" == "junkpile" ]]; then
        "$JUNKPILE_BREW" "$@"
    else
        ssh j "$JUNKPILE_BREW $*"
    fi
}

# Resolve "local" to actual hostname
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
