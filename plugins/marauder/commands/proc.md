---
name: proc
description: "List all operational procedures"
allowed-tools:
  - Bash
  - TaskCreate
  - TaskUpdate
---

# Operational Procedures

List all operational procedures (standing orders) from the DB.

## Execution Flow

1. **Create task with spinner**:
   ```
   TaskCreate(subject: "List procedures", activeForm: "Loading procedures...")
   ```

2. **Query all procedures**:
   ```bash
   marauder memory search --subject "procedure.P" --limit 20
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Render as a clean table:

   ```
   | # | Procedure | Summary |
   |---|-----------|---------|
   | P01 | Verify Before Acting | Never assume current state... |
   | P02 | Terse by Default | No trailing summaries... |
   ```

## Rules

- Show ALL procedures, sorted by number
- Extract the title (text before the em dash `—`) and summary (text after) from each entry
- If no procedures exist, say so
- Do NOT modify anything — this is read-only

## Related
- **Skill**: `Skill(skill: "marauder:procedures")` - Full procedures guide
- **Commands**: `/proc:show`, `/proc:update`, `/proc:add`
