# marauder-plugin TODO

## Phase 10 "Guncannon" — Plugin Scaffold (~1.5h cooperative)

- [ ] Create `.claude-plugin/plugin.json` (name: "marauder")
- [ ] Create `.claude-plugin/marketplace.json` (local-dev marketplace)
- [ ] Create `.mcp.json` pointing to `marauder mcp --mode {core,indexer,local}`
- [ ] Copy all config-only skills (~38 SKILL.md files) from personality-plugin
- [ ] Copy all script-based skills (~19 with .sh/.rb/.py) from personality-plugin
- [ ] Update hardcoded `~/Projects/personality-plugin` paths to `${CLAUDE_PLUGIN_ROOT}`
- [ ] Create compiled skill SKILL.md stubs referencing `marauder skill <name>`
- [ ] Copy prompts/ and templates/ directories
- [ ] Create README.md and LICENSE.md
- [ ] Verify: `claude plugin validate` passes

## Phase 11 "Guntank" — Agent Migration (~45m cooperative)

- [ ] Copy all 23 agent .md files from personality-plugin
- [ ] Bulk replace: `mcp__plugin_marauder_core__` → `mcp__plugin_marauder_core__`
- [ ] Bulk replace: `mcp__plugin_marauder_core__` → `mcp__plugin_marauder_core__`
- [ ] Bulk replace: `mcp__plugin_marauder_core__` → `mcp__plugin_marauder_core__`
- [ ] Bulk replace: `psn:` skill prefixes → `marauder:` in agent descriptions
- [ ] Bulk replace: `psn` → `marauder` in agent body prompts (CLI references)
- [ ] Validate: grep for any remaining `psn` references in agents/
- [ ] Test: load plugin, verify agent tool lists resolve against .mcp.json

## Phase 12 "Ball" — Hook Migration (~1.5h cooperative)

- [ ] Create hooks/hooks.json with all `psn` → `marauder` CLI calls
- [ ] Copy hud-layout.js unchanged
- [ ] Copy hud-avatar.js unchanged
- [ ] Copy hud-bootup.js unchanged (audit size — extract base64 assets if present)
- [ ] Implement `marauder hooks hud-tool` in marauder-os (replaces hud-tool.sh Ruby JSON parsing)
- [ ] Add `marauder hooks permission-request` (auto-approve mcp__plugin_marauder_* tools)
- [ ] Add `marauder hooks pre-compact` / `marauder hooks post-compact`
- [ ] Test: SessionStart, Stop, PreToolUse, PostToolUse all fire correctly
- [ ] Test: TTS interrupt-check works on UserPromptSubmit

## Phase 13 "GM" — Compiled Skills in marauder-os (~2h cooperative)

- [ ] Create `src/skills/mod.rs` with SkillAction enum
- [ ] Create `src/skills/cross_machine.rs` — Target enum, ToolPaths, detect_host(), run()
- [ ] Implement `marauder skill brew <target> <args...>`
- [ ] Implement `marauder skill cargo <target> <args...>`
- [ ] Implement `marauder skill uv <target> <args...>`
- [ ] Implement `marauder skill gem <target> <args...>`
- [ ] Implement `marauder skill ruby <target> <args...>`
- [ ] Implement `marauder skill screenshot <all|N|list|clean>`
- [ ] Implement `marauder skill junkpile <server-mode|desktop-mode>`
- [ ] Wire Command::Skill into main.rs dispatch
- [ ] Update SKILL.md files in marauder-plugin to reference `marauder skill` commands
- [ ] Test: `marauder skill brew local list` works on fuji
- [ ] Test: `marauder skill cargo junkpile build --release` runs via SSH

## Phase 14 "Nemo" — Command Migration (~45m cooperative)

- [ ] Copy all command .md files from personality-plugin
- [ ] Copy command .sh scripts (gac.sh, gacp.sh, gh/cleanup.sh)
- [ ] Copy cf/ commands and scripts (14 files)
- [ ] Copy tsr/ commands (5 files)
- [ ] Update cf/ scripts: paths to `${CLAUDE_PLUGIN_ROOT}/skills/cloudflare/cf.sh`
- [ ] Update any `psn` CLI references to `marauder`
- [ ] Verify: all command .md files have valid frontmatter

## Phase 15 "Rick Dias" — Cutover (~1h cooperative)

- [ ] Register marauder-plugin in Claude Code settings (local-dev marketplace)
- [ ] Test with both plugins active (verify no tool name collisions)
- [ ] Disable personality-plugin in Claude Code settings
- [ ] Full integration test: agent dispatch, memory store/recall, TTS speak/stop
- [ ] Full integration test: hook lifecycle, index search, skill execution
- [ ] Update ~/.claude agent-memory paths if needed
- [ ] Update marauder-hq CLAUDE.md ecosystem map
- [ ] Update ~/Projects/CLAUDE.md project index

## Post-Cutover

- [ ] Archive personality-plugin repository
- [ ] Remove `psn-mcp` from PATH / uninstall personality gem
- [ ] Audit hud-bootup.js for size reduction
- [ ] Consider compiling more skills (cloudflare, cam, spotify) if shell versions cause issues
- [ ] Push marauder-plugin to GitHub
