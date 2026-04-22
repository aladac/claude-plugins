# Jira Integration — TODO

## Estimates

| Phase | Naive | Coop | Sessions | Notes |
|-------|-------|------|----------|-------|
| 1. Jira skill | 15 min | ~4 min | 1 | One SKILL.md, all operations |
| 2. Slash commands | 20 min | ~6 min | 1 | 6 command files, repetitive pattern |
| 3. Reinstall + test | 10 min | ~3 min | 1 | Plugin reinstall + auth smoke test |
| **Total** | **~45 min** | **~13 min** | **1** | All config/markdown, no Rust |

## Tasks

### Phase 1: Jira Skill
- [ ] Create `skills/jira/SKILL.md` with frontmatter, examples, quick reference for all `hu jira` operations
- [ ] Include update safety note (read-before-write — fetch+show before updating)

### Phase 2: Slash Commands
- [ ] `commands/jira/tickets.md` — list my sprint tickets
- [ ] `commands/jira/sprint.md` — full sprint board
- [ ] `commands/jira/sprints.md` — list sprints
- [ ] `commands/jira/show.md` — show ticket by KEY
- [ ] `commands/jira/search.md` — JQL search
- [ ] `commands/jira/update.md` — update ticket (fetch first, then update)

### Phase 3: Reinstall + Test
- [ ] Run `/plugin-reinstall`
- [ ] Restart Claude Code session
- [ ] Verify `/jira:tickets` appears in command list
- [ ] Smoke test: `/jira:tickets` returns current sprint
- [ ] Smoke test: `/jira:show <a real ticket key>` returns details
