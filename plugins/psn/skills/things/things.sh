#!/usr/bin/env bash
# Things 3 skill — read via SQLite, write via URL scheme
set -euo pipefail

THINGS_DB="$HOME/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/ThingsData-MF22B/Things Database.thingsdatabase/main.sqlite"
THINGS_TOKEN="${THINGS_TOKEN:-$(op item get things3 --vault DEV --fields credential --reveal 2>/dev/null)}"

cmd="${1:-today}"
shift 2>/dev/null || true

# ── Helpers ──────────────────────────────────────────────

urlencode() {
  python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

# Use osascript to open URL — handles encoding properly unlike /usr/bin/open
things_open() {
  osascript -e "open location \"$1\""
}

query() {
  sqlite3 "$THINGS_DB" "$1" 2>/dev/null
}

format_todos() {
  # Reads pipe-delimited: id|title|when|deadline|project|tags|notes
  while IFS='|' read -r id title when_date deadline project tags notes; do
    line="☐ $title"
    [[ -n "$tags" ]] && line="$line #$tags"
    [[ -n "$when_date" ]] && line="$line ($when_date)"
    [[ -n "$deadline" ]] && line="$line [due: $deadline]"
    [[ -n "$project" ]] && line="$line → $project"
    echo "$line"
    echo "  id: $id"
  done
}

# ── SQL Fragments ────────────────────────────────────────

TODO_FIELDS="t.uuid, t.title, date(t.startDate, 'unixepoch', '+31 years'), date(t.deadline, 'unixepoch', '+31 years'), COALESCE(p.title, ''), COALESCE(GROUP_CONCAT(DISTINCT tag.title), ''), COALESCE(t.notes, '')"

TODO_JOINS="LEFT JOIN TMTask p ON t.project = p.uuid LEFT JOIN TMTaskTag tt ON t.uuid = tt.tasks LEFT JOIN TMTag tag ON tt.tags = tag.uuid"

TODO_BASE="SELECT $TODO_FIELDS FROM TMTask t $TODO_JOINS WHERE t.trashed = 0 AND t.status = 0 AND t.type = 0"

# ── Read Commands ────────────────────────────────────────

case "$cmd" in
  today|t)
    result=$(query "$TODO_BASE AND t.start = 1 GROUP BY t.uuid ORDER BY t.todayIndex;")
    if [[ -z "$result" ]]; then
      echo "No todos for today."
    else
      echo "=== Today ==="
      echo "$result" | format_todos
    fi
    ;;

  inbox|i)
    result=$(query "$TODO_BASE AND t.start = 0 AND t.startDate IS NULL AND t.project IS NULL GROUP BY t.uuid ORDER BY t.\`index\`;")
    if [[ -z "$result" ]]; then
      echo "Inbox is empty."
    else
      echo "=== Inbox ==="
      echo "$result" | format_todos
    fi
    ;;

  upcoming|u)
    result=$(query "$TODO_BASE AND t.start = 2 GROUP BY t.uuid ORDER BY t.startDate;")
    if [[ -z "$result" ]]; then
      echo "No upcoming todos."
    else
      echo "=== Upcoming ==="
      echo "$result" | format_todos
    fi
    ;;

  someday|s)
    result=$(query "$TODO_BASE AND t.start = 2 AND t.startDate IS NULL GROUP BY t.uuid ORDER BY t.\`index\`;")
    if [[ -z "$result" ]]; then
      echo "No someday todos."
    else
      echo "=== Someday ==="
      echo "$result" | format_todos
    fi
    ;;

  projects|p)
    query "SELECT uuid, title FROM TMTask WHERE trashed = 0 AND status = 0 AND type = 1 ORDER BY title;" | while IFS='|' read -r id title; do
      count=$(query "SELECT COUNT(*) FROM TMTask WHERE project = '$id' AND trashed = 0 AND status = 0 AND type = 0;")
      echo "📁 $title ($count todos)"
      echo "  id: $id"
    done
    ;;

  project)
    name="$1"
    pid=$(query "SELECT uuid FROM TMTask WHERE title = '$name' AND type = 1 AND trashed = 0 LIMIT 1;")
    if [[ -z "$pid" ]]; then
      echo "Project not found: $name"
      exit 1
    fi
    result=$(query "$TODO_BASE AND t.project = '$pid' GROUP BY t.uuid ORDER BY t.\`index\`;")
    if [[ -z "$result" ]]; then
      echo "No todos in project: $name"
    else
      echo "=== $name ==="
      echo "$result" | format_todos
    fi
    ;;

  search|find|f)
    term="$1"
    result=$(query "$TODO_BASE AND (t.title LIKE '%$term%' OR t.notes LIKE '%$term%') GROUP BY t.uuid ORDER BY t.todayIndex;")
    if [[ -z "$result" ]]; then
      echo "No todos matching: $term"
    else
      echo "=== Search: $term ==="
      echo "$result" | format_todos
    fi
    ;;

  tags)
    query "SELECT title FROM TMTag ORDER BY title;" | while read -r tag; do
      count=$(query "SELECT COUNT(*) FROM TMTaskTag tt JOIN TMTask t ON tt.tasks = t.uuid WHERE tt.tags = (SELECT uuid FROM TMTag WHERE title = '$tag') AND t.trashed = 0 AND t.status = 0;")
      echo "#$tag ($count)"
    done
    ;;

  show)
    id="$1"
    query "SELECT t.title, date(t.startDate, 'unixepoch', '+31 years'), date(t.deadline, 'unixepoch', '+31 years'), t.notes, t.status, COALESCE(p.title, '') FROM TMTask t LEFT JOIN TMTask p ON t.project = p.uuid WHERE t.uuid = '$id';" | IFS='|' read -r title when_date deadline notes status project
    echo "Title: $title"
    [[ -n "$when_date" ]] && echo "When: $when_date"
    [[ -n "$deadline" ]] && echo "Deadline: $deadline"
    [[ -n "$project" ]] && echo "Project: $project"
    [[ -n "$notes" ]] && echo "Notes: $notes"
    # Checklist
    query "SELECT title, CASE WHEN stopDate IS NOT NULL THEN '✓' ELSE '☐' END FROM TMChecklistItem WHERE task = '$id' ORDER BY \`index\`;" | while IFS='|' read -r item check; do
      echo "  $check $item"
    done
    ;;

  # ── Write Commands ───────────────────────────────────────

  add)
    title="$1"
    shift 2>/dev/null || true

    # Build params array, then encode the full URL via python
    declare -a params
    # auth-token added directly to URL, not through params (must not be encoded)
    params+=("title=$title")

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --when)      params+=("when=$2"); shift 2 ;;
        --tags)      params+=("tags=$2"); shift 2 ;;
        --notes)     params+=("notes=$2"); shift 2 ;;
        --project)   params+=("list=$2"); shift 2 ;;
        --deadline)  params+=("deadline=$2"); shift 2 ;;
        --checklist) params+=("checklist-items=$(echo "$2" | tr ',' '\n')"); shift 2 ;;
        --heading)   params+=("heading=$2"); shift 2 ;;
        *)           shift ;;
      esac
    done

    # Build properly encoded URL via python
    url=$(python3 -c "
import sys, urllib.parse
params = []
for arg in sys.argv[1:]:
    k, v = arg.split('=', 1)
    params.append((k, v))
print('things:///add?auth-token=$THINGS_TOKEN&' + '&'.join(urllib.parse.quote(k, safe='') + '=' + urllib.parse.quote(v, safe='') for k, v in params))
" "${params[@]}")

    open "$url"
    echo "Created: $title"
    ;;

  complete)
    id="$1"
    open "things:///update?auth-token=$THINGS_TOKEN&id=$id&completed=true"
    echo "Completed: $id"
    ;;

  help|h|*)
    echo "things.sh — Things 3 CLI (read: SQLite, write: URL scheme)"
    echo ""
    echo "Read:"
    echo "  today          Today's todos"
    echo "  inbox          Inbox todos"
    echo "  upcoming       Upcoming todos"
    echo "  someday        Someday todos"
    echo "  projects       All projects"
    echo "  project NAME   Todos in a project"
    echo "  search TERM    Search by title/notes"
    echo "  tags           List all tags with counts"
    echo "  show ID        Show full todo details"
    echo ""
    echo "Write:"
    echo "  add TITLE [--when today|tomorrow|DATE] [--tags TAG] [--notes TEXT]"
    echo "              [--project NAME] [--deadline DATE] [--checklist a,b,c]"
    echo "  complete ID  Mark todo complete"
    ;;
esac
