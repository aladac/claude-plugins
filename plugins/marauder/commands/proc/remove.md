---
name: proc:remove
description: "Remove an existing operational procedure"
allowed-tools:
  - Bash
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
argument-hint: "<P number>"
---

# Remove Procedure

Delete an operational procedure permanently. Requires explicit Pilot approval.

## Arguments

- `P number` - The procedure number to remove (e.g., `P03`, `3`)

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Remove procedure", activeForm: "Loading procedure...")
   ```

2. **Find the procedure**:
   ```bash
   marauder memory search --subject "procedure.P03" --limit 1 --json
   ```
   (Normalize input: `3`, `03`, `P3`, `P03` all resolve to `procedure.P03`)

3. **Present for approval** (MANDATORY — never skip):
   Use AskUserQuestion to show the full procedure content and confirm deletion.
   Wait for explicit approval. Do NOT delete until the Pilot confirms.

4. **Delete the procedure**:
   ```bash
   marauder memory forget <ID>
   ```

5. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Confirm which procedure was removed. Do NOT renumber remaining procedures.

## Rules

- NEVER delete without explicit Pilot approval via AskUserQuestion
- If the procedure doesn't exist, say so
- Do NOT renumber remaining procedures after deletion — gaps are fine
- Read-only until approval is granted

## Related
- **Commands**: `/proc`, `/proc:show`, `/proc:update`, `/proc:add`
