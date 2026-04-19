#!/bin/bash
# Create a new Cloudflare Tunnel
set -euo pipefail

NAME="${1:?Usage: add-tunnel.sh <name>}"

echo "Creating tunnel: $NAME"
cloudflared tunnel create "$NAME"

echo ""
echo "Next steps:"
echo "1. Configure ~/.cloudflared/config.yml with ingress rules"
echo "2. Route DNS: flarectl dns create --zone <zone> --type CNAME --name <sub> --content <tunnel-id>.cfargotunnel.com --proxy"
echo "   WARNING: Do NOT use 'cloudflared tunnel route dns' — it picks the wrong zone on multi-zone accounts"
echo "3. Run tunnel: cloudflared tunnel run $NAME"
