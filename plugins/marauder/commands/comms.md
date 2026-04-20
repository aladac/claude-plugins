---
name: comms
description: "List all comms rules (brevity codes and shortcuts)"
allowed-tools:
  - Bash
  - TaskCreate
  - TaskUpdate
---

# Comms Rules

List all comms rules (brevity codes, prowords, shortcuts) from the DB.

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "List comms rules", activeForm: "Loading comms rules...")
   ```

2. **Query all comms rules**:
   ```bash
   marauder memory search --subject "comms.C" --limit 25
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Render as a quick reference table:

   ```
   | # | Term | Shortcut | Meaning |
   |---|------|----------|---------|
   | C01 | NATO PHONETIC | — | Spell via NATO alphabet over TTS |
   | C02 | WILCO | w | Will comply, executing |
   ```

## Rules

- Show ALL comms rules, sorted by number
- Extract the term, shortcut, and meaning from each entry
- If no comms rules exist, say so
- Do NOT modify anything — this is read-only

## Related
- **Skill**: `Skill(skill: "marauder:comms")` - Full comms rules guide
- **Commands**: `/comms:show`, `/comms:update`, `/comms:add`
