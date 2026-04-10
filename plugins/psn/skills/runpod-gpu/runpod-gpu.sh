#!/usr/bin/env bash
set -euo pipefail

# RunPod GPU availability and pricing
# Usage: runpod-gpu.sh <action> [args...]

RUNPODCTL="runpodctl"

format_gpu_list() {
  python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"{'Name':<35} {'GPU ID':<35} {'VRAM':>6} {'Stock':<10} {'Community':>9} {'Secure':>6}\")
print('-' * 110)
for g in sorted(data, key=lambda x: x.get('memoryInGb', 0), reverse=True):
    name = g.get('displayName', '?')
    gid = g.get('gpuId', '?')
    mem = g.get('memoryInGb', 0)
    stock = g.get('stockStatus', '?')
    comm = 'yes' if g.get('communityCloud') else 'no'
    sec = 'yes' if g.get('secureCloud') else 'no'
    avail = g.get('available', False)
    if not avail:
        stock = 'UNAVAIL'
    print(f'{name:<35} {gid:<35} {mem:>4} GB {stock:<10} {comm:>9} {sec:>6}')
"
}

action="${1:-help}"
shift || true

case "$action" in
  list)
    $RUNPODCTL gpu list 2>&1 | format_gpu_list
    ;;

  datacenters)
    $RUNPODCTL datacenter list --output=table 2>&1 || $RUNPODCTL datacenter list 2>&1
    ;;

  search)
    query="${1:?Search query required}"
    $RUNPODCTL gpu list 2>&1 | python3 -c "
import sys, json
data = json.load(sys.stdin)
matches = [g for g in data if '${query}'.lower() in g.get('displayName','').lower() or '${query}'.lower() in g.get('gpuId','').lower()]
if not matches:
    print('No GPUs matching \"${query}\"')
    sys.exit(0)
print(f\"{'Name':<35} {'GPU ID':<35} {'VRAM':>6} {'Stock':<10} {'Community':>9} {'Secure':>6}\")
print('-' * 110)
for g in sorted(matches, key=lambda x: x.get('memoryInGb', 0), reverse=True):
    name = g.get('displayName', '?')
    gid = g.get('gpuId', '?')
    mem = g.get('memoryInGb', 0)
    stock = g.get('stockStatus', '?')
    comm = 'yes' if g.get('communityCloud') else 'no'
    sec = 'yes' if g.get('secureCloud') else 'no'
    avail = g.get('available', False)
    if not avail:
        stock = 'UNAVAIL'
    print(f'{name:<35} {gid:<35} {mem:>4} GB {stock:<10} {comm:>9} {sec:>6}')
"
    ;;

  help|*)
    cat <<'EOF'
RunPod GPU availability and pricing

Usage: runpod-gpu.sh <action> [args...]

Actions:
  list              List all available GPU types
  datacenters       List all datacenters and availability
  search <query>    Filter GPUs by name
EOF
    ;;
esac
