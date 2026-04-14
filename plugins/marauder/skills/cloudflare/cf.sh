#!/usr/bin/env bash
# Cloudflare skill — unified CLI for zones, DNS, tunnels, pages, workers
# Usage: bash cf.sh <module> <command> [args...]
#
# CLI tools used:
#   flarectl   — DNS records, zones (requires CF_API_KEY + CF_API_EMAIL env vars)
#   cloudflared — Tunnel management (requires ~/.cloudflared/cert.pem)
#   wrangler   — Pages + Workers (requires CLOUDFLARE_ACCOUNT_ID env var)
#
# NEVER use curl + CF API directly. All operations go through CLI tools.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED_FILE="$HOME/.config/cloudflare/credentials"

# ── Auth ──────────────────────────────────────────────────────────────────────

load_credentials() {
  # flarectl uses CF_API_KEY + CF_API_EMAIL
  # wrangler uses CLOUDFLARE_ACCOUNT_ID
  # Ensure both sets are exported

  # 1. Already set in env
  if [[ -n "${CF_API_KEY:-}" && -n "${CF_API_EMAIL:-}" ]]; then
    export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-95ad3baa2a4ecda1e38342df7d24204f}"
    return 0
  fi

  # Also accept CLOUDFLARE_API_KEY/CLOUDFLARE_EMAIL and map them
  if [[ -n "${CLOUDFLARE_API_KEY:-}" && -n "${CLOUDFLARE_EMAIL:-}" ]]; then
    export CF_API_KEY="$CLOUDFLARE_API_KEY"
    export CF_API_EMAIL="$CLOUDFLARE_EMAIL"
    export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-95ad3baa2a4ecda1e38342df7d24204f}"
    return 0
  fi

  # 2. Config file
  if [[ -f "$CRED_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CRED_FILE"
    # Map CLOUDFLARE_ vars to CF_ vars for flarectl
    if [[ -n "${CLOUDFLARE_API_KEY:-}" && -n "${CLOUDFLARE_EMAIL:-}" ]]; then
      export CF_API_KEY="${CF_API_KEY:-$CLOUDFLARE_API_KEY}"
      export CF_API_EMAIL="${CF_API_EMAIL:-$CLOUDFLARE_EMAIL}"
      export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-95ad3baa2a4ecda1e38342df7d24204f}"
      return 0
    fi
    if [[ -n "${CF_API_KEY:-}" && -n "${CF_API_EMAIL:-}" ]]; then
      export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-95ad3baa2a4ecda1e38342df7d24204f}"
      return 0
    fi
  fi

  # 3. 1Password
  if command -v op &>/dev/null; then
    local api_key email account_id
    api_key="$(op item get cf --vault DEV --fields api_key 2>/dev/null || true)"
    email="$(op item get cf --vault DEV --fields email 2>/dev/null || true)"
    account_id="$(op item get cf --vault DEV --fields account_id 2>/dev/null || true)"
    if [[ -n "$api_key" && -n "$email" ]]; then
      export CF_API_KEY="$api_key"
      export CF_API_EMAIL="$email"
      export CLOUDFLARE_ACCOUNT_ID="${account_id:-95ad3baa2a4ecda1e38342df7d24204f}"
      return 0
    fi
  fi

  echo "ERROR: No Cloudflare credentials found." >&2
  echo "Run: bash cf.sh auth setup" >&2
  echo "Needed: CF_API_KEY + CF_API_EMAIL (for flarectl)" >&2
  return 1
}

# ── Module: auth ──────────────────────────────────────────────────────────────

cmd_auth() {
  local action="${1:-help}"
  shift 2>/dev/null || true

  case "$action" in
    setup)
      mkdir -p "$(dirname "$CRED_FILE")"
      echo "Cloudflare credential setup"
      echo "Enter your Global API Key (from https://dash.cloudflare.com/profile/api-tokens):"
      read -r api_key
      echo "Enter your account email:"
      read -r email
      echo "Enter your account ID [95ad3baa2a4ecda1e38342df7d24204f]:"
      read -r account_id
      account_id="${account_id:-95ad3baa2a4ecda1e38342df7d24204f}"

      cat > "$CRED_FILE" <<EOF
