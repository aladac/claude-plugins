---
name: jira:sprint
description: Show all issues in the current sprint
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
---

# Jira — Sprint Board

Show all issues in the current active sprint.

## Execution Flow

1. **Create task**:
   ```
   TaskCreate(subject: "Jira: sprint board", activeForm: "Loading sprint...")
   ```

2. **Fetch sprint**:
   ```bash
   hu jira sprint
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Present as a table grouped by status: KEY | Assignee | Summary | Priority
