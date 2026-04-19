# PLAN: Forced Output Style for MARAUDER Plugin

**Date:** 2026-04-19
**Branch:** `feature/output-style`
**Goal:** Enforce BT-7274 persona voice at the Claude Code harness level via `forceForPlugin` output style

## Context

Claude Code plugins can ship `output-styles/*.md` files. When frontmatter includes `force-for-plugin: true`, the style auto-applies as a system prompt layer whenever the plugin is active. This is a **third prompt layer** — independent of CLAUDE.md and agent frontmatter — that operates at the harness level on every response.

Currently, persona voice depends on the core agent prompt loading. If Claude responds before agent dispatch, or in contexts where the agent prompt isn't injected, persona consistency breaks. A forced output style fixes this structurally.

## Discovery

Source analysis of Claude Code (`src/utils/plugins/loadPluginOutputStyles.ts`):
- Plugin loader auto-discovers `output-styles/` directory
- Each `.md` file becomes a style, namespaced as `marauder:<styleName>`
- Frontmatter key is `force-for-plugin: true` (not camelCase)
- `keepCodingInstructions` flag preserves default coding behaviour
- Style prompt replaces the default system prompt unless `keepCodingInstructions` is set

## Phases

### Phase 1: Create Output Style (15 min)

Create `output-styles/marauder.md` with:
- Frontmatter: name, description, `force-for-plugin: true`
- Persona voice rules (terse, military comms, no trailing summaries)
- TTS integration reminders (speak key responses)
- Memory-first workflow reminder
- Must NOT duplicate agent-level detail — keep it light, behavioural only

The output style complements the core agent prompt:
- **Output style** = voice, tone, formatting rules (always active)
- **Core agent prompt** = full dispatch logic, tool reference, procedures (loaded per agent)

### Phase 2: Update Plugin Manifest (5 min)

Check if `plugin.json` needs `outputStyles` or `outputStylesPaths` entries. Based on source analysis, the plugin loader auto-discovers `output-styles/` directory — no manifest change needed. Verify.

### Phase 3: Test (10 min)

- Reinstall plugin via `/plugin-reinstall`
- Restart session
- Verify output style appears in `/output-style` list as `marauder:marauder`
- Verify it auto-applies (check style name in status line)
- Test persona voice consistency in direct conversation (no agent dispatch)
- Test that coding instructions are preserved

## Risks

- **Prompt conflict:** Output style prompt could conflict with core agent prompt. Mitigate by keeping the style lightweight — voice/tone only, no tool instructions.
- **Token overhead:** Extra system prompt layer costs tokens. Keep under 500 words.
- **Override issues:** If user manually switches output style, the forced style may not re-apply until session restart. Acceptable.

## Non-Goals

- Dynamic persona switching via output styles (future — would need style-per-cart)
- Proactive mode integration (separate feature)
- System-reminder enhancement (separate feature)
