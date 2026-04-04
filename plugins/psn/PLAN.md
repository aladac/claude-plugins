# Plan: Self-Contained personality-plugin

Port all agents, skills, and commands from `psn-plugin` into `personality-plugin` so it operates as a standalone Claude Code plugin backed by the `personality` Ruby gem.

## Current State

- **personality-plugin** has: 2 agents (`core.md`, `memory-curator.md`), 5 commands, 3 skills, 1 prompt, hooks, `.mcp.json`
- **psn-plugin** has: 18 agents, 6 skills (+ 27 code sub-skills), 11 commands (+ 26 CF commands + 8 plugin commands), 1 prompt
- MCP servers: `core` (psn-mcp) and `speech` (psn-tts) — both from the personality gem
- Plugin name stays `psn`, tool prefix stays `mcp__plugin_psn_*`

## Constraints

- Keep `psn` namespace everywhere (plugin name, skill prefixes, directory names)
- Agents reference MCP tools as `mcp__plugin_psn_core__*` and `mcp__plugin_psn_speech__*`
- Skills use `Skill(skill: "psn:...")` naming
- The personality gem's MCP server exposes: memory (5 tools), index (5 tools), cart (3 tools), resource_read (1 tool) via `core` server, and speak/stop/voices/current/download/test via `speech` server

## MCP Tool Reference (personality gem)

```
# Core server (psn-mcp)
mcp__plugin_psn_core__memory_store
mcp__plugin_psn_core__memory_recall
mcp__plugin_psn_core__memory_search
mcp__plugin_psn_core__memory_forget
mcp__plugin_psn_core__memory_list
mcp__plugin_psn_core__index_code
mcp__plugin_psn_core__index_docs
mcp__plugin_psn_core__index_search
mcp__plugin_psn_core__index_status
mcp__plugin_psn_core__index_clear
mcp__plugin_psn_core__cart_list
mcp__plugin_psn_core__cart_use
mcp__plugin_psn_core__cart_create
mcp__plugin_psn_core__resource_read

# Speech server (psn-tts)
mcp__plugin_psn_speech__speak
mcp__plugin_psn_speech__stop
mcp__plugin_psn_speech__voices
mcp__plugin_psn_speech__current
mcp__plugin_psn_speech__download
mcp__plugin_psn_speech__test
```

---

## Phase 1: Fix Existing Agents

Fix the 2 agents that already exist but have incomplete tool declarations.

### 1.1 Fix `memory-curator.md`

Add MCP memory tools to the `tools:` frontmatter so the agent can actually operate on the database:

```yaml
tools:
  - TaskCreate
  - TaskUpdate
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - mcp__plugin_psn_core__memory_forget
  - mcp__plugin_psn_core__memory_list
  - mcp__plugin_psn_core__memory_recall
  - mcp__plugin_psn_core__memory_search
  - mcp__plugin_psn_core__memory_store
```

Update the Tools Reference table in the body to match.

### 1.2 Update `core.md` (persona agent)

Already has correct MCP tools. No changes needed unless role changes (see Phase 4).

---

## Phase 2: Port Skills

Skills are referenced by agents via `Skill(skill: "psn:...")`. Port from psn-plugin, updating MCP tool names where referenced.

### 2.1 Port existing skills (verify/update)

Already present in personality-plugin:
- `memory.md` — update MCP tool names from `mcp__psn__memory.store` to `mcp__plugin_psn_core__memory_store` format
- `pretty-output.md` — no changes needed
- `session.md` — update MCP tool names

### 2.2 Port indexer skill

- Copy `psn-plugin/skills/indexer.md` → `personality-plugin/skills/indexer.md`
- Update MCP tool references

### 2.3 Port cloudflare skill

- Copy `psn-plugin/skills/cloudflare.md` → `personality-plugin/skills/cloudflare.md`
- No MCP dependencies

### 2.4 Port plugin-management skill

- Copy `psn-plugin/skills/plugin-management.md` → `personality-plugin/skills/plugin-management.md`

### 2.5 Port code skills directory

- Copy entire `psn-plugin/skills/code/` → `personality-plugin/skills/code/`
- 27 files covering Ruby, Python, Rust, TypeScript, Dioxus, and common patterns
- No MCP tool references in code skills — pure coding guidance

---

## Phase 3: Port Coding Agents

These agents handle code writing, debugging, and refactoring. They use built-in tools + Bash only (no MCP).

### 3.1 `code-ruby.md`

- Copy from psn-plugin
- Tools: TaskCreate, TaskUpdate, Read, Write, Edit, Glob, Grep, Bash, Skill
- No MCP tools needed — coding agents use file/bash tools
- Critical for working on the personality gem itself

### 3.2 `code-python.md`

- Copy from psn-plugin
- Same tool set as code-ruby
- Needed for PSN Python codebase work

### 3.3 `code-rust.md`

- Copy from psn-plugin
- Same tool set

### 3.4 `code-typescript.md`

- Copy from psn-plugin
- Same tool set

### 3.5 `code-dx.md` (Dioxus)

- Copy from psn-plugin
- Same tool set

---

## Phase 4: Port Infrastructure Agents

### 4.1 `architect.md`

- Copy from psn-plugin
- Tools: TaskCreate, TaskUpdate, Read, Glob, Grep, WebSearch, WebFetch, Bash, Skill
- Language-agnostic, works with any backend

### 4.2 `devops.md` (dispatcher)

