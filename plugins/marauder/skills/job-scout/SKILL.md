---
name: Job Scout
description: |
  Multi-source job search aggregator. Scans Gmail, NoFluffJobs, Just Join IT, RubyOnRemote, HN Who's Hiring, and more for senior Ruby/Rails roles. Scores matches, tracks pipeline, manages watchlist.

  <example>
  Context: User wants to find new jobs
  user: "scout for jobs"
  </example>

  <example>
  Context: User wants to check email for recruiter messages
  user: "check my job inbox"
  </example>

  <example>
  Context: User wants to analyze a specific posting
  user: "review this job posting"
  </example>

  <example>
  Context: User wants a status update
  user: "job report"
  </example>

  <example>
  Context: User wants to score a job description
  user: "score this job against my criteria"
  </example>

  <example>
  Context: User wants to track a company
  user: "add Shopify to my job watchlist"
  </example>
version: 1.0.0
---

# Job Scout Skill

Multi-source job search aggregator for senior Ruby/Rails remote roles.

## Quick Reference

```bash
SKILL=${CLAUDE_PLUGIN_ROOT}/skills/job-scout/job-scout.sh

# Full scan — all sources
bash $SKILL scout

# Scan single source
bash $SKILL scout --source nofluffjobs
bash $SKILL scout --source gmail
bash $SKILL scout --source hnhiring

# Check email inbox for recruiter/ATS messages
bash $SKILL inbox

# Score a job description
echo "Senior Ruby on Rails, 30K PLN, remote, B2B" | bash $SKILL score

# Report — summary of leads and pipeline
bash $SKILL report

# Pipeline management
bash $SKILL pipeline
bash $SKILL status https://example.com/job/123 applied

# Watchlist and blacklist
bash $SKILL track "Basecamp"
bash $SKILL blacklist "Bad Recruiter Agency"

# Show criteria
bash $SKILL criteria

# List leads
bash $SKILL leads
```

## Commands

### Scan

| Command | Description |
|---------|-------------|
| `scout` | Full scan across all 8 sources |
| `scout --source <name>` | Scan one source |
| `inbox` | Check email for recruiter/ATS messages (7d) |

### Analyze

| Command | Description |
|---------|-------------|
| `score` | Score job text against criteria (pipe or args) |

### Manage

| Command | Description |
|---------|-------------|
| `track <company>` | Add to watchlist in criteria.yaml |
| `blacklist <name>` | Add to blacklist in criteria.yaml |
| `pipeline` | Show application pipeline |
| `status <url> <state>` | Update pipeline entry |

### Report

| Command | Description |
|---------|-------------|
| `report` | Summary of leads, pipeline, last scans |
| `leads` | List lead files |
| `criteria` | Show current search criteria |

## Sources

| Source | Shortcut | Method |
|--------|----------|--------|
| Gmail (both accounts) | `gmail` | gog CLI search |
| NoFluffJobs | `nfj` | API/curl |
| Just Join IT | `jjit` | API/curl |
| RubyOnRemote | `ror` | curl + parse |
| Rails Job Board | `rjb` | curl + parse |
| HN Who's Hiring | `hn` | curl + parse |
| Bulldogjob | `bdj` | curl + parse |
| Welcome to the Jungle | `wttj` | curl + parse |

## Scoring

Jobs are scored 0-100 against `~/Projects/jobs/criteria.yaml`:

| Score | Grade | Meaning |
|-------|-------|---------|
| 80-100 | A | Strong match, apply |
| 60-79 | B | Good match, review |
| 40-59 | C | Partial match |
| 20-39 | D | Weak match |
| 0-19 | F | Skip |

### Score Breakdown

| Factor | Max Points |
|--------|-----------|
| Title keywords | +25 |
| Must-have stack (ruby/rails) | +25 |
| Strong match stack | +15 |
| Nice-to-have stack | +10 |
| Location match | +10 |
| Salary in range | +10 |
| Contract type match | +5 |
| Watchlist company | +15 |
| Exclude keyword | -50 each |
| Dealbreaker | -100 |
| Blacklisted | -100 |

## File Structure

```
~/Projects/jobs/
  criteria.yaml      # Search criteria, watchlist, blacklist
  status.yaml        # Scan state, seen URLs, pipeline
  leads/             # Individual lead analysis files
  everai.md          # Company recon files
  opus-*.md          # Recruiter profiles
```

## Prerequisites

- `gog` CLI with gmail OAuth (both accounts)
- `python3` with `pyyaml`
- `curl`
- Gmail skill at `${CLAUDE_PLUGIN_ROOT}/skills/gmail/gmail.sh`