# Cloudflare credentials
# CF_API_KEY / CF_API_EMAIL — used by flarectl
# CLOUDFLARE_* variants — used by wrangler and cf.sh
CF_API_KEY="$api_key"
CF_API_EMAIL="$email"
CLOUDFLARE_API_KEY="$api_key"
CLOUDFLARE_EMAIL="$email"
CLOUDFLARE_ACCOUNT_ID="$account_id"
EOF
      chmod 600 "$CRED_FILE"
      echo "Credentials saved to $CRED_FILE"
      ;;

    test)
      load_credentials
      echo "Testing credentials with flarectl..."
      if flarectl user info 2>/dev/null | head -5; then
        echo "OK — flarectl authenticated"
      else
        echo "FAILED — check CF_API_KEY and CF_API_EMAIL"
        return 1
      fi
      ;;

    show)
      if [[ -f "$CRED_FILE" ]]; then
        echo "Credentials file: $CRED_FILE"
        echo "Email: $(grep CF_API_EMAIL "$CRED_FILE" | head -1 | cut -d'"' -f2)"
        echo "Account ID: $(grep CLOUDFLARE_ACCOUNT_ID "$CRED_FILE" | head -1 | cut -d'"' -f2)"
        echo "API Key: $(grep CF_API_KEY "$CRED_FILE" | head -1 | cut -d'"' -f2 | head -c8)..."
      else
        echo "No credentials file at $CRED_FILE"
        echo ""
        echo "Checking env vars:"
        [[ -n "${CF_API_KEY:-}" ]] && echo "  CF_API_KEY: set" || echo "  CF_API_KEY: not set"
        [[ -n "${CF_API_EMAIL:-}" ]] && echo "  CF_API_EMAIL: set" || echo "  CF_API_EMAIL: not set"
        [[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]] && echo "  CLOUDFLARE_ACCOUNT_ID: set" || echo "  CLOUDFLARE_ACCOUNT_ID: not set"
      fi
      ;;

    *)
      cat <<EOF
auth commands:
  setup    Interactive credential setup (saves to $CRED_FILE)
  test     Verify credentials work (uses flarectl)
  show     Show stored credential info
EOF
      ;;
  esac
}

# ── Module: zones ─────────────────────────────────────────────────────────────
# Tool: flarectl

cmd_zones() {
  load_credentials
  local action="${1:-list}"
  shift 2>/dev/null || true

  case "$action" in
    list)
      flarectl zone list
      ;;

    info)
      local domain="${1:-}"
      if [[ -z "$domain" ]]; then
        echo "Usage: cf.sh zones info <domain>" >&2; return 1
      fi
      flarectl zone info --zone "$domain"
      ;;

    *)
      cat <<EOF
zones commands:  (tool: flarectl)
  list              List all zones
  info <domain>     Show zone details
EOF
      ;;
  esac
}

# ── Module: dns ───────────────────────────────────────────────────────────────
# Tool: flarectl

