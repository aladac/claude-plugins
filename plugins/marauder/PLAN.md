# marauder-plugin Implementation Plan

Claude Code plugin replacing `personality-plugin`. Uses the `marauder` Rust binary for MCP servers, hooks, and compiled skills.

## Architecture

**Separate repo** from `marauder-os`. The plugin is the Claude Code integration layer (markdown, JSON, scripts). The binary is a runtime dependency on PATH, not a build dependency.

```
marauder-plugin/          ← Claude Code reads this
  .claude-plugin/plugin.json
  .mcp.json               → marauder mcp --mode {core,indexer,local}
  hooks/hooks.json        → marauder hooks <event>, marauder tts <cmd>
  agents/*.md             → 23 agents, tool refs: mcp__plugin_marauder_*
  skills/*/SKILL.md       → 60+ skills (config-only + scripts + compiled refs)
  commands/*.md           → 50+ slash commands

marauder-os/              ← Compiled binary
  marauder mcp            → MCP server (rmcp, stdio)
  marauder hooks          → Hook handlers (JSONL, stdin JSON)
  marauder skill          → Compiled skills (brew, cargo, uv, gem, ruby, screenshot, music)
  marauder tts            → TTS (piper process management)
  marauder memory/cart/index → Core operations
```

## Skill Tiers

| Tier | Count | Where | Example |
|------|-------|-------|---------|
| **Config-only** (SKILL.md, no code) | ~38 | Plugin `skills/*/SKILL.md` | code/rust, memory, persona, browse |
| **Script-based** (SKILL.md + .sh/.rb/.py) | ~19 | Plugin `skills/*/` | cloudflare, eve-esi, cam, job-scout, gmail |
| **Compiled** (SKILL.md → `marauder skill`) | 8 | marauder-os binary | brew, cargo, uv, gem, ruby, screenshot, junkpile modes |
| **Already in marauder** | 6 | marauder-os existing CLI | memory, persona/cart, speech/tts, indexer |

## MCP Tool Naming

Plugin name: `marauder`. Server keys: `core`, `indexer`, `local`.

```
mcp__plugin_marauder_core__memory_store
mcp__plugin_marauder_core__memory_recall
mcp__plugin_marauder_indexer__index_code
mcp__plugin_marauder_local__speak
```

## Hook Strategy

- **Shell hooks** → find-replace `psn` → `marauder` in hooks.json
- **JS hooks** (hud-layout.js, hud-avatar.js, hud-bootup.js) → **stay as JS** — they run in Claude Code's Node.js runtime with canvas/DOM APIs that can't move to Rust
- **hud-tool.sh** (Ruby JSON parsing) → **compile** into `marauder hooks hud-tool` with serde_json

## Migration Strategy

Incremental. Both plugins coexist during transition:
- Different plugin names (`psn` vs `marauder`) = different tool namespaces
- Same config.toml, same database (WAL concurrent access)
- Rollback: just re-enable personality-plugin

## Phases

### Phase 10 "Guncannon" — Plugin Scaffold
Create repo structure, manifest, MCP config. Copy config-only skills and script-based skills.

### Phase 11 "Guntank" — Agent Migration
Copy 23 agents, bulk find-replace tool prefixes `psn` → `marauder`.

### Phase 12 "Ball" — Hook Migration
Rewrite hooks.json, copy JS hooks unchanged, compile hud-tool into marauder.

### Phase 13 "GM" — Compiled Skills
Implement `marauder skill` subcommand in marauder-os: cross_machine module + brew/cargo/uv/gem/ruby/screenshot.

### Phase 14 "Nemo" — Command Migration
Copy 50+ commands, update paths and CLI references.

### Phase 15 "Rick Dias" — Cutover
Disable personality-plugin, enable marauder-plugin as sole plugin. Full integration test.

## Estimated Effort

| Phase | Naive | Coop | Sessions | Notes |
|-------|-------|------|----------|-------|
| 10 "Guncannon" — Scaffold | 3h | ~1.5h | 1 | Mechanical copy + path fixup |
| 11 "Guntank" — Agents | 2h | ~45m | 1 | Bulk sed, verify tool refs |
| 12 "Ball" — Hooks | 3h | ~1.5h | 1 | hooks.json rewrite + hud-tool compile |
| 13 "GM" — Compiled Skills | 4h | ~2h | 1 | cross_machine module in marauder-os |
| 14 "Nemo" — Commands | 2h | ~45m | 1 | Mechanical copy + path fixup |
| 15 "Rick Dias" — Cutover | 2h | ~1h | 1 | Integration test, soak |
| **Total** | **16h** | **~7.5h** | **4-6** | |

Phases 10-11 and 13 can overlap (plugin scaffold while compiling skills in marauder-os).

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Agent tool refs missed in find-replace | Medium | Grep validator: every `mcp__plugin_` in agents/ must match .mcp.json server |
| JS hooks depend on window.PSN namespace | Low | Namespace set by HUD, not plugin — no change needed |
| hud-bootup.js is huge (~130K tokens) | Medium | Audit for base64 images, extract static assets |
| Script paths break | Medium | Use `${CLAUDE_PLUGIN_ROOT}` everywhere, never hardcode |
| marauder binary not on PATH | Medium | Use absolute path in .mcp.json initially |
| Ruby skills require Ruby runtime | Low | Eve scripts stay as Ruby — Ruby stays required on host |
