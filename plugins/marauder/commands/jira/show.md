---
name: jira:show
description: "Show Jira ticket details. Usage: /jira:show <KEY> (e.g. HU-42)"
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
---

# Jira — Show Ticket

Show full details for a Jira ticket by key.

## Arguments

The user must provide a ticket key (e.g. `HU-42`). If not provided, ask for it.

## Execution Flow

1. **Create task**:
   ```
   TaskCreate(subject: "Jira: show <KEY>", activeForm: "Fetching ticket...")
   ```

2. **Fetch ticket**:
   ```bash
   hu jira show <KEY>
   ```

3. **Complete and display**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Present: Key, Summary, Status, Priority, Assignee, Reporter, Description, Labels, Sprint.
