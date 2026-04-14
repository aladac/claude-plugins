---
name: Things 3
description: |
  Manage Things 3 todos from the terminal. Read via SQLite, write via URL scheme. No focus steal, no dependencies.

  <example>
  Context: User wants to add a task
  user: "Add a todo to check backup logs"
  </example>

  <example>
  Context: User wants to see today's tasks
  user: "What's on my Things today?"
  </example>

  <example>
  Context: User wants to search tasks
  user: "Find all psn tagged todos"
  </example>
version: 1.0.0
---

# Things 3 Skill

Manage Things 3 todos. Read from SQLite database, write via URL scheme (silent, no focus steal).

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/things/things.sh"

# Read
bash $SKILL today                    # Today's todos
bash $SKILL inbox                    # Inbox
bash $SKILL upcoming                 # Upcoming
bash $SKILL projects                 # All projects
bash $SKILL search "query"           # Search by title/notes
bash $SKILL tags                     # List all tags
bash $SKILL project "Project Name"   # Todos in a project

# Write (silent, no focus)
bash $SKILL add "Task title"                          # Add to inbox
bash $SKILL add "Task title" --when today             # Add to today
bash $SKILL add "Task title" --when tomorrow          # Add to tomorrow
bash $SKILL add "Task title" --tags psn               # Add with tag
bash $SKILL add "Task title" --when today --tags psn --notes "Details here"
bash $SKILL add "Task title" --project "Project Name" --when today
bash $SKILL add "Task title" --checklist "item1,item2,item3"

# Modify
bash $SKILL complete <id>            # Mark complete
bash $SKILL show <id>                # Show full details
```
