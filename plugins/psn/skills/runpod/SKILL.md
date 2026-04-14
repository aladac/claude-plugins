---
name: RunPod
description: |
  GPU pod lifecycle management on RunPod. Create, list, start, stop, and destroy GPU pods for training workloads (TTS voice training, LLM fine-tuning, image generation). Uses runpodctl CLI.

  <example>
  Context: User wants to spin up a GPU pod for training
  user: "create a runpod with an A40 for voice training"
  </example>

  <example>
  Context: User wants to check running pods
  user: "what pods are running on runpod?"
  </example>

  <example>
  Context: User wants to stop a pod to save money
  user: "stop the training pod"
  </example>
---

# RunPod Skill

Manages GPU pod lifecycle on RunPod via `runpodctl`.

## Usage

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/runpod/runpod.sh <action> [args...]
```

### Actions

| Action | Args | Description |
|--------|------|-------------|
| `list` | | List all pods (table format) |
| `list-all` | | List all pods including stopped |
| `get` | `<pod-id>` | Get pod details |
| `create` | `--name --gpu --image [flags]` | Create a new pod |
| `start` | `<pod-id>` | Start a stopped pod |
| `start-spot` | `<pod-id> --bid <price>` | Start as spot instance |
| `stop` | `<pod-id>` | Stop a running pod (preserves data, stops billing) |
| `destroy` | `<pod-id>` | Permanently delete a pod |

### Create Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--name` | Pod name | required |
| `--gpu` | GPU type (e.g. "NVIDIA A40") | required |
| `--image` | Docker image | required |
| `--gpu-count` | Number of GPUs | 1 |
| `--disk` | Container disk in GB | 20 |
| `--volume` | Persistent volume in GB | 50 |
| `--volume-path` | Volume mount point | /runpod |
| `--mem` | Min RAM in GB | 20 |
| `--ports` | Exposed ports (e.g. "8888/http") | |
| `--env` | Environment variables (KEY=VALUE) | |
| `--ssh` | Enable SSH access | false |
| `--community` | Use community cloud | false |
| `--secure` | Use secure cloud | false |
| `--cost` | Max $/hr ceiling | |

### Examples

```bash
# List running pods
bash ${CLAUDE_PLUGIN_ROOT}/skills/runpod/runpod.sh list

# Create a training pod with A40
bash ${CLAUDE_PLUGIN_ROOT}/skills/runpod/runpod.sh create \
  --name "bt-voice-training" \
  --gpu "NVIDIA A40" \
  --image "runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04" \
  --disk 20 --volume 100 --ssh

# Stop a pod
bash ${CLAUDE_PLUGIN_ROOT}/skills/runpod/runpod.sh stop pod_abc123

# Destroy a pod
bash ${CLAUDE_PLUGIN_ROOT}/skills/runpod/runpod.sh destroy pod_abc123
```

## Notes

- API key is configured in `~/.runpod/config.toml`
- Credentials stored in 1Password DEV vault under "runpod"
- Stopping a pod preserves data but stops compute billing
- Destroying is permanent — all data is lost
- Account: adam@saiden.pl
