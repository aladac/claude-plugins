#!/usr/bin/env python3
"""Things 3 skill — read via SQLite, write via URL scheme."""

import argparse
import os
import sqlite3
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote


# ── Config ────────────────────────────────────────────────

THINGS_DB = Path.home() / "Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/ThingsData-MF22B/Things Database.thingsdatabase/main.sqlite"

_token_cache = None


def get_token():
    global _token_cache
    if _token_cache is not None:
        return _token_cache
    _token_cache = os.environ.get("THINGS_TOKEN") or ""
    if not _token_cache:
        try:
            result = subprocess.run(
                ["op", "item", "get", "things3", "--vault", "DEV", "--fields", "credential", "--reveal"],
                capture_output=True, text=True, timeout=10,
            )
            _token_cache = result.stdout.strip()
        except (subprocess.SubprocessError, FileNotFoundError):
            _token_cache = ""
    return _token_cache


# ── Database ──────────────────────────────────────────────

TODO_FIELDS = """
    t.uuid,
    t.title,
    date(t.startDate, 'unixepoch', '+31 years'),
    date(t.deadline, 'unixepoch', '+31 years'),
    COALESCE(p.title, ''),
    COALESCE(GROUP_CONCAT(DISTINCT tag.title), ''),
    COALESCE(t.notes, '')
"""

TODO_JOINS = """
    LEFT JOIN TMTask p ON t.project = p.uuid
    LEFT JOIN TMTaskTag tt ON t.uuid = tt.tasks
    LEFT JOIN TMTag tag ON tt.tags = tag.uuid
"""

TODO_BASE = f"""
    SELECT {TODO_FIELDS}
    FROM TMTask t {TODO_JOINS}
    WHERE t.trashed = 0 AND t.status = 0 AND t.type = 0
"""


def query(sql):
    try:
        conn = sqlite3.connect(f"file:{THINGS_DB}?mode=ro", uri=True)
        rows = conn.execute(sql).fetchall()
        conn.close()
        return rows
    except sqlite3.Error:
        return []


def format_todos(rows):
    if not rows:
        return
    for uuid, title, when_date, deadline, project, tags, notes in rows:
        line = f"☐ {title}"
        if tags:
            line += f" #{tags}"
        if when_date:
            line += f" ({when_date})"
        if deadline:
            line += f" [due: {deadline}]"
        if project:
            line += f" → {project}"
        print(line)
        print(f"  id: {uuid}")


# ── URL Scheme ────────────────────────────────────────────

def build_url(action, params):
    """Build a things:/// URL with auth token and properly encoded params."""
    token = get_token()
    encoded = "&".join(
        f"{quote(k, safe='')}={quote(v, safe='@:')}"
        for k, v in params.items()
        if v is not None
    )
    url = f"things:///{action}?auth-token={token}"
    if encoded:
        url += f"&{encoded}"
    return url


def things_open(url):
    subprocess.run(["open", url], check=True)


# ── Read Commands ─────────────────────────────────────────

def cmd_today(_args):
    rows = query(f"{TODO_BASE} AND t.start = 1 GROUP BY t.uuid ORDER BY t.todayIndex;")
    if not rows:
        print("No todos for today.")
    else:
        print("=== Today ===")
        format_todos(rows)


def cmd_inbox(_args):
    rows = query(f"{TODO_BASE} AND t.start = 0 AND t.startDate IS NULL AND t.project IS NULL GROUP BY t.uuid ORDER BY t.`index`;")
    if not rows:
        print("Inbox is empty.")
    else:
        print("=== Inbox ===")
        format_todos(rows)


def cmd_upcoming(_args):
    rows = query(f"{TODO_BASE} AND t.start = 2 GROUP BY t.uuid ORDER BY t.startDate;")
    if not rows:
        print("No upcoming todos.")
    else:
        print("=== Upcoming ===")
        format_todos(rows)


def cmd_someday(_args):
    rows = query(f"{TODO_BASE} AND t.start = 2 AND t.startDate IS NULL GROUP BY t.uuid ORDER BY t.`index`;")
    if not rows:
        print("No someday todos.")
    else:
        print("=== Someday ===")
        format_todos(rows)


def cmd_projects(_args):
    rows = query("SELECT uuid, title FROM TMTask WHERE trashed = 0 AND status = 0 AND type = 1 ORDER BY title;")
    for uuid, title in rows:
        count = query(f"SELECT COUNT(*) FROM TMTask WHERE project = '{uuid}' AND trashed = 0 AND status = 0 AND type = 0;")
        n = count[0][0] if count else 0
        print(f"📁 {title} ({n} todos)")
        print(f"  id: {uuid}")


def cmd_project(args):
    name = args.name
    pid = query(f"SELECT uuid FROM TMTask WHERE title = '{name}' AND type = 1 AND trashed = 0 LIMIT 1;")
    if not pid:
        print(f"Project not found: {name}")
        sys.exit(1)
    pid = pid[0][0]
    rows = query(f"{TODO_BASE} AND t.project = '{pid}' GROUP BY t.uuid ORDER BY t.`index`;")
    if not rows:
        print(f"No todos in project: {name}")
    else:
        print(f"=== {name} ===")
        format_todos(rows)


def cmd_search(args):
    term = args.term
    rows = query(f"{TODO_BASE} AND (t.title LIKE '%{term}%' OR t.notes LIKE '%{term}%') GROUP BY t.uuid ORDER BY t.todayIndex;")
    if not rows:
        print(f"No todos matching: {term}")
    else:
        print(f"=== Search: {term} ===")
        format_todos(rows)


