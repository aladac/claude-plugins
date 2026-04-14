#!/usr/bin/env bash
# Google Calendar skill - events, create, search via gog CLI
# Usage: bash gcal.sh <command> [args...]
# Requires: gog (gogcli) with calendar OAuth per account

set -euo pipefail

GOG="gog"
DEFAULT_ACCOUNT="chi@sazabi.pl"
ACCOUNTS=("chi@sazabi.pl" "adam.ladachowski@gmail.com")

usage() {
  cat <<'EOF'
Google Calendar Skill Commands:

  View
    today [-a account] [--all]                Today's events
    tomorrow [-a account] [--all]             Tomorrow's events
    week [-a account] [--all]                 This week's events
    next <N> [-a account] [--all]             Next N days of events
    agenda [-a account]                       Next 7 days, all calendars
    today-all                                 Today across ALL accounts
    week-all                                  This week across ALL accounts

  Query
    events [calendarId] [-a account] [flags]  List events (pass-through to gog)
    search <query> [-a account] [--today|--week|--days N]
    freebusy [-a account] --from <t> --to <t> Free/busy check

  Create & Manage
    create [-a account] --summary <title> --from <time> --to <time> [flags]
    update [-a account] <calendarId> <eventId> [flags]
    delete [-a account] <calendarId> <eventId>
    respond [-a account] <calendarId> <eventId> --status <accepted|declined|tentative>

  Info
    calendars [-a account]                    List calendars
    accounts                                  List configured accounts

Options:
    -a <email>     Target account (default: chi@sazabi.pl)
    --all          All calendars on the account
    --json         Output JSON instead of plain text
    --max <N>      Max results (default: 25)

Time formats:
    Relative: today, tomorrow, monday, tuesday, ...
    Date: 2026-04-07
    RFC3339: 2026-04-07T09:00:00+02:00
EOF
}

# Parse global flags
ACCOUNT="$DEFAULT_ACCOUNT"
OUTPUT_FLAG="-p"
ALL_CALS=""
MAX=""
CMD="${1:-help}"
shift 2>/dev/null || true

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
    --all)
      ALL_CALS="--all"
      shift
      ;;
    --max)
      MAX="--max $2"
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

cal_cmd() {
  # shellcheck disable=SC2086
  $GOG calendar "$@" -a "$ACCOUNT" $OUTPUT_FLAG $ALL_CALS $MAX
}

case "$CMD" in
  today)
    # shellcheck disable=SC2086
    $GOG calendar events -a "$ACCOUNT" $OUTPUT_FLAG ${ALL_CALS:---all} $MAX --today
    ;;

  tomorrow)
    # shellcheck disable=SC2086
    $GOG calendar events -a "$ACCOUNT" $OUTPUT_FLAG ${ALL_CALS:---all} $MAX --tomorrow
    ;;

  week)
    # shellcheck disable=SC2086
    $GOG calendar events -a "$ACCOUNT" $OUTPUT_FLAG ${ALL_CALS:---all} $MAX --week --weekday
    ;;

  next)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gcal.sh next <N> — show events for next N days"
      exit 1
    fi
    days="${ARGS[0]}"
    # shellcheck disable=SC2086
    $GOG calendar events -a "$ACCOUNT" $OUTPUT_FLAG ${ALL_CALS:---all} $MAX --days "$days" --weekday
    ;;

  agenda)
    # 7-day agenda, all calendars
    # shellcheck disable=SC2086
    $GOG calendar events -a "$ACCOUNT" $OUTPUT_FLAG --all $MAX --days 7 --weekday
    ;;

  today-all)
    for acct in "${ACCOUNTS[@]}"; do
      echo "=== $acct ==="
      # shellcheck disable=SC2086
      $GOG calendar events -a "$acct" $OUTPUT_FLAG --all $MAX --today 2>&1 || echo "  (no results or not authed)"
      echo ""
    done
    ;;

  week-all)
    for acct in "${ACCOUNTS[@]}"; do
      echo "=== $acct ==="
      # shellcheck disable=SC2086
      $GOG calendar events -a "$acct" $OUTPUT_FLAG --all $MAX --week --weekday 2>&1 || echo "  (no results or not authed)"
      echo ""
    done
    ;;

  events)
    # Pass-through to gog calendar events
    cal_cmd events "${ARGS[@]}"
    ;;

  search)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: gcal.sh search <query> [--today|--week|--days N]"
      exit 1
    fi
    query="${ARGS[0]}"
    remaining=("${ARGS[@]:1}")
    # shellcheck disable=SC2086
    $GOG calendar search -a "$ACCOUNT" $OUTPUT_FLAG $MAX "$query" "${remaining[@]+"${remaining[@]}"}"
    ;;

  freebusy)
    cal_cmd freebusy "${ARGS[@]}"
    ;;

  create)
    # shellcheck disable=SC2086
    $GOG calendar create -a "$ACCOUNT" $OUTPUT_FLAG "primary" "${ARGS[@]}"
    ;;

  update)
    if [ ${#ARGS[@]} -lt 2 ]; then
      echo "Usage: gcal.sh update <calendarId> <eventId> [flags]"
      exit 1
    fi
    # shellcheck disable=SC2086
    $GOG calendar update -a "$ACCOUNT" $OUTPUT_FLAG "${ARGS[@]}"
    ;;

  delete)
    if [ ${#ARGS[@]} -lt 2 ]; then
      echo "Usage: gcal.sh delete <calendarId> <eventId>"
      exit 1
    fi
    $GOG calendar delete -a "$ACCOUNT" -y "${ARGS[@]}"
    echo "Deleted: ${ARGS[1]}"
    ;;

  respond|rsvp)
    if [ ${#ARGS[@]} -lt 2 ]; then
      echo "Usage: gcal.sh respond <calendarId> <eventId> --status accepted|declined|tentative"
      exit 1
    fi
    $GOG calendar respond -a "$ACCOUNT" "${ARGS[@]}"
    ;;

  calendars)
    $GOG calendar calendars -a "$ACCOUNT" $OUTPUT_FLAG
    ;;

  conflicts)
    # shellcheck disable=SC2086
    $GOG calendar conflicts -a "$ACCOUNT" $OUTPUT_FLAG $MAX "${ARGS[@]}"
    ;;

  accounts)
    echo "Configured accounts:"
    for acct in "${ACCOUNTS[@]}"; do
      marker=" "
      [ "$acct" = "$DEFAULT_ACCOUNT" ] && marker="*"
      cals=$($GOG calendar calendars -a "$acct" -p 2>/dev/null | tail -n +1 | wc -l | tr -d ' ')
      echo "  $marker $acct ($cals calendars)"
    done
    echo ""
    echo "* = default"
    ;;

  help|--help|-h|*)
    usage
    ;;
esac
