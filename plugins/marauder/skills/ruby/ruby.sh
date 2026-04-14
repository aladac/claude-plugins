#!/usr/bin/env bash
set -euo pipefail

# Cross-machine ruby wrapper (Homebrew-installed)
# Usage: ruby.sh <target> <ruby-args...>
# Targets: local, fuji, junkpile, both

FUJI_RUBY="/opt/homebrew/opt/ruby/bin/ruby"
JUNKPILE_RUBY="/home/linuxbrew/.linuxbrew/opt/ruby/bin/ruby"

HOSTNAME="$(hostname)"
TARGET="${1:-local}"
shift || { echo "Usage: ruby.sh <local|fuji|junkpile|both> <ruby-args...>"; exit 1; }

if [[ $# -eq 0 ]]; then
    echo "Usage: ruby.sh <local|fuji|junkpile|both> <ruby-args...>"
    exit 1
fi

run_fuji() {
    if [[ "$HOSTNAME" == "fuji" ]]; then
        "$FUJI_RUBY" "$@"
    else
        ssh f "$FUJI_RUBY $*"
    fi
}

run_junkpile() {
    if [[ "$HOSTNAME" == "junkpile" ]]; then
        "$JUNKPILE_RUBY" "$@"
    else
        ssh j "$JUNKPILE_RUBY $*"
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
