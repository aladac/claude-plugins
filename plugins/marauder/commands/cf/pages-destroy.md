---
name: cf:pages-destroy
description: Delete a Cloudflare Pages project
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
  - AskUserQuestion
arguments:
  - name: project
    description: Pages project name
    required: true
---

# Delete Pages Project

Delete a Cloudflare Pages project.

## Standing Restrictions

- NEVER destroy a Pages project without presenting project name and deployment count via AskUserQuestion and receiving explicit approval.
- This is permanent and irreversible.

## Execution Flow

1. **Present project for confirmation**:
   Show the project name and deployment count via AskUserQuestion. Emphasize this action is permanent and irreversible. Only proceed after approval.

2. **Create task with spinner**:
   ```
   TaskCreate(subject: "Delete Pages project", activeForm: "Deleting Pages project...")
   ```

3. **Execute command**:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/commands/cf/pages-destroy.sh <project>
   ```

4. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show deletion confirmation

## Example

User: `/cf:pages-destroy old-site`

Claude shows spinner: "Deleting Pages project..."
Then: `Pages project deleted: old-site`

## Related
- **Skill**: `Skill(skill: "marauder:cloudflare")` - Cloudflare operations
- **Skill**: `Skill(skill: "marauder:pretty-output")` - Output guidelines
- **Agent**: `marauder:devops-cf` - Cloudflare infrastructure
- **Commands**: `/cf:pages-list`, `/cf:pages-deploy`
