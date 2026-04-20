---
name: metrics
description: |
  Team performance metrics — session counts, prompts, tool uses, active time, weekly trends. Use when asked about productivity, stats, teaming fluency, or daily/weekly activity.

  <example>
  Context: User wants to see today's activity
  user: "how's today looking?"
  </example>

  <example>
  Context: User asks about weekly trends
  user: "show me this week's metrics"
  </example>

  <example>
  Context: User wants to store metrics
  user: "save today's metrics"
  </example>
---

# Team Performance Metrics

HMT (Human-Machine Teaming) fluency metrics derived from Claude Code hook events and session data.

## Commands

```bash
# Today's metrics
marauder metrics today

# Specific date
marauder metrics daily 2026-04-16

# 7-day trend table
marauder metrics weekly

# Store today's metrics to MARAUDER memory
marauder metrics store
```

## Workflow

When the Pilot asks about metrics, stats, or teaming performance:

1. **Run `marauder metrics today`** to get today's snapshot
2. **Run `marauder metrics weekly`** to get the 7-day trend
3. **Display the weekly table on the VISOR** via markdown viewport:
   ```
   Skill(skill: "marauder:markdown-viewport")
   ```
   Or use the `visor_markdown` MCP tool directly with the table output.
4. **Speak a brief summary** — e.g. "15 sessions today, 298 minutes active across 5 projects"
5. If asked to save, run `marauder metrics store`

## Metrics Tracked

| Metric | Source | Description |
|--------|--------|-------------|
| Sessions | SessionStart events | Number of Claude Code sessions |
| Prompts | UserPromptSubmit events | User messages sent |
| Tool uses | PreToolUse events | Total tool invocations |
| Stops | Stop events | Natural conversation ends |
| Notifications | Notification events | Agent completions |
| Permissions | PermissionRequest events | Permission prompts |
| Compactions | PreCompact/PostCompact | Context window compactions |
| Active time | Session start→end | Estimated active minutes |
| Projects | cwd from hook data | Distinct project directories |

## Data Source

Metrics are parsed from `~/.config/marauder/hooks.jsonl` — a log written by the `hooks_cmd` handler on every Claude Code lifecycle event. Each line is a JSON object with `event`, `timestamp`, and optional `data` fields.

## Storage

`marauder metrics store` saves today's aggregate to MARAUDER memory under subject `metrics.daily.YYYY-MM-DD`. This enables historical recall and trend analysis across sessions.

## Related

- **Commands**: `/marauder:proc` (operational procedures)
- **Agent**: `marauder:core` (primary assistant)
- **MCP Tools**: `mcp__plugin_marauder_core__memory_store` (for manual storage)
