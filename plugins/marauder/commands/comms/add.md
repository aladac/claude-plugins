---
name: comms:add
description: "Add a new comms rule"
allowed-tools:
  - Bash
  - TaskCreate
  - TaskUpdate
argument-hint: "<content>"
---

# Add Comms Rule

Add a new comms rule to the list.

## Arguments

- `content` - The rule text: `TERM — "shortcut" — description`

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "Add comms rule", activeForm: "Adding comms rule...")
   ```

2. **Determine next number**:
   ```bash
   marauder memory search --subject "comms.C" --limit 25 --json
   ```
   Parse existing subjects to find the highest C number, then increment.

3. **Store the new rule**:
   ```bash
   marauder memory store "comms.C{N}" "C{N}: TERM — \"shortcut\" — Description"
   ```

4. **Update master index and agent memory mirror**:
   - Update `comms.index` in DB
   - Update `~/.claude/agent-memory/marauder-core/comms_rules.md`

5. **Complete and confirm**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show: "Added C{N}: TERM (shortcut)"

## Examples

- `/comms:add MAYDAY — "md" — Emergency, all other traffic ceases`
- `/comms:add COPY — "cp" — I heard your transmission (weaker than ROGER)`

## Rules

- Auto-assign the next sequential number (C22, C23, etc.)
- Two-digit zero-padded format (C01, C02, ..., C22)
- Always update all three locations: DB entry, master index, agent memory mirror
- If no content provided, ask what the rule should be

## Related
- **Commands**: `/comms`, `/comms:show`, `/comms:update`
