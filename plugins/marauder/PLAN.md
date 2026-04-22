# Jira Integration via `hu` CLI

**Date:** 2026-04-22
**Goal:** Expose `hu jira` operations in marauder-plugin as a skill and slash commands. Jira only — other `hu` tools (gh, slack, pagerduty, etc.) excluded for now.

## Why

- `hu` is already installed with full Jira OAuth support
- Sprint/ticket visibility from the Claude Code interface saves context-switching
- Slash commands give quick invocation; the skill gives proactive AI-driven access

## Scope

| hu subcommand | Slash command | Skill operation |
|---------------|---------------|-----------------|
| `hu jira tickets` | `/jira:tickets` | List my sprint tickets |
| `hu jira sprint` | `/jira:sprint` | Full sprint board |
| `hu jira sprints` | `/jira:sprints` | List sprints (active/future/closed) |
| `hu jira show <KEY>` | `/jira:show` | Ticket details |
| `hu jira search <JQL>` | `/jira:search` | JQL search |
| `hu jira update <KEY>` | `/jira:update` | Update ticket (read-before-write enforced) |

## Architecture

**No new dependencies.** Pure markdown/config additions to marauder-plugin.

```
marauder-plugin/
  skills/jira/
    SKILL.md          ← skill definition, all hu jira operations
  commands/jira/
    tickets.md        ← /jira:tickets
    sprint.md         ← /jira:sprint
    sprints.md        ← /jira:sprints
    show.md           ← /jira:show
    search.md         ← /jira:search
    update.md         ← /jira:update
```

**Update safety:** `hu jira update` always fetches current ticket via `hu jira show <KEY>` first, displays it, then applies changes. Enforced in `update.md` execution flow.

## Phases

### Phase 1: Jira Skill
Create `skills/jira/SKILL.md` with complete `hu jira` quick reference, examples, and update safety notes.

### Phase 2: Slash Commands
Create `commands/jira/` directory with 6 command files. Each wraps the corresponding `hu jira` subcommand with TaskCreate spinner and structured output.

### Phase 3: Reinstall + Smoke Test
Run `/plugin-reinstall`, restart session, verify commands appear and auth works.

## Not in Scope (This Phase)

- `hu gh` — GitHub operations (already covered by native gh CLI)
- `hu slack`, `hu pagerduty`, `hu sentry`, `hu newrelic` — future phases
- `hu jira auth` — not a slash command, user runs manually
