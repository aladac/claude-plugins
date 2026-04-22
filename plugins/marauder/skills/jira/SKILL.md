---
name: Jira
description: |
  Manage Jira tickets via hu CLI. View sprint, search tickets, show details, update status/assignment/description.

  <example>
  Context: User asks about their tickets
  user: "What Jira tickets do I have in the current sprint?"
  </example>

  <example>
  Context: User wants to see the sprint board
  user: "Show me the full sprint"
  </example>

  <example>
  Context: User wants ticket details
  user: "Show me HU-42"
  </example>

  <example>
  Context: User wants to search
  user: "Find all open bugs in the PROJ project"
  </example>

  <example>
  Context: User wants to update a ticket
  user: "Move HU-42 to In Progress"
  </example>

  <example>
  Context: User wants to see sprints
  user: "List all active and future sprints"
  </example>
version: 1.0.0
---

# Jira Skill

Interact with Jira via the `hu` CLI. OAuth authenticated. Read-before-write enforced on all update operations.

## Quick Reference

```bash
# List my tickets in current sprint
hu jira tickets

# Full sprint board (all issues)
hu jira sprint

# List sprints (active, future, closed)
hu jira sprints

# Show ticket details
hu jira show <KEY>          # e.g. hu jira show HU-42

# Search with JQL
hu jira search "<JQL>"      # e.g. hu jira search "project = HU AND status = 'In Progress'"

# Update a ticket (ALWAYS fetch first with show)
hu jira show <KEY>          # Read current state first
hu jira update <KEY> --status "In Progress"
hu jira update <KEY> --summary "New title"
hu jira update <KEY> --assign me
hu jira update <KEY> --body "New description"
```

## Rules

- NEVER update a Jira ticket without first showing current state and confirming the intended change via AskUserQuestion.
- NEVER change ticket status, assignee, or sprint without explicit approval.

## Authentication

If `hu jira` returns an auth error, the user must run:
```bash
hu jira auth
```
This opens OAuth flow in the browser. Credentials are stored by `hu`.

## Common JQL Patterns

```
project = HU AND status = "To Do"
project = HU AND assignee = currentUser() AND sprint in openSprints()
project = HU AND priority = High AND status != Done
text ~ "keyword" AND project = HU
```
