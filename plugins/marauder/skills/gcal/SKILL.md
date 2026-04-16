---
name: Google Calendar
description: |
  Manage Google Calendar events via gog CLI. Multi-account (chi@sazabi.pl, adam.ladachowski@gmail.com). Shortcuts for today, tomorrow, week. Use today-all/week-all for both accounts.

  <example>
  Context: User asks about their day
  user: "what's on my calendar today?"
  </example>

  <example>
  Context: User asks about the week
  user: "what does my week look like?"
  </example>

  <example>
  Context: User wants to create an event
  user: "add a meeting tomorrow at 2pm"
  </example>

  <example>
  Context: User searches for an event
  user: "when's the dentist appointment?"
  </example>

  <example>
  Context: User checks all accounts
  user: "anything on any calendar today?"
  </example>
version: 1.0.0
---

# Google Calendar Skill

View, search, create, and manage Google Calendar events via `gog` CLI. Multi-account support.

## Quick Reference

```bash
SKILL=${CLAUDE_PLUGIN_ROOT}/skills/gcal/gcal.sh

# Today's events (all calendars)
bash $SKILL today

# Tomorrow
bash $SKILL tomorrow

# This week (with day-of-week column)
bash $SKILL week

# Next 3 days
bash $SKILL next 3

# 7-day agenda, all calendars
bash $SKILL agenda

# Today across ALL accounts
bash $SKILL today-all

# Week across ALL accounts
bash $SKILL week-all

# Search events
bash $SKILL search "dentist"
bash $SKILL search "meeting" --today
bash $SKILL search "standup" --week

# Create event
bash $SKILL create --summary "Lunch with Bob" --from "2026-04-08T12:00:00+02:00" --to "2026-04-08T13:00:00+02:00"
bash $SKILL create --summary "Day Off" --from "2026-04-10" --to "2026-04-11" --all-day

# Create with attendees and Meet link
bash $SKILL create --summary "Sync" --from tomorrow --to tomorrow --attendees "bob@example.com" --with-meet

# Specific account
bash $SKILL today -a adam.ladachowski@gmail.com

# List calendars
bash $SKILL calendars

# Free/busy check
bash $SKILL freebusy --from "2026-04-08T09:00:00+02:00" --to "2026-04-08T17:00:00+02:00"

# RSVP to invitation
bash $SKILL respond primary <eventId> --status accepted

# JSON output
bash $SKILL today --json
```

## Accounts

| Account | Default | Calendars |
|---------|---------|-----------|
| `chi@sazabi.pl` | Yes | Primary + Polish Holidays |
| `adam.ladachowski@gmail.com` | No | Google (primary) |

Use `-a <email>` to target a specific account. `today-all` / `week-all` query both.

## Commands

### View

| Command | Description |
|---------|-------------|
| `today` | Today's events, all calendars |
| `tomorrow` | Tomorrow's events |
| `week` | This week with day-of-week |
| `next <N>` | Next N days |
| `agenda` | 7-day agenda, all calendars |
| `today-all` | Today across all accounts |
| `week-all` | This week across all accounts |

### Query

| Command | Description |
|---------|-------------|
| `events [calendarId]` | List events (pass-through flags) |
| `search <query>` | Free-text event search |
| `freebusy` | Free/busy time check |
| `conflicts` | Find scheduling conflicts |

### Create & Manage

| Command | Description |
|---------|-------------|
| `create` | Create event (--summary, --from, --to) |
| `update <calId> <eventId>` | Update event fields |
| `delete <calId> <eventId>` | Delete event |
| `respond <calId> <eventId>` | RSVP (--status accepted/declined/tentative) |

### Info

| Command | Description |
|---------|-------------|
| `calendars` | List calendars |
| `accounts` | List configured accounts |

## Create Event Flags

| Flag | Description |
|------|-------------|
| `--summary` | Event title |
| `--from` / `--to` | Start/end time (RFC3339, date, or relative) |
| `--description` | Event description |
| `--location` | Location |
| `--attendees` | Comma-separated emails |
| `--all-day` | All-day event (use date-only for from/to) |
| `--with-meet` | Attach Google Meet link |
| `--reminder` | e.g. `popup:30m`, `email:1d` |
| `--visibility` | default, public, private |
| `--rrule` | Recurrence (e.g. `RRULE:FREQ=WEEKLY;BYDAY=MO`) |

## Time Formats

| Format | Example |
|--------|---------|
| Relative | `today`, `tomorrow`, `monday` |
| Date | `2026-04-07` |
| RFC3339 | `2026-04-07T09:00:00+02:00` |

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `-a <email>` | Target account | chi@sazabi.pl |
| `--all` | All calendars | on for today/tomorrow/week |
| `--json` | JSON output | off |
| `--max <N>` | Max results | 25 |

## Prerequisites

- `gog` CLI (Homebrew: `gogcli`)
- OAuth auth per account: `gog auth add <email> --services calendar`

## Auth Setup

```bash
gog auth add chi@sazabi.pl --services calendar
gog auth add adam.ladachowski@gmail.com --services calendar
```
