#!/usr/bin/env bash
# Gmail skill - search, read, send, label via gog CLI
# Usage: bash gmail.sh <command> [args...]
# Requires: gog (gogcli) with gmail OAuth per account

set -euo pipefail

GOG="gog"
DEFAULT_ACCOUNT="chi@sazabi.pl"
ACCOUNTS=("chi@sazabi.pl" "adam.ladachowski@gmail.com")

usage() {
  cat <<'EOF'
Gmail Skill Commands:

  Search
    search <query> [-a account] [--max N]     Search threads (Gmail query syntax)
    search-all <query> [--max N]              Search ALL accounts in parallel

  Read
    read <threadId> [-a account]              Read thread (plain text)
    read-full <threadId> [-a account]         Read thread with full bodies
    attachments <threadId> [-a account]       List attachments in thread

  Write
    send [-a account] --to <addr> --subject <subj> --body <text>
    reply <threadId> [-a account] --body <text>

  Organize
    labels [-a account]                       List labels
    archive <threadId> [-a account]           Archive thread
    trash <threadId> [-a account]             Trash thread
    mark-read <threadId> [-a account]         Mark as read
    unread <threadId> [-a account]            Mark as unread

  Info
    accounts                                  List configured accounts

Options:
    -a <email>     Target account (default: chi@sazabi.pl)
    --max <N>      Max results for search (default: 10)
    --json         Output JSON instead of plain text

Gmail query syntax examples:
    from:linkedin subject:engineer
    newer_than:7d is:unread
    has:attachment filename:pdf
    "exact phrase"
    from:recruiter@example.com OR from:hr@example.com
EOF
}

# Parse global flags before command
ACCOUNT="$DEFAULT_ACCOUNT"
OUTPUT_FLAG="-p"
MAX=10
CMD="${1:-help}"
shift 2>/dev/null || true

# Collect remaining args, extracting our flags
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -a|--account)
      ACCOUNT="$2"
      shift 2
      ;;
    --json)
      OUTPUT_FLAG="-j"
      shift
      ;;
    --max)
      MAX="$2"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

gog_gmail() {
  $GOG gmail "$@" -a "$ACCOUNT" $OUTPUT_FLAG
}

case "$CMD" in
  search)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh search <query> [-a account] [--max N]"
      exit 1
    fi
    query="${ARGS[*]}"
    $GOG gmail search -a "$ACCOUNT" $OUTPUT_FLAG --max "$MAX" "$query"
    ;;

  search-all)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh search-all <query> [--max N]"
      exit 1
    fi
    query="${ARGS[*]}"
    for acct in "${ACCOUNTS[@]}"; do
      echo "=== $acct ==="
      $GOG gmail search -a "$acct" $OUTPUT_FLAG --max "$MAX" "$query" 2>&1 || echo "  (no results or not authed)"
      echo ""
    done
    ;;

  read)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh read <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail thread get -a "$ACCOUNT" $OUTPUT_FLAG "${ARGS[0]}"
    ;;

  read-full)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh read-full <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail thread get -a "$ACCOUNT" $OUTPUT_FLAG --full "${ARGS[0]}"
    ;;

  attachments)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh attachments <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail thread attachments -a "$ACCOUNT" $OUTPUT_FLAG "${ARGS[0]}"
    ;;

  send)
    # Pass all args through to gog gmail send
    $GOG gmail send -a "$ACCOUNT" "${ARGS[@]}"
    ;;

  reply)
    if [ ${#ARGS[@]} -lt 1 ]; then
      echo "Usage: gmail.sh reply <threadId> [-a account] --body <text>"
      exit 1
    fi
    thread_id="${ARGS[0]}"
    remaining=("${ARGS[@]:1}")
    $GOG gmail send -a "$ACCOUNT" --thread-id "$thread_id" --reply-all --quote "${remaining[@]}"
    ;;

  labels)
    $GOG gmail labels list -a "$ACCOUNT" $OUTPUT_FLAG
    ;;

  archive)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh archive <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail archive -a "$ACCOUNT" "${ARGS[0]}"
    echo "Archived: ${ARGS[0]}"
    ;;

  trash)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh trash <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail trash -a "$ACCOUNT" -y "${ARGS[0]}"
    echo "Trashed: ${ARGS[0]}"
    ;;

  mark-read)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh mark-read <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail mark-read -a "$ACCOUNT" "${ARGS[0]}"
    echo "Marked read: ${ARGS[0]}"
    ;;

  unread)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gmail.sh unread <threadId> [-a account]"
      exit 1
    fi
    $GOG gmail unread -a "$ACCOUNT" "${ARGS[0]}"
    echo "Marked unread: ${ARGS[0]}"
    ;;

  accounts)
    echo "Configured accounts:"
    for acct in "${ACCOUNTS[@]}"; do
      marker=" "
      [ "$acct" = "$DEFAULT_ACCOUNT" ] && marker="*"
      echo "  $marker $acct"
    done
    echo ""
    echo "* = default"
    ;;

  help|--help|-h|*)
    usage
    ;;
esac
