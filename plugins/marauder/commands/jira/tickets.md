---
name: jira:tickets
description: List my Jira tickets in the current sprint
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
---

# Jira — My Tickets

List tickets assigned to me in the current sprint.

## Execution Flow

1. **Create task**:
   ```
   TaskCreate(subject: "Jira: my tickets", activeForm: "Fetching sprint tickets...")
   ```

2. **Fetch tickets**:
   ```bash
   hu jira tickets
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Present as a table: KEY | Summary | Status | Priority