cmd_dns() {
  load_credentials
  local action="${1:-help}"
  shift 2>/dev/null || true

  case "$action" in
    list)
      local domain="${1:-}"
      if [[ -z "$domain" ]]; then
        echo "Usage: cf.sh dns list <domain>" >&2; return 1
      fi
      flarectl dns list --zone "$domain"
      ;;

    add)
      local domain="${1:-}" type="${2:-}" name="${3:-}" content="${4:-}" proxy="${5:-false}"
      if [[ -z "$domain" || -z "$type" || -z "$name" || -z "$content" ]]; then
        echo "Usage: cf.sh dns add <domain> <type> <name> <content> [true|false]" >&2
        echo "  type: A, AAAA, CNAME, TXT, MX" >&2
        echo "  name: subdomain or @ for root" >&2
        echo "  proxy: true (orange cloud) or false (default, gray)" >&2
        return 1
      fi

      local proxy_flag=""
      if [[ "$proxy" == "true" || "$proxy" == "yes" || "$proxy" == "--proxy" ]]; then
        proxy_flag="--proxy"
      fi

      flarectl dns create \
        --zone "$domain" \
        --type "$type" \
        --name "$name" \
        --content "$content" \
        $proxy_flag

      echo ""
      echo "Verifying record..."
      flarectl dns list --zone "$domain" --name "$name" 2>/dev/null || true
      ;;

    del|delete)
      local domain="${1:-}" record_id="${2:-}"
      if [[ -z "$domain" || -z "$record_id" ]]; then
        echo "Usage: cf.sh dns del <domain> <record-id>" >&2
        echo "  Get record IDs with: cf.sh dns list <domain>" >&2
        return 1
      fi
      flarectl dns delete --zone "$domain" --id "$record_id"
      echo "Deleted record: $record_id"
      ;;

    find)
      # Find a record by name — flarectl --name requires FQDN
      local domain="${1:-}" name="${2:-}"
      if [[ -z "$domain" || -z "$name" ]]; then
        echo "Usage: cf.sh dns find <domain> <name>" >&2; return 1
      fi
      # If name already contains the domain, use as-is; otherwise append domain
      if [[ "$name" == *"$domain"* ]]; then
        flarectl dns list --zone "$domain" --name "$name"
      else
        flarectl dns list --zone "$domain" --name "${name}.${domain}"
      fi
      ;;

    *)
      cat <<EOF
dns commands:  (tool: flarectl)
  list <domain>                                 List all DNS records
  add <domain> <type> <name> <content> [proxy]  Create record (proxy: true/false)
  del <domain> <record-id>                      Delete record by ID
  find <domain> <name>                          Find record by name
EOF
      ;;
  esac
}

# ── Module: tunnels ───────────────────────────────────────────────────────────
# Tool: cloudflared

# Determine where cloudflared runs (local or SSH to target)
run_cloudflared() {
  local target="${CF_TUNNEL_HOST:-local}"
  if [[ "$target" == "local" ]]; then
    target="$(hostname)"
  fi
  case "$target" in
    fuji)
      if [[ "$(hostname)" == "fuji" ]]; then
        cloudflared "$@"
      else
        ssh f "cloudflared $*"
      fi
      ;;
    junkpile)
      if [[ "$(hostname)" == "junkpile" ]]; then
        cloudflared "$@"
      else
        ssh j "cloudflared $*"
      fi
      ;;
    *)
      cloudflared "$@"
      ;;
  esac
}

