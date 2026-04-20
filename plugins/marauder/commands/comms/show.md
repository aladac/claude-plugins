---
name: comms:show
description: "Show expanded detail for a specific comms rule"
allowed-tools:
  - Bash
  - TaskCreate
  - TaskUpdate
argument-hint: "<C number>"
---

# Show Comms Rule

Display the full content of a specific comms rule.

## Arguments

- `C number` - The rule number (e.g., `C05`, `5`, `05`)

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Show comms rule", activeForm: "Loading comms rule...")
   ```

2. **Query the rule**:
   ```bash
   marauder memory search --subject "comms.C05" --limit 1
   ```
   (Normalize input: `5`, `05`, `C5`, `C05` all resolve to `comms.C05`)

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show full content with the DB ID for reference.

## Examples

- `/comms:show C05` - Show ROGER rule
- `/comms:show 16` - Show EXECUTE rule

## Rules

- If the rule doesn't exist, say so
- Show the DB memory ID alongside the content (useful for updates)
- Read-only — does not modify anything

## Related
- **Commands**: `/comms`, `/comms:update`, `/comms:add`
