#!/usr/bin/env bash
set -euo pipefail

# Cross-machine gem wrapper (Homebrew-installed Ruby)
# Usage: gem.sh <target> <gem-args...>
# Targets: local, fuji, junkpile, both
#
# For running gem-installed executables, use:
#   gem.sh <target> exec <executable> [args...]

FUJI_GEM="/opt/homebrew/opt/ruby/bin/gem"
FUJI_GEMBIN="/opt/homebrew/lib/ruby/gems/4.0.0/bin"
JUNKPILE_GEM="/home/linuxbrew/.linuxbrew/opt/ruby/bin/gem"
JUNKPILE_GEMBIN="/home/linuxbrew/.linuxbrew/lib/ruby/gems/4.0.0/bin"

HOSTNAME="$(hostname)"
TARGET="${1:-local}"
shift || { echo "Usage: gem.sh <local|fuji|junkpile|both> <gem-args...>"; exit 1; }

if [[ $# -eq 0 ]]; then
    echo "Usage: gem.sh <local|fuji|junkpile|both> <gem-args...>"
    echo "       gem.sh <target> exec <executable> [args...]"
    exit 1
fi

run_fuji() {
    local subcmd="$1"
    if [[ "$subcmd" == "exec" ]]; then
        shift
        local exe="$1"; shift
        if [[ "$HOSTNAME" == "fuji" ]]; then
            "$FUJI_GEMBIN/$exe" "$@"
        else
            ssh f "$FUJI_GEMBIN/$exe $*"
        fi
    else
        if [[ "$HOSTNAME" == "fuji" ]]; then
            "$FUJI_GEM" "$@"
        else
            ssh f "$FUJI_GEM $*"
        fi
    fi
}

run_junkpile() {
    local subcmd="$1"
    if [[ "$subcmd" == "exec" ]]; then
        shift
        local exe="$1"; shift
        if [[ "$HOSTNAME" == "junkpile" ]]; then
            "$JUNKPILE_GEMBIN/$exe" "$@"
        else
            ssh j "$JUNKPILE_GEMBIN/$exe $*"
        fi
    else
        if [[ "$HOSTNAME" == "junkpile" ]]; then
            "$JUNKPILE_GEM" "$@"
        else
            ssh j "$JUNKPILE_GEM $*"
        fi
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