cmd_tunnels() {
  local action="${1:-help}"
  shift 2>/dev/null || true

  case "$action" in
    list)
      local target="${1:-local}"
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel list
      ;;

    info)
      local name="${1:-}" target="${2:-local}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh tunnels info <name> [host]" >&2; return 1
      fi
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel info "$name"
      ;;

    create)
      local name="${1:-}" target="${2:-local}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh tunnels create <name> [host]" >&2; return 1
      fi
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel create "$name"
      ;;

    delete)
      local name="${1:-}" target="${2:-local}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh tunnels delete <name> [host]" >&2; return 1
      fi
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel cleanup "$name" 2>/dev/null || true
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel delete "$name"
      ;;

    route)
      local tunnel="${1:-}" hostname="${2:-}" target="${3:-local}"
      if [[ -z "$tunnel" || -z "$hostname" ]]; then
        echo "Usage: cf.sh tunnels route <tunnel-name> <hostname> [host]" >&2; return 1
      fi
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel route dns "$tunnel" "$hostname"
      ;;

    config)
      # Show tunnel config on a host
      local target="${1:-local}"
      local host
      host="$(hostname)"
      if [[ "$target" == "local" ]]; then target="$host"; fi

      local config_path
      case "$target" in
        fuji)     config_path="$HOME/.cloudflared/config.yml" ;;
        junkpile) config_path="/home/chi/.cloudflared/config.yml" ;;
        *)        config_path="$HOME/.cloudflared/config.yml" ;;
      esac

      if [[ "$target" == "$host" ]]; then
        cat "$config_path" 2>/dev/null || echo "No config at $config_path"
      else
        case "$target" in
          fuji)     ssh f "cat $config_path" 2>/dev/null || echo "No config" ;;
          junkpile) ssh j "cat $config_path" 2>/dev/null || echo "No config" ;;
        esac
      fi
      ;;

    expose)
      # Quick expose: create tunnel + route DNS + add ingress for localhost:port
      local port="${1:-}" hostname="${2:-}" tunnel_name="${3:-}"
      local target="${4:-local}"
      if [[ -z "$port" || -z "$hostname" ]]; then
        echo "Usage: cf.sh tunnels expose <port> <hostname> [tunnel-name] [host]" >&2
        echo "" >&2
        echo "Creates a tunnel exposing localhost:<port> at <hostname>" >&2
        echo "If tunnel-name is omitted, derives from hostname" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  cf.sh tunnels expose 3000 app.saiden.dev" >&2
        echo "  cf.sh tunnels expose 8080 api.saiden.dev my-api-tunnel" >&2
        echo "  cf.sh tunnels expose 3000 app.saiden.dev '' junkpile" >&2
        return 1
      fi

      # Derive tunnel name from hostname if not given
      if [[ -z "$tunnel_name" ]]; then
        tunnel_name="$(echo "$hostname" | sed 's/\./-/g')"
      fi

      echo "==> Creating tunnel: $tunnel_name"
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel create "$tunnel_name" 2>&1 || true

      echo "==> Routing DNS: $hostname -> $tunnel_name"
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel route dns "$tunnel_name" "$hostname" 2>&1 || true

      echo ""
      echo "==> Tunnel created. Add this ingress to your cloudflared config:"
      echo ""
      echo "  - hostname: $hostname"
      echo "    service: http://localhost:$port"
      echo ""
      echo "Then run: cloudflared tunnel run $tunnel_name"
      echo ""
      echo "Or run inline (no config edit needed):"
      echo "  cloudflared tunnel --url http://localhost:$port run $tunnel_name"
      ;;

    expose-ssh)
      # Expose a service on a remote host via tunnel on that host
      local ssh_host="${1:-}" port="${2:-}" hostname="${3:-}" tunnel_name="${4:-}"
      if [[ -z "$ssh_host" || -z "$port" || -z "$hostname" ]]; then
        echo "Usage: cf.sh tunnels expose-ssh <ssh-host> <port> <hostname> [tunnel-name]" >&2
        echo "" >&2
        echo "Creates a tunnel on <ssh-host> exposing <ssh-host>:<port> at <hostname>" >&2
        echo "The tunnel runs on the remote host (cloudflared must be installed there)" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  cf.sh tunnels expose-ssh junkpile 8080 api.saiden.dev" >&2
        echo "  cf.sh tunnels expose-ssh junkpile 3000 app.tengu.to my-app" >&2
        return 1
      fi

      if [[ -z "$tunnel_name" ]]; then
        tunnel_name="$(echo "$hostname" | sed 's/\./-/g')"
      fi

      # Resolve SSH alias to target name
      local target
      case "$ssh_host" in
        j|junkpile) target="junkpile" ;;
        f|fuji)     target="fuji" ;;
        *)          target="$ssh_host" ;;
      esac

      echo "==> Creating tunnel '$tunnel_name' on $target"
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel create "$tunnel_name" 2>&1 || true

      echo "==> Routing DNS: $hostname -> $tunnel_name"
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel route dns "$tunnel_name" "$hostname" 2>&1 || true

      echo ""
      echo "==> Tunnel created on $target. Add this ingress to cloudflared config on $target:"
      echo ""
      echo "  - hostname: $hostname"
      echo "    service: http://localhost:$port"
      echo ""
      echo "Then on $target run: cloudflared tunnel run $tunnel_name"
      echo ""
      echo "Or run inline:"
      if [[ "$target" == "junkpile" ]]; then
        echo "  ssh j \"cloudflared tunnel --url http://localhost:$port run $tunnel_name\""
      elif [[ "$target" == "fuji" ]]; then
        echo "  ssh f \"cloudflared tunnel --url http://localhost:$port run $tunnel_name\""
      else
        echo "  ssh $ssh_host \"cloudflared tunnel --url http://localhost:$port run $tunnel_name\""
      fi
      ;;

    ingress-add)
      # Add an ingress rule to a remote cloudflared config
      local hostname="${1:-}" service="${2:-}" target="${3:-local}"
      if [[ -z "$hostname" || -z "$service" ]]; then
        echo "Usage: cf.sh tunnels ingress-add <hostname> <service-url> [host]" >&2
        echo "  Adds an ingress rule BEFORE the catch-all in cloudflared config" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  cf.sh tunnels ingress-add app.saiden.dev http://localhost:3000 junkpile" >&2
        return 1
      fi

      local host
      host="$(hostname)"
      if [[ "$target" == "local" ]]; then target="$host"; fi

      local rule="  - hostname: $hostname\n    service: $service"

      # Insert before the catch-all line
      if [[ "$target" == "$host" ]]; then
        local config="$HOME/.cloudflared/config.yml"
        if [[ ! -f "$config" ]]; then
          echo "No config at $config" >&2; return 1
        fi
        # Insert before "  - service: http_status:404"
        if grep -q "$hostname" "$config"; then
          echo "Ingress for $hostname already exists in $config"
        else
          sed -i.bak "/- service: http_status:404/i\\
