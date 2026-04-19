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
  user: "Find all marauder tagged todos"
  </example>

  <example>
  Context: User wants to create a project
  user: "Create a project for the website redesign"
  </example>

  <example>
  Context: User wants to move a task
  user: "Move that task to the MARAUDER project"
  </example>
version: 3.0.0
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
python3 $SKILL add "Task title" --tags marauder               # Add with tag
python3 $SKILL add "Task title" --when today --tags marauder --notes "Details here"
python3 $SKILL add "Task title" --project "Project Name" --when today
python3 $SKILL add "Task title" --checklist "item1,item2,item3"

# Update existing
python3 $SKILL update <id> --notes "New notes"                       # Set notes
python3 $SKILL update <id> --when today --reminder "2026-04-15@12:00" # Set date + alarm
python3 $SKILL update <id> --append-notes "Extra info"               # Append to notes
python3 $SKILL update <id> --deadline 2026-04-20                     # Set deadline
python3 $SKILL update <id> --title "New title" --tags work           # Update title/tags
python3 $SKILL update <id> --project "Project Name"                  # Move to project

# Move (shortcut)
python3 $SKILL move <id> "Project Name"  # Move a todo to a project

# Complete
python3 $SKILL complete <id>            # Mark complete

# Projects — Create & Update
python3 $SKILL add-project "Project Name"                            # Create empty project
python3 $SKILL add-project "Project Name" --notes "Description"      # With notes
python3 $SKILL add-project "Project Name" --deadline 2026-05-01      # With deadline
python3 $SKILL add-project "Project Name" --area "Work"              # In an area
python3 $SKILL add-project "Project Name" --todos "Task 1,Task 2"   # With initial todos
python3 $SKILL add-project "Project Name" --tags "tag1,tag2"         # With tags
python3 $SKILL update-project <id> --title "New Name"                # Rename project
python3 $SKILL update-project <id> --deadline 2026-06-01             # Set deadline
python3 $SKILL update-project <id> --append-notes "Update"           # Append to notes
python3 $SKILL update-project <id> --add-tags "newtag"               # Add tags
python3 $SKILL update-project <id> --completed                       # Complete project
```
