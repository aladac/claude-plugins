#!/usr/bin/env bash
# Cloudflare environment check — verifies CLI tools, credentials, and API access
# on both fuji (local) and junkpile (remote) in one pass.
#
# Usage: bash cf-check.sh [machine]
#   no args  — check both fuji and junkpile
#   local    — check fuji only
#   remote   — check junkpile only
set -uo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
BREW_BIN_J="/home/linuxbrew/.linuxbrew/bin"
BREW_BIN_F="/opt/homebrew/bin"
CRED_FILE="$HOME/.config/cloudflare/credentials"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CF_SCRIPT="$SCRIPT_DIR/cf.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

pass() { printf "  ${GREEN}%-14s${RESET} %s\n" "$1" "$2"; }
fail() { printf "  ${RED}%-14s${RESET} %s\n" "$1" "$2"; }
warn() { printf "  ${YELLOW}%-14s${RESET} %s\n" "$1" "$2"; }
header() { printf "\n${BOLD}${CYAN}── %s${RESET}\n" "$1"; }

ERRORS=0

# ── Local check (fuji) ─────────────────────────────────────────────────────

check_local() {
  header "fuji ($(hostname))"

  # Tools
  for tool in flarectl cloudflared wrangler; do
    local path
    path="$(command -v "$tool" 2>/dev/null || true)"
    if [[ -n "$path" ]]; then
      local ver
      ver="$("$tool" --version 2>&1 | head -1 | sed 's/.*version //' | sed 's/ .*//')"
      pass "$tool" "$path ($ver)"
    else
      fail "$tool" "NOT FOUND"
      ((ERRORS++))
    fi
  done

  # cf.sh
  if [[ -x "$CF_SCRIPT" ]]; then
    pass "cf.sh" "$CF_SCRIPT"
  elif [[ -f "$CF_SCRIPT" ]]; then
    warn "cf.sh" "$CF_SCRIPT (not executable)"
  else
    fail "cf.sh" "NOT FOUND"
    ((ERRORS++))
  fi

  # Credentials
  local creds_found=0
  if [[ -f "$CRED_FILE" ]]; then
    source "$CRED_FILE" 2>/dev/null
    export CF_API_KEY="${CF_API_KEY:-${CLOUDFLARE_API_KEY:-}}"
    export CF_API_EMAIL="${CF_API_EMAIL:-${CLOUDFLARE_EMAIL:-}}"
    if [[ -n "${CF_API_KEY:-}" && -n "${CF_API_EMAIL:-}" ]]; then
      pass "credentials" "$CRED_FILE"
      creds_found=1
    else
      warn "credentials" "$CRED_FILE (missing keys)"
    fi
  fi
  if [[ "$creds_found" -eq 0 ]] && [[ -n "${CF_API_KEY:-}" && -n "${CF_API_EMAIL:-}" ]]; then
    pass "credentials" "environment variables"
    creds_found=1
  fi
  if [[ "$creds_found" -eq 0 ]] && command -v op &>/dev/null; then
    local key
    key="$(op item get cf --vault DEV --fields api_key 2>/dev/null || true)"
    if [[ -n "$key" ]]; then
      pass "credentials" "1Password (DEV/cf)"
      creds_found=1
    fi
  fi
  if [[ "$creds_found" -eq 0 ]]; then
    warn "credentials" "no file/env/1Password (flarectl may use its own config)"
  fi

  # Tunnels
  local tunnel_count
  tunnel_count="$(cloudflared tunnel list 2>/dev/null | tail -n +2 | grep -c '[a-f0-9-]' || echo 0)"
  if [[ "$tunnel_count" -gt 0 ]]; then
    pass "tunnels" "$tunnel_count configured"
  else
    warn "tunnels" "none or cert.pem missing"
  fi

  # API test via flarectl
  if command -v flarectl &>/dev/null; then
    # Load creds for the test
    if [[ -f "$CRED_FILE" ]]; then
      source "$CRED_FILE" 2>/dev/null
      export CF_API_KEY="${CF_API_KEY:-${CLOUDFLARE_API_KEY:-}}"
      export CF_API_EMAIL="${CF_API_EMAIL:-${CLOUDFLARE_EMAIL:-}}"
    fi
    local api_result
    api_result="$(flarectl user info 2>&1 || true)"
    if echo "$api_result" | grep -qi "email\|id"; then
      pass "api access" "verified via flarectl"
    else
      fail "api access" "flarectl user info failed"
      ((ERRORS++))
    fi
  fi

  # Zones (quick count)
  if command -v flarectl &>/dev/null && [[ -n "${CF_API_KEY:-}" ]]; then
    local zone_count
    zone_count="$(flarectl zone list 2>/dev/null | grep -c '|' || echo 0)"
    if [[ "$zone_count" -gt 0 ]]; then
      pass "zones" "$zone_count accessible"
    else
      fail "zones" "none returned"
      ((ERRORS++))
    fi
  fi
}