\\  - hostname: $hostname\\
\\    service: $service" "$config"
          echo "Added ingress: $hostname -> $service"
          echo "Config: $config"
        fi
      else
        local config
        case "$target" in
          junkpile) config="/home/chi/.cloudflared/config.yml" ;;
          fuji)     config="$HOME/.cloudflared/config.yml" ;;
          *)        echo "Unknown target: $target" >&2; return 1 ;;
        esac
        local ssh_alias
        case "$target" in
          junkpile) ssh_alias="j" ;;
          fuji)     ssh_alias="f" ;;
        esac

        if ssh "$ssh_alias" "grep -q '$hostname' '$config'"; then
          echo "Ingress for $hostname already exists on $target"
        else
          ssh "$ssh_alias" "sed -i.bak '/- service: http_status:404/i\\
\\  - hostname: $hostname\\
\\    service: $service' '$config'"
          echo "Added ingress on $target: $hostname -> $service"
          echo "Config: $config"
        fi
      fi
      ;;

    run)
      local name="${1:-}" target="${2:-local}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh tunnels run <name> [host]" >&2; return 1
      fi
      CF_TUNNEL_HOST="$target" run_cloudflared tunnel run "$name"
      ;;

    *)
      cat <<EOF
tunnels commands:  (tool: cloudflared)
  list [host]                                          List tunnels (host: local/fuji/junkpile)
  info <name> [host]                                   Tunnel details
  create <name> [host]                                 Create tunnel
  delete <name> [host]                                 Delete tunnel
  route <tunnel> <hostname> [host]                     Route DNS to tunnel
  config [host]                                        Show cloudflared config
  expose <port> <hostname> [name] [host]               Quick: localhost:port -> hostname
  expose-ssh <ssh-host> <port> <hostname> [name]       Quick: remote:port -> hostname
  ingress-add <hostname> <service-url> [host]          Add ingress rule to config
  run <name> [host]                                    Run tunnel

  [host] defaults to local machine. Use 'fuji' or 'junkpile' for remote.
EOF
      ;;
  esac
}

# ── Module: pages ─────────────────────────────────────────────────────────────
# Tool: wrangler