def cmd_tags(_args):
    tags = query("SELECT title FROM TMTag ORDER BY title;")
    for (tag,) in tags:
        count = query(f"SELECT COUNT(*) FROM TMTaskTag tt JOIN TMTask t ON tt.tasks = t.uuid WHERE tt.tags = (SELECT uuid FROM TMTag WHERE title = '{tag}') AND t.trashed = 0 AND t.status = 0;")
        n = count[0][0] if count else 0
        print(f"#{tag} ({n})")


def cmd_show(args):
    uid = args.id
    rows = query(f"""
        SELECT t.title, date(t.startDate, 'unixepoch', '+31 years'),
               date(t.deadline, 'unixepoch', '+31 years'), t.notes, t.status,
               COALESCE(p.title, '')
        FROM TMTask t LEFT JOIN TMTask p ON t.project = p.uuid
        WHERE t.uuid = '{uid}';
    """)
    if not rows:
        print(f"Todo not found: {uid}")
        sys.exit(1)
    title, when_date, deadline, notes, status, project = rows[0]
    print(f"Title: {title}")
    if when_date:
        print(f"When: {when_date}")
    if deadline:
        print(f"Deadline: {deadline}")
    if project:
        print(f"Project: {project}")
    if notes:
        print(f"Notes: {notes}")
    # Checklist
    items = query(f"""
        SELECT title, CASE WHEN stopDate IS NOT NULL THEN '✓' ELSE '☐' END
        FROM TMChecklistItem WHERE task = '{uid}' ORDER BY `index`;
    """)
    for item, check in items:
        print(f"  {check} {item}")


# ── Write Commands ────────────────────────────────────────

def cmd_add(args):
    params = {"title": args.title}
    if args.when:
        params["when"] = args.when
    if args.tags:
        params["tags"] = args.tags
    if args.notes:
        params["notes"] = args.notes
    if args.project:
        params["list"] = args.project
    if args.deadline:
        params["deadline"] = args.deadline
    if args.heading:
        params["heading"] = args.heading
    if args.checklist:
        params["checklist-items"] = "\n".join(args.checklist.split(","))

    url = build_url("add", params)
    things_open(url)
    print(f"Created: {args.title}")


def cmd_update(args):
    params = {"id": args.id}
    if args.title:
        params["title"] = args.title
    if args.when:
        params["when"] = args.when
    if args.tags:
        params["tags"] = args.tags
    if args.notes:
        params["notes"] = args.notes
    if args.append_notes:
        params["append-notes"] = args.append_notes
    if args.prepend_notes:
        params["prepend-notes"] = args.prepend_notes
    if args.deadline:
        params["deadline"] = args.deadline
    if args.reminder:
        params["reminder"] = args.reminder
    if args.heading:
        params["heading"] = args.heading
    if args.checklist:
        params["checklist-items"] = "\n".join(args.checklist.split(","))
    if args.completed:
        params["completed"] = "true"
    if args.canceled:
        params["canceled"] = "true"

    url = build_url("update", params)
    things_open(url)
    print(f"Updated: {args.id}")


def cmd_complete(args):
    url = build_url("update", {"id": args.id, "completed": "true"})
    things_open(url)
    print(f"Completed: {args.id}")


# ── CLI ───────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(prog="things", description="Things 3 CLI — read via SQLite, write via URL scheme")
    sub = parser.add_subparsers(dest="command")

    # Read
    sub.add_parser("today", aliases=["t"], help="Today's todos").set_defaults(func=cmd_today)
    sub.add_parser("inbox", aliases=["i"], help="Inbox todos").set_defaults(func=cmd_inbox)
    sub.add_parser("upcoming", aliases=["u"], help="Upcoming todos").set_defaults(func=cmd_upcoming)
    sub.add_parser("someday", aliases=["s"], help="Someday todos").set_defaults(func=cmd_someday)
    sub.add_parser("projects", aliases=["p"], help="All projects").set_defaults(func=cmd_projects)

    p_project = sub.add_parser("project", help="Todos in a project")
    p_project.add_argument("name")
    p_project.set_defaults(func=cmd_project)

    p_search = sub.add_parser("search", aliases=["find", "f"], help="Search by title/notes")
    p_search.add_argument("term")
    p_search.set_defaults(func=cmd_search)

    sub.add_parser("tags", help="List all tags with counts").set_defaults(func=cmd_tags)

    p_show = sub.add_parser("show", help="Show full todo details")
    p_show.add_argument("id")
    p_show.set_defaults(func=cmd_show)

    # Write
    p_add = sub.add_parser("add", help="Create a new todo")
    p_add.add_argument("title")
    p_add.add_argument("--when")
    p_add.add_argument("--tags")
    p_add.add_argument("--notes")
    p_add.add_argument("--project")
    p_add.add_argument("--deadline")
    p_add.add_argument("--heading")
    p_add.add_argument("--checklist")
    p_add.set_defaults(func=cmd_add)

    p_update = sub.add_parser("update", help="Update an existing todo")
    p_update.add_argument("id")
    p_update.add_argument("--title")
    p_update.add_argument("--when")
    p_update.add_argument("--tags")
    p_update.add_argument("--notes")
    p_update.add_argument("--append-notes")
    p_update.add_argument("--prepend-notes")
    p_update.add_argument("--deadline")
    p_update.add_argument("--reminder")
    p_update.add_argument("--heading")
    p_update.add_argument("--checklist")
    p_update.add_argument("--completed", action="store_true")
    p_update.add_argument("--canceled", action="store_true")
    p_update.set_defaults(func=cmd_update)

    p_complete = sub.add_parser("complete", help="Mark todo complete")
    p_complete.add_argument("id")
    p_complete.set_defaults(func=cmd_complete)

    args = parser.parse_args()
    if not args.command:
        # Default to today
        cmd_today(args)
    else:
        args.func(args)


if __name__ == "__main__":
    main()
