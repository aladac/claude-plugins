#!/usr/bin/env bash
# Protocol 5 — Backup Verification
# Thin wrapper — delegates to marauder backup CLI.
# Usage: bash protocol5.sh [status|destinations|run|help]

cmd="${1:-status}"

case "$cmd" in
  status|s)
    exec marauder backup status
    ;;
  destinations|d)
    exec marauder backup destinations
    ;;
  run|r)
    shift
    exec marauder backup run "$@"
    ;;
  help|h|*)
    echo "protocol5.sh — Protocol 5 Backup Verification"
    echo ""
    echo "  status (s)        Full verification of all destinations (default)"
    echo "  destinations (d)  List all backup destinations"
    echo "  run (r)           Execute backup"
    echo "  help (h)          This message"
    ;;
esac
