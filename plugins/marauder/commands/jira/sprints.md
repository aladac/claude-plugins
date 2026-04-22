---
name: jira:sprints
description: List sprints (active, future, closed)
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
---

# Jira — Sprints

List all sprints — active, future, and recently closed.

## Execution Flow

1. **Create task**:
   ```
   TaskCreate(subject: "Jira: sprints", activeForm: "Fetching sprints...")
   ```

2. **Fetch sprints**:
   ```bash
   hu jira sprints
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Present as a table: Name | State | Start | End
