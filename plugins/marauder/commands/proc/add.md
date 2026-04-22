---
name: proc:add
description: "Add a new operational procedure"
allowed-tools:
  - Bash
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
argument-hint: "<content>"
---

# Add Procedure

Add a new operational procedure to the list.

## Arguments

- `content` - The procedure text in format: `Title — Description`

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Add procedure", activeForm: "Adding procedure...")
   ```

2. **Determine next number**:
   ```bash
   marauder memory search --subject "procedure.P" --limit 20 --json
   ```
   Parse existing subjects to find the highest P number, then increment.

3. **Present for approval** (MANDATORY — never skip):
   Use AskUserQuestion to show the exact text that will be stored:
   ```
   P{N}: Title — Description
   ```
   Wait for explicit approval. Do NOT store until the Pilot confirms.
   Procedures are standing orders — they govern behavior. No storing without sign-off.

4. **Store the approved procedure**:
   ```bash
   marauder memory store "procedure.P{N}" "Title — Description"
   ```

5. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show: "Added P{N}: Title"

## Examples

- `/proc:add Check Disk Space — Before large operations (Docker builds, model downloads), verify sufficient disk space on the target machine.`
- `/proc:add Signal on Long Tasks — Send a Signal message to the Pilot when tasks exceeding 5 minutes complete.`

## Rules

- Auto-assign the next sequential number (P11, P12, etc.)
- If the Pilot specifies a number, use it (and warn if it already exists)
- Use two-digit zero-padded format for consistency (P01, P02, ..., P11)
- If no content provided, ask what the procedure should be
- **NEVER store without Pilot approval** — this is a hard gate, not a suggestion. Procedures change behavior permanently

## Related
- **Commands**: `/proc`, `/proc:show`, `/proc:update`
