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
version: 2.0.0
---

# Things 3 Skill

Manage Things 3 todos. Read from SQLite database, write via URL scheme (silent, no focus steal).

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/things/things.py"

# Read
python3 $SKILL today                    # Today's todos
python3 $SKILL inbox                    # Inbox
python3 $SKILL upcoming                 # Upcoming
python3 $SKILL projects                 # All projects
python3 $SKILL search "query"           # Search by title/notes
python3 $SKILL tags                     # List all tags
python3 $SKILL project "Project Name"   # Todos in a project
python3 $SKILL show <id>                # Show full details

# Write (silent, no focus)
python3 $SKILL add "Task title"                          # Add to inbox
python3 $SKILL add "Task title" --when today             # Add to today
python3 $SKILL add "Task title" --when tomorrow          # Add to tomorrow
python3 $SKILL add "Task title" --tags psn               # Add with tag
python3 $SKILL add "Task title" --when today --tags psn --notes "Details here"
python3 $SKILL add "Task title" --project "Project Name" --when today
python3 $SKILL add "Task title" --checklist "item1,item2,item3"

# Update existing
python3 $SKILL update <id> --notes "New notes"                       # Set notes
python3 $SKILL update <id> --when today --reminder "2026-04-15@12:00" # Set date + alarm
python3 $SKILL update <id> --append-notes "Extra info"               # Append to notes
python3 $SKILL update <id> --deadline 2026-04-20                     # Set deadline
python3 $SKILL update <id> --title "New title" --tags work           # Update title/tags

# Complete
python3 $SKILL complete <id>            # Mark complete
```
