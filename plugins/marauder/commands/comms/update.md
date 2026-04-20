---
name: comms:update
description: "Update an existing comms rule"
allowed-tools:
  - Bash
  - TaskCreate
  - TaskUpdate
argument-hint: "<C number> <new content>"
---

# Update Comms Rule

Modify the content of an existing comms rule. Uses forget + re-store to replace.

## Arguments

- `C number` - The rule number to update (e.g., `C05`, `5`)
- `new content` - The new rule text

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Update comms rule", activeForm: "Updating comms rule...")
   ```

2. **Find the existing rule**:
   ```bash
   marauder memory search --subject "comms.C05" --limit 1 --json
   ```

3. **Delete the old version**:
   ```bash
   marauder memory forget <ID>
   ```

4. **Store the new version**:
   ```bash
   marauder memory store "comms.C05" "New content"
   ```

5. **Update master index and agent memory mirror**:
   - Update `comms.index` in DB
   - Update `~/.claude/agent-memory/marauder-core/comms_rules.md`

6. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show old vs new content.

## Examples

- `/comms:update C16 EXECUTE — "xx" — Run now, double-tap shortcut for emphasis`
- `/comms:update 2 WILCO — "w" — Will comply, executing. Also means "go ahead" from Pilot`

## Rules

- If the rule doesn't exist, ask if the Pilot wants to create it instead
- Show old content before replacing
- Preserve the subject `comms.C{N}` exactly
- Always update all three locations: DB entry, master index, agent memory mirror

## Related
- **Commands**: `/comms`, `/comms:show`, `/comms:add`
