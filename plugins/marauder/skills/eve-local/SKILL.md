---
name: EVE Local Reference
description: |
  Look up EVE Online mission guides, combat anomalies, and escalation chains from local offline files. Covers 159 L4 missions (eve-survival) and 26 Guristas hisec combat sites (EVE Uni Wiki).

  <example>
  Context: User asks about a mission
  user: "look up Gone Berserk"
  </example>

  <example>
  Context: User asks about a combat anomaly
  user: "what's in a Guristas Den?"
  </example>

  <example>
  Context: User wants escalation info
  user: "show me the Guristas escalation chain"
  </example>

  <example>
  Context: User wants specific DED site
  user: "look up the 4/10 scout outpost"
  </example>
version: 1.0.0
---

# EVE Local Reference

Offline lookup for L4 missions, Guristas combat anomalies, and DED escalation chains.

## Usage

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/eve-local/eve-local.rb"

# Mission lookup (159 L4 guides from eve-survival.org)
ruby $SKILL mission "gone berserk"
ruby $SKILL mission blockade an
ruby $SKILL mission "worlds collide" ansa

# Combat anomaly / DED site lookup (26 Guristas hisec sites)
ruby $SKILL anomaly den
ruby $SKILL anomaly "scout outpost"
ruby $SKILL anomaly "rally point"

# Escalation chain
ruby $SKILL escalation
ruby $SKILL escalation guristas
```

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `mission <name> [faction]` | `m` | Search L4 mission guides |
| `anomaly <name>` | `a` | Search Guristas anomalies and DED complexes |
| `escalation [filter]` | `e` | Show anomaly -> DED escalation mapping |

## Data Sources

| Directory | Source | Files |
|-----------|--------|-------|
| `~/Projects/eve-online/missions/` | eve-survival.org | 159 L4 guides |
| `~/Projects/eve-online/guristas-hisec/` | wiki.eveuniversity.org | 26 combat sites |
| `~/Projects/eve-online/guristas-hisec/escalations.md` | Curated | Escalation map |

## Notes

- Mission names use partial fuzzy matching — "blockade" finds all Blockade variants
- Faction codes narrow results: an, br, gu, sa, se, am, ca, ga, mi
- If multiple matches found, lists all and shows the first
- Local files only — no network calls. Use `eve-survival` skill as web fallback.
