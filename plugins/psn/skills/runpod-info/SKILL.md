---
name: RunPod Info
description: |
  RunPod account info, balance, and billing. Check spend, balance, and billing history before and after training runs.

  <example>
  Context: User wants to check their RunPod balance
  user: "how much do I have left on runpod?"
  </example>

  <example>
  Context: User wants billing details
  user: "show me runpod billing history"
  </example>
---

# RunPod Info Skill

Account info, balance, and billing on RunPod.

## Usage

```bash
bash ~/Projects/personality-plugin/skills/runpod-info/runpod-info.sh <action>
```

### Actions

| Action | Description |
|--------|-------------|
| `account` | Show account info and balance |
| `billing` | Show billing history |
| `balance` | Show balance only (short) |

### Examples

```bash
# Full account info
bash ~/Projects/personality-plugin/skills/runpod-info/runpod-info.sh account

# Check balance
bash ~/Projects/personality-plugin/skills/runpod-info/runpod-info.sh balance

# Billing history
bash ~/Projects/personality-plugin/skills/runpod-info/runpod-info.sh billing
```
