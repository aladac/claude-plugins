#!/usr/bin/env bash
set -euo pipefail

# RunPod account info and billing
# Usage: runpod-info.sh <action>

RUNPODCTL="runpodctl"

action="${1:-help}"

case "$action" in
  account)
    $RUNPODCTL user
    ;;

  balance)
    balance=$($RUNPODCTL user 2>&1 | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"Balance: \${d['clientBalance']:.2f} | Spend/hr: \${d['currentSpendPerHr']:.2f} | Limit: \${d['spendLimit']}\")")
    echo "$balance"
    ;;

  billing)
    $RUNPODCTL billing --output=table
    ;;

  help|*)
    cat <<'EOF'
RunPod account info and billing

Usage: runpod-info.sh <action>

Actions:
  account     Full account info (JSON)
  balance     Balance summary (one line)
  billing     Billing history (table)
EOF
    ;;
esac