- Copy from psn-plugin
- Routes to devops-net, devops-cf, devops-gh
- Tools: Task, TaskCreate, TaskUpdate, Agent

### 4.3 `devops-cf.md`

- Copy from psn-plugin
- Cloudflare specialist
- Tools: TaskCreate, TaskUpdate, Read, Glob, Grep, Bash, Skill

### 4.4 `devops-gh.md`

- Copy from psn-plugin
- GitHub/Git specialist
- Tools: TaskCreate, TaskUpdate, Read, Glob, Grep, Bash

### 4.5 `devops-net.md`

- Copy from psn-plugin
- Network specialist (Mac-PC link, NAS, NFS)
- Tools: TaskCreate, TaskUpdate, Read, Glob, Grep, Bash

### 4.6 `devops-tengu.md`

- Copy from psn-plugin
- Tengu PaaS specialist
- Tools: TaskCreate, TaskUpdate, Read, Glob, Grep, Bash, WebSearch, WebFetch

---

## Phase 5: Port Utility Agents

### 5.1 `code-analyzer.md`

- Copy from psn-plugin
- **Add missing MCP index tools** to the `tools:` frontmatter:

```yaml
tools:
  - TaskCreate
  - TaskUpdate
  - Read
  - Glob
  - Grep
  - mcp__plugin_psn_core__index_search
  - mcp__plugin_psn_core__index_code
  - mcp__plugin_psn_core__index_docs
  - mcp__plugin_psn_core__index_status
  - mcp__plugin_psn_core__index_clear
  - mcp__plugin_psn_core__memory_store
  - mcp__plugin_psn_core__memory_recall
```

- Update the empty MCP tools tables in the body

### 5.2 `docs.md`

- Copy from psn-plugin
- Documentation management agent
- Add index MCP tools for semantic doc search

### 5.3 `draw.md`

- Copy from psn-plugin
- Stable Diffusion on junkpile
- Tools: TaskCreate, TaskUpdate, Bash, Read

### 5.4 `hardware.md`

- Copy from psn-plugin
- Hardware guidance and research
- Tools: TaskCreate, TaskUpdate, WebSearch, WebFetch, Read

### 5.5 `claude-admin.md`

- Copy from psn-plugin
- Claude Code plugin development specialist
- Tools: TaskCreate, TaskUpdate, Read, Write, Edit, Glob, Grep, Bash

---

## Phase 6: Port or Merge Dispatcher

The psn-plugin `core.md` is a **dispatcher + general coder** that routes to specialist agents. The personality-plugin `core.md` is the **persona agent**. These are different roles.

### 6.1 Decision: Keep persona `core.md`, add dispatch table

Rather than adding a separate dispatcher agent, **extend** the personality-plugin's `core.md` to include the dispatch routing table from psn-plugin's `core.md`. The persona agent is always the entry point — it should know how to route to specialists.

Add to the existing `core.md`:
- Agent Registry table (all 18 agents)
- Routing Logic section (classify → detect language → determine execution → dispatch)
- Language Detection table
- Parallel Execution Candidates
- Quick Reference routing table

This keeps a single entry point that stays in persona while being able to dispatch.

---

## Phase 7: Port Commands

### 7.1 Index commands

- Copy `index-code.md`, `index-docs.md`, `index-status.md` from psn-plugin
- These invoke MCP index tools

### 7.2 CF commands

- Copy entire `commands/cf/` directory (26 files: 13 .md + 13 .sh)
- Cloudflare operations via flarectl/cloudflared/wrangler

### 7.3 Plugin commands

- Copy `commands/plugins/` directory (8 files: 4 .md + 4 .sh)
- Plugin management utilities

### 7.4 Verify existing commands

Already present and likely correct:
- `memory-recall.md`, `memory-search.md`, `memory-store.md`
- `session-restore.md`, `session-save.md`

---

## Phase 8: Verify & Clean Up

### 8.1 Update skills MCP tool references

All skills that reference `mcp__psn__memory.store` format must be updated to `mcp__plugin_psn_core__memory_store` format. Check:
- `skills/memory.md`
- `skills/session.md`

### 8.2 Verify hooks.json

Current hooks.json references `psn` CLI commands (e.g., `psn tts mark-natural-stop`). Verify these resolve to the personality gem's CLI, not the Python PSN. The gem installs as `psn` via `exe/psn`, so this should work if the gem is installed.

### 8.3 Verify prompt

`prompts/intro.md` — check it works with personality gem's session-start hook.

### 8.4 Test agent discovery

Restart Claude CLI and verify all agents appear in `/agents` list.

---

## Implementation Order

1. **Phase 1** — Fix existing agents (quick wins)
2. **Phase 2** — Port skills (agents depend on these)
3. **Phase 3** — Port coding agents (most frequently used)
4. **Phase 5** — Port utility agents (code-analyzer needs index tools)
5. **Phase 4** — Port infrastructure agents
6. **Phase 6** — Merge dispatcher into core.md
7. **Phase 7** — Port commands
8. **Phase 8** — Verify & clean up

## File Count

| Category | Files to Port | Files to Fix |
|----------|---------------|--------------|
| Agents | 16 new | 1 existing (memory-curator) |
| Skills | 29 new (1 dir + 28 files) | 2 existing (memory, session) |
| Commands | 37 new (2 dirs + 3 files) | 0 |
| Total | **82 new** | **3 fixes** |
