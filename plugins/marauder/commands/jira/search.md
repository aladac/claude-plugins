---
name: jira:search
description: "Search Jira tickets using JQL. Usage: /jira:search <JQL query>"
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
---

# Jira — Search

Search tickets using JQL (Jira Query Language).

## Arguments

The user must provide a JQL query string. If not provided, ask for it.

## Execution Flow

1. **Create task**:
   ```
   TaskCreate(subject: "Jira: search", activeForm: "Searching...")
   ```

2. **Execute search**:
   ```bash
   hu jira search "<JQL query>"
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Present as a table: KEY | Summary | Status | Assignee | Priority

## Common JQL Examples

```
project = HU AND status = "To Do"
assignee = currentUser() AND sprint in openSprints()
priority = High AND status != Done
text ~ "auth" AND project = HU
```
