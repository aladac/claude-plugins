---
name: cf:del-host
description: Delete DNS record from Cloudflare zone
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
  - AskUserQuestion
arguments:
  - name: zone
    description: Domain name (e.g., example.com)
    required: true
  - name: record-id
    description: DNS record ID (get from /cf:zone-info)
    required: true
---

# Delete DNS Record

Delete a DNS record from a Cloudflare zone.

## Standing Restrictions

- NEVER delete a DNS record without first presenting the record details (name, type, value) via AskUserQuestion and receiving explicit approval.

## Execution Flow

1. **Present record for confirmation**:
   Show the record to be deleted via AskUserQuestion (name, type, value). Only proceed after explicit approval.

2. **Create task with spinner**:
   ```
   TaskCreate(subject: "Delete DNS record", activeForm: "Deleting DNS record...")
   ```

3. **Execute command**:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/commands/cf/del-host.sh <zone> <record-id>
   ```

4. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show deletion confirmation

## Example

User: `/cf:del-host tengu.host abc123`

Claude shows spinner: "Deleting DNS record..."
Then:

```
DNS record deleted

Zone: tengu.host
Record ID: abc123
```

## Related
- **Skill**: `Skill(skill: "marauder:cloudflare")` - Cloudflare operations
- **Skill**: `Skill(skill: "marauder:pretty-output")` - Output guidelines
- **Agent**: `marauder:devops-cf` - Cloudflare infrastructure
- **Commands**: `/cf:add-host`, `/cf:zone-info`