# ── Remote check (junkpile) ────────────────────────────────────────────────

check_remote() {
  header "junkpile (remote)"

  # Check SSH first
  if ! ssh -T j "echo ok" &>/dev/null; then
    fail "ssh" "cannot reach junkpile"
    ((ERRORS++))
    return
  fi
  pass "ssh" "connected"

  # Run the checks remotely in one SSH call
  local remote_output
  remote_output="$(ssh -T j "bash -s" <<'REMOTE_SCRIPT'
export PATH="/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:$PATH"
CRED_FILE="$HOME/.config/cloudflare/credentials"
CF_SCRIPT="$HOME/Projects/personality-plugin/skills/cloudflare/cf.sh"

# Tools
for tool in flarectl cloudflared wrangler; do
  path="$(command -v "$tool" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then
    ver="$("$tool" --version 2>&1 | head -1 | sed 's/.*version //' | sed 's/ .*//')"
    echo "PASS|$tool|$path ($ver)"
  else
    echo "FAIL|$tool|NOT FOUND"
  fi
done

# cf.sh
if [[ -x "$CF_SCRIPT" ]]; then
  echo "PASS|cf.sh|$CF_SCRIPT"
elif [[ -f "$CF_SCRIPT" ]]; then
  echo "WARN|cf.sh|$CF_SCRIPT (not executable)"
else
  echo "FAIL|cf.sh|NOT FOUND"
fi

# Credentials
if [[ -f "$CRED_FILE" ]]; then
  source "$CRED_FILE" 2>/dev/null
  if [[ -n "${CF_API_KEY:-}${CLOUDFLARE_API_KEY:-}" && -n "${CF_API_EMAIL:-}${CLOUDFLARE_EMAIL:-}" ]]; then
    echo "PASS|credentials|$CRED_FILE"
  else
    echo "FAIL|credentials|$CRED_FILE (missing keys)"
  fi
else
  echo "FAIL|credentials|no file found"
fi

# Map creds for flarectl
if [[ -f "$CRED_FILE" ]]; then
  source "$CRED_FILE" 2>/dev/null
  export CF_API_KEY="${CF_API_KEY:-${CLOUDFLARE_API_KEY:-}}"
  export CF_API_EMAIL="${CF_API_EMAIL:-${CLOUDFLARE_EMAIL:-}}"
fi

# Running tunnels
tunnel_pids="$(pgrep -c cloudflared 2>/dev/null || echo 0)"
if [[ "$tunnel_pids" -gt 0 ]]; then
  echo "PASS|tunnels|$tunnel_pids process(es) running"
else
  echo "WARN|tunnels|no processes running"
fi

# API test
if command -v flarectl &>/dev/null && [[ -n "${CF_API_KEY:-}" ]]; then
  api_result="$(flarectl user info 2>&1 || true)"
  if echo "$api_result" | grep -qi "email\|id"; then
    echo "PASS|api access|verified via flarectl"
  else
    echo "FAIL|api access|flarectl user info failed"
  fi
fi

# Zone count
if command -v flarectl &>/dev/null && [[ -n "${CF_API_KEY:-}" ]]; then
  zone_count="$(flarectl zone list 2>/dev/null | grep -c '|' || echo 0)"
  if [[ "$zone_count" -gt 0 ]]; then
    echo "PASS|zones|$zone_count accessible"
  else
    echo "FAIL|zones|none returned"
  fi
fi
REMOTE_SCRIPT
)" 2>/dev/null

  # Parse and display remote results
  while IFS='|' read -r status label detail; do
    case "$status" in
      PASS) pass "$label" "$detail" ;;
      FAIL) fail "$label" "$detail"; ((ERRORS++)) ;;
      WARN) warn "$label" "$detail" ;;
    esac
  done <<< "$remote_output"
}

# ── Main ────────────────────────────────────────────────────────────────────

target="${1:-both}"

printf "${BOLD}Cloudflare Environment Check${RESET}\n"

case "$target" in
  local|fuji|f)   check_local ;;
  remote|junkpile|j) check_remote ;;
  both|all|"")    check_local; check_remote ;;
  *)              echo "Usage: cf-check.sh [local|remote|both]"; exit 1 ;;
esac

# Summary
echo ""
if [[ "$ERRORS" -eq 0 ]]; then
  printf "${GREEN}${BOLD}All checks passed.${RESET}\n"
else
  printf "${RED}${BOLD}%d issue(s) found.${RESET}\n" "$ERRORS"
fi
exit "$ERRORS"
