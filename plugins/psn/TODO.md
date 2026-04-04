# TODO

## Phase 1: Fix Existing Agents

- [x] Fix `memory-curator.md` — add MCP memory tools to `tools:` frontmatter and update Tools Reference table
- [x] Verify `core.md` — confirm MCP tools are correct (no changes expected)

## Phase 2: Port Skills

- [x] Restructure all skills to subdirectory format (`skills/name/SKILL.md`)
- [x] Update `skills/memory/SKILL.md` — fix MCP tool name format
- [x] Update `skills/session/SKILL.md` — fix MCP tool name format, add version field
- [x] Port + fix `skills/indexer/SKILL.md` — third-person description, add examples
- [x] Port `skills/cloudflare/SKILL.md` from psn-plugin
- [x] Port `skills/plugin-management/SKILL.md` from psn-plugin
- [x] Port `skills/code/` directory (27 skills) from psn-plugin as subdirectories

## Phase 3: Port Coding Agents

- [x] Port `agents/code-ruby.md` from psn-plugin
- [x] Port `agents/code-python.md` from psn-plugin
- [x] Port `agents/code-rust.md` from psn-plugin
- [x] Port `agents/code-typescript.md` from psn-plugin
- [x] Port `agents/code-dx.md` from psn-plugin

## Phase 4: Port Utility Agents

- [x] Port `agents/code-analyzer.md` from psn-plugin — add MCP index + memory tools
- [x] Port `agents/docs.md` from psn-plugin — add MCP index tools
- [x] Port `agents/draw.md` from psn-plugin
- [x] Port `agents/hardware.md` from psn-plugin
- [x] Port `agents/claude-admin.md` from psn-plugin

## Phase 5: Port Infrastructure Agents

- [x] Port `agents/architect.md` from psn-plugin
- [x] Port `agents/devops.md` from psn-plugin
- [x] Port `agents/devops-cf.md` from psn-plugin
- [x] Port `agents/devops-gh.md` from psn-plugin
- [x] Port `agents/devops-net.md` from psn-plugin
- [x] Port `agents/devops-tengu.md` from psn-plugin

## Phase 6: Merge Dispatcher into core.md

- [x] Add Agent Registry table to `core.md`
- [x] Add Routing Logic section (classify → detect language → dispatch)
- [x] Add Language Detection table
- [x] Add Parallel Execution Candidates
- [x] Add Quick Reference routing table

## Phase 7: Port Commands

- [x] Port `commands/index-code.md` from psn-plugin
- [x] Port `commands/index-docs.md` from psn-plugin
- [x] Port `commands/index-status.md` from psn-plugin
- [x] Port `commands/cf/` directory (26 files) from psn-plugin
- [x] Port `commands/plugins/` directory (8 files) from psn-plugin

## Phase 8: Verify & Clean Up

- [ ] Verify hooks.json references resolve to personality gem CLI
- [ ] Verify prompts/intro.md works with session-start hook
- [ ] Test agent discovery (all agents appear in /agents list)
