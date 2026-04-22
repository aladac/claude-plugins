---
name: cf:del-tunnel
description: Delete a Cloudflare Tunnel
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
  - AskUserQuestion
arguments:
  - name: name
    description: Tunnel name or ID
    required: true
---

# Delete Cloudflare Tunnel

Delete a Cloudflare Tunnel.

## Standing Restrictions

- NEVER delete a tunnel without first presenting tunnel name and status via AskUserQuestion and receiving explicit approval.
- NEVER delete tunnels with active connections without explicit warning.

## Execution Flow

1. **Present tunnel for confirmation**:
   Show the tunnel name and status via AskUserQuestion. If the tunnel has active connections, warn explicitly. Only proceed after approval.

2. **Create task with spinner**:
   ```
   TaskCreate(subject: "Delete tunnel", activeForm: "Deleting tunnel...")
   ```

3. **Execute command**:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/commands/cf/del-tunnel.sh <name>
   ```

4. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show deletion confirmation

## Example

User: `/cf:del-tunnel my-tunnel`

Claude shows spinner: "Deleting tunnel..."
Then: `Tunnel deleted: my-tunnel`

## Related
- **Skill**: `Skill(skill: "marauder:cloudflare")` - Cloudflare operations
- **Skill**: `Skill(skill: "marauder:pretty-output")` - Output guidelines
- **Agent**: `marauder:devops-cf` - Cloudflare infrastructure
- **Commands**: `/cf:add-tunnel`, `/cf:list-tunnels`
