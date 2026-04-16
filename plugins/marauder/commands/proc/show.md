---
name: proc:show
description: "Show expanded detail for a specific procedure"
allowed-tools:
  - Bash
  - TaskCreate
  - TaskUpdate
argument-hint: "<P number>"
---

# Show Procedure

Display the full content of a specific operational procedure.

## Arguments

- `P number` - The procedure number (e.g., `P03`, `3`, `03`)

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Show procedure", activeForm: "Loading procedure...")
   ```

2. **Query the procedure**:
   ```bash
   marauder memory search --subject "procedure.P03" --limit 1
   ```
   (Normalize input: `3`, `03`, `P3`, `P03` all resolve to `procedure.P03`)

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show full content with the DB ID for reference.

## Examples

- `/proc:show P03` - Show procedure 3
- `/proc:show 7` - Show procedure 7

## Rules

- If the procedure doesn't exist, say so
- Show the DB memory ID alongside the content (useful for updates)
- Read-only — does not modify anything

## Related
- **Commands**: `/proc`, `/proc:update`, `/proc:add`
