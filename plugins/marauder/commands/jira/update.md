---
name: jira:update
description: "Update a Jira ticket. Usage: /jira:update <KEY> [field] [value]"
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
---

# Jira — Update Ticket

Update a Jira ticket's summary, status, assignee, or description.

## Arguments

The user must provide a ticket key (e.g. `HU-42`) and what to change. If not provided, ask.

## Execution Flow

### Step 1 — Read current state (REQUIRED)

**Always fetch the ticket first.** Never overwrite without reading.

```bash
hu jira show <KEY>
```

Display the current state to the Pilot. Confirm the intended change.

### Step 2 — Apply the update

```
TaskCreate(subject: "Jira: update <KEY>", activeForm: "Updating...")
```

Run the appropriate update command:

```bash
# Change status
hu jira update <KEY> --status "In Progress"

# Change summary/title
hu jira update <KEY> --summary "New title"

# Assign to self
hu jira update <KEY> --assign me

# Replace description (CAUTION: full replace)
hu jira update <KEY> --body "New description"
```

### Step 3 — Confirm

```bash
hu jira show <KEY>
```

Show the updated ticket to confirm the change landed.

```
TaskUpdate(taskId: "...", status: "completed")
```

## Safety Note

`--body` **replaces** the entire description. When updating description, always show the current content first and confirm with the Pilot before proceeding.