cmd_pages() {
  load_credentials
  export CLOUDFLARE_ACCOUNT_ID
  local action="${1:-help}"
  shift 2>/dev/null || true

  case "$action" in
    list)
      wrangler pages project list 2>&1
      ;;

    deploy)
      local dir="${1:-}" project="${2:-}" branch="${3:-main}"
      if [[ -z "$dir" || -z "$project" ]]; then
        echo "Usage: cf.sh pages deploy <dir> <project> [branch]" >&2; return 1
      fi
      wrangler pages deploy "$dir" --project-name="$project" --branch="$branch" 2>&1
      ;;

    destroy)
      local project="${1:-}"
      if [[ -z "$project" ]]; then
        echo "Usage: cf.sh pages destroy <project>" >&2; return 1
      fi
      echo "Deleting Pages project: $project"
      wrangler pages project delete "$project" --yes 2>&1
      ;;

    *)
      cat <<EOF
pages commands:  (tool: wrangler)
  list                              List Pages projects
  deploy <dir> <project> [branch]   Deploy to Pages (branch default: main)
  destroy <project>                 Delete Pages project
EOF
      ;;
  esac
}

# ── Module: workers ───────────────────────────────────────────────────────────
# Tool: wrangler

cmd_workers() {
  local action="${1:-help}"
  shift 2>/dev/null || true

  case "$action" in
    list)
      load_credentials
      export CLOUDFLARE_ACCOUNT_ID
      wrangler deployments list 2>&1
      ;;

    info)
      local name="${1:-}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh workers info <name>" >&2; return 1
      fi
      load_credentials
      export CLOUDFLARE_ACCOUNT_ID
      echo "=== Worker: $name ==="
      wrangler deployments list --name "$name" 2>&1 || echo "No deployments found"
      echo ""
      echo "To tail live logs: wrangler tail $name"
      ;;

    deploy)
      local dir="${1:-.}"
      (cd "$dir" && wrangler deploy 2>&1)
      ;;

    dev)
      local dir="${1:-.}"
      (cd "$dir" && wrangler dev 2>&1)
      ;;

    tail)
      local name="${1:-}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh workers tail <name>" >&2; return 1
      fi
      wrangler tail "$name" 2>&1
      ;;

    delete)
      local name="${1:-}"
      if [[ -z "$name" ]]; then
        echo "Usage: cf.sh workers delete <name>" >&2; return 1
      fi
      echo "Deleting worker: $name"
      wrangler delete --name "$name" --yes 2>&1
      ;;

    *)
      cat <<EOF
workers commands:  (tool: wrangler)
  list                 List all workers
  info <name>          Worker details
  deploy [dir]         Deploy worker (default: current dir)
  dev [dir]            Run worker locally
  tail <name>          Tail worker logs
  delete <name>        Delete worker
EOF
      ;;
  esac
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

MODULE="${1:-help}"
shift 2>/dev/null || true

case "$MODULE" in
  auth)     cmd_auth "$@" ;;
  zones)    cmd_zones "$@" ;;
  dns)      cmd_dns "$@" ;;
  tunnels)  cmd_tunnels "$@" ;;
  pages)    cmd_pages "$@" ;;
  workers)  cmd_workers "$@" ;;
  help|*)
    cat <<EOF
Cloudflare Skill -- cf.sh

Usage: bash cf.sh <module> <command> [args...]

Modules:
  auth       Credential setup and testing
  zones      Zone management via flarectl (list, info)
  dns        DNS records via flarectl (list, add, del, find)
  tunnels    Tunnel management via cloudflared (list, create, expose, expose-ssh, ingress-add)
  pages      Pages deployment via wrangler (list, deploy, destroy)
  workers    Worker management via wrangler (list, deploy, tail, delete)

CLI tools:
  flarectl    DNS records, zones      (env: CF_API_KEY + CF_API_EMAIL)
  cloudflared Tunnels                 (cert: ~/.cloudflared/cert.pem)
  wrangler    Pages, Workers          (env: CLOUDFLARE_ACCOUNT_ID)

Run 'bash cf.sh <module>' for module-specific help.

Credentials: env vars > ~/.config/cloudflare/credentials > 1Password
Setup: bash cf.sh auth setup
EOF
    ;;
esac
