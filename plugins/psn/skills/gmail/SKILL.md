---
name: Gmail Search & Management
description: |
  Search, read, send, and manage Gmail via the gog CLI. Supports multiple accounts (chi@sazabi.pl, adam.ladachowski@gmail.com). Use search-all to query both accounts in parallel. Supports Gmail query syntax for filtering.

  <example>
  Context: User wants to search email
  user: "search my email for EverAI"
  </example>

  <example>
  Context: User wants to search all accounts
  user: "check both email accounts for messages from recruiters"
  </example>

  <example>
  Context: User wants to read a specific thread
  user: "read that email thread"
  </example>

  <example>
  Context: User wants to send an email
  user: "send an email to bob@example.com about the meeting"
  </example>
version: 1.0.0
---

# Gmail Skill

Search, read, send, and manage Gmail via `gog` CLI (gogcli). Multi-account support.

## Quick Reference

```bash
SKILL=~/Projects/personality-plugin/skills/gmail/gmail.sh

# Search default account (chi@sazabi.pl)
bash $SKILL search "from:linkedin subject:engineer"

# Search specific account
bash $SKILL search "is:unread newer_than:7d" -a adam.ladachowski@gmail.com

# Search ALL accounts at once
bash $SKILL search-all "everai"

# Read a thread (plain text)
bash $SKILL read <threadId>

# Read with full bodies
bash $SKILL read-full <threadId> -a adam.ladachowski@gmail.com

# Send email
bash $SKILL send --to "bob@example.com" --subject "Hello" --body "Message here"

# Reply to thread
bash $SKILL reply <threadId> --body "Thanks for the info"

# Labels, archive, trash
bash $SKILL labels
bash $SKILL archive <threadId>
bash $SKILL trash <threadId>
bash $SKILL mark-read <threadId>

# List accounts
bash $SKILL accounts

# JSON output
bash $SKILL search "query" --json --max 20
```

## Accounts

| Account | Default | Notes |
|---------|---------|-------|
| `chi@sazabi.pl` | Yes | Primary, Google Workspace |
| `adam.ladachowski@gmail.com` | No | Personal Gmail |

Use `-a <email>` to target a specific account. `search-all` queries both.

## Commands

| Command | Description |
|---------|-------------|
| `search <query>` | Search threads using Gmail query syntax |
| `search-all <query>` | Search all accounts in parallel |
| `read <threadId>` | Read thread messages (plain text) |
| `read-full <threadId>` | Read thread with full message bodies |
| `attachments <threadId>` | List attachments in a thread |
| `send` | Send email (--to, --subject, --body) |
| `reply <threadId>` | Reply to thread (--body, auto reply-all + quote) |
| `labels` | List all labels |
| `archive <threadId>` | Archive (remove from inbox) |
| `trash <threadId>` | Move to trash |
| `mark-read <threadId>` | Mark as read |
| `unread <threadId>` | Mark as unread |
| `accounts` | List configured accounts |

## Gmail Query Syntax

| Query | Matches |
|-------|---------|
| `from:user@example.com` | Sender |
| `to:user@example.com` | Recipient |
| `subject:meeting` | Subject line |
| `"exact phrase"` | Exact match |
| `newer_than:7d` | Last 7 days (d/m/y) |
| `older_than:1y` | Older than 1 year |
| `after:2026/01/01` | After date |
| `before:2026/04/01` | Before date |
| `is:unread` | Unread only |
| `is:starred` | Starred |
| `has:attachment` | Has attachments |
| `filename:pdf` | Attachment type |
| `label:work` | By label |
| `in:inbox` / `in:sent` / `in:trash` | By location |
| `OR` | Boolean OR |
| `-keyword` | Exclude |

Combine freely: `from:linkedin subject:ruby newer_than:30d -label:archived`

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `-a <email>` | Target account | chi@sazabi.pl |
| `--max <N>` | Max search results | 10 |
| `--json` | JSON output instead of plain text | off |

## Prerequisites

- `gog` CLI (Homebrew: `gogcli`)
- OAuth auth per account per service: `gog auth add <email> --services gmail`

## Auth Setup

If a new account or service needs auth:

```bash
gog auth add chi@sazabi.pl --services gmail
gog auth add adam.ladachowski@gmail.com --services gmail
```

Opens browser for OAuth consent. One-time per account per service.
