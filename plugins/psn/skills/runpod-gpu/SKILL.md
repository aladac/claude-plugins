---
name: RunPod GPU
description: |
  List available GPU types, pricing, and datacenter availability on RunPod. Use before creating pods to find the right GPU at the best price.

  <example>
  Context: User wants to know what GPUs are available
  user: "what GPUs can I get on runpod?"
  </example>

  <example>
  Context: User wants to find cheap GPUs for training
  user: "find me the cheapest A100 on runpod"
  </example>
---

# RunPod GPU Skill

Query GPU availability and datacenter info on RunPod.

## Usage

```bash
bash ~/Projects/personality-plugin/skills/runpod-gpu/runpod-gpu.sh <action> [args...]
```

### Actions

| Action | Args | Description |
|--------|------|-------------|
| `list` | | List all available GPU types with pricing |
| `datacenters` | | List all datacenters and availability |
| `search` | `<query>` | Filter GPUs by name (grep) |

### Examples

```bash
# List all available GPUs
bash ~/Projects/personality-plugin/skills/runpod-gpu/runpod-gpu.sh list

# List datacenters
bash ~/Projects/personality-plugin/skills/runpod-gpu/runpod-gpu.sh datacenters

# Find A40 pricing
bash ~/Projects/personality-plugin/skills/runpod-gpu/runpod-gpu.sh search A40

# Find A100 options
bash ~/Projects/personality-plugin/skills/runpod-gpu/runpod-gpu.sh search A100
```
