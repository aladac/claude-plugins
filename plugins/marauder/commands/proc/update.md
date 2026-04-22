---
name: proc:update
description: "Update an existing operational procedure"
allowed-tools:
  - Bash
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
argument-hint: "<P number> <new content>"
---

# Update Procedure

Modify the content of an existing operational procedure. Uses forget + re-store to replace.

## Arguments

- `P number` - The procedure number to update (e.g., `P03`, `3`)
- `new content` - The new procedure text (Title — Description)

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Update procedure", activeForm: "Updating procedure...")
   ```

2. **Find the existing procedure**:
   ```bash
   marauder memory search --subject "procedure.P03" --limit 1 --json
   ```

3. **Present old vs new for approval** (MANDATORY — never skip):
   Use AskUserQuestion to show the current text and proposed new text side by side.
   Wait for explicit approval. Do NOT delete or store until the Pilot confirms.

4. **Delete the old version**:
   ```bash
   marauder memory forget <ID>
   ```

5. **Store the approved version**:
   ```bash
   marauder memory store "procedure.P03" "New Title — New description content"
   ```

6. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show old vs new content.

## Examples

- `/proc:update P03 Cross-Machine Sync — After any git push, pull on the other machine. Include NAS sync for shared assets.`
- `/proc:update 7 Visor as Dashboard — Use the HUD for visual feedback. Prefer code and image endpoints over log spam.`

## Rules

- If the procedure doesn't exist, ask if the Pilot wants to create it instead
- Show old content before replacing so the Pilot can confirm
- Preserve the subject `procedure.P{N}` exactly
- If no new content provided, ask what to change

## Related
- **Commands**: `/proc`, `/proc:show`, `/proc:add`
