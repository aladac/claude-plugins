#!/usr/bin/env bash
set -euo pipefail

# RunPod pod lifecycle management
# Usage: runpod.sh <action> [args...]

RUNPODCTL="runpodctl"

action="${1:-help}"
shift || true

case "$action" in
  list)
    $RUNPODCTL pod list --output=table "$@"
    ;;

  list-all)
    $RUNPODCTL pod list --all --output=table "$@"
    ;;

  get)
    pod_id="${1:?Pod ID required}"
    shift
    $RUNPODCTL pod get "$pod_id" "$@"
    ;;

  create)
    name="" gpu="" image="" gpu_count="1" disk="20" volume="50"
    volume_path="/runpod" mem="20" ports="" env_vars=() ssh=false
    community=false secure=false cost=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --name)       name="$2"; shift 2 ;;
        --gpu)        gpu="$2"; shift 2 ;;
        --image)      image="$2"; shift 2 ;;
        --gpu-count)  gpu_count="$2"; shift 2 ;;
        --disk)       disk="$2"; shift 2 ;;
        --volume)     volume="$2"; shift 2 ;;
        --volume-path) volume_path="$2"; shift 2 ;;
        --mem)        mem="$2"; shift 2 ;;
        --ports)      ports="$2"; shift 2 ;;
        --env)        env_vars+=("$2"); shift 2 ;;
        --ssh)        ssh=true; shift ;;
        --community)  community=true; shift ;;
        --secure)     secure=true; shift ;;
        --cost)       cost="$2"; shift 2 ;;
        *)            echo "Unknown flag: $1"; exit 1 ;;
      esac
    done

    [[ -z "$name" ]] && echo "Error: --name required" && exit 1
    [[ -z "$gpu" ]] && echo "Error: --gpu required" && exit 1
    [[ -z "$image" ]] && echo "Error: --image required" && exit 1

    cmd=($RUNPODCTL pod create)
    cmd+=(--name "$name")
    cmd+=(--gpuType "$gpu")
    cmd+=(--imageName "$image")
    cmd+=(--gpuCount "$gpu_count")
    cmd+=(--containerDiskSize "$disk")
    cmd+=(--volumeSize "$volume")
    cmd+=(--volumePath "$volume_path")
    cmd+=(--mem "$mem")

    [[ -n "$ports" ]] && cmd+=(--ports "$ports")
    for ev in "${env_vars[@]+"${env_vars[@]}"}"; do
      cmd+=(--env "$ev")
    done
    [[ "$ssh" == true ]] && cmd+=(--startSSH)
    [[ "$community" == true ]] && cmd+=(--communityCloud)
    [[ "$secure" == true ]] && cmd+=(--secureCloud)
    [[ -n "$cost" ]] && cmd+=(--cost "$cost")

    "${cmd[@]}"
    ;;

  start)
    pod_id="${1:?Pod ID required}"
    shift
    $RUNPODCTL pod start "$pod_id" "$@"
    ;;

  start-spot)
    pod_id="${1:?Pod ID required}"
    shift
    $RUNPODCTL pod start "$pod_id" "$@"
    ;;

  stop)
    pod_id="${1:?Pod ID required}"
    $RUNPODCTL pod stop "$pod_id"
    ;;

  destroy)
    pod_id="${1:?Pod ID required}"
    $RUNPODCTL pod delete "$pod_id"
    ;;

  help|*)
    cat <<'EOF'
RunPod pod lifecycle management

Usage: runpod.sh <action> [args...]

Actions:
  list                    List running pods
  list-all                List all pods (including stopped)
  get <pod-id>            Get pod details
  create --name --gpu --image [flags]  Create a new pod
  start <pod-id>          Start a stopped pod
  start-spot <pod-id> --bid <price>    Start as spot instance
  stop <pod-id>           Stop a pod (preserves data)
  destroy <pod-id>        Destroy a pod (permanent)

Create flags:
  --name        Pod name (required)
  --gpu         GPU type, e.g. "NVIDIA A40" (required)
  --image       Docker image (required)
  --gpu-count   Number of GPUs (default: 1)
  --disk        Container disk in GB (default: 20)
  --volume      Persistent volume in GB (default: 50)
  --volume-path Volume mount path (default: /runpod)
  --mem         Min RAM in GB (default: 20)
  --ports       Exposed ports, e.g. "8888/http"
  --env         Environment variable (KEY=VALUE), repeatable
  --ssh         Enable SSH access
  --community   Use community cloud
  --secure      Use secure cloud
  --cost        Max $/hr price ceiling
EOF
    ;;
esac
