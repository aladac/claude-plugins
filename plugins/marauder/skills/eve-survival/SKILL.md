---
name: EVE Survival
description: |
  Look up EVE Online mission guides from eve-survival.org. Fetches NPC spawns, damage types, recommended tank, triggers, and pocket layouts by mission name, level, and faction.

  <example>
  Context: User asks about a mission
  user: "look up Pirate Invasion level 4 Sansha"
  </example>

  <example>
  Context: User needs mission intel
  user: "eve survival Blockade level 3 guristas"
  </example>

  <example>
  Context: User wants to prep for a mission
  user: "what spawns in The Assault level 4?"
  </example>
version: 1.0.0
---

# EVE Survival Mission Guide

Look up mission guides from eve-survival.org — the definitive EVE mission reference.

## Usage

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/eve-survival/eve-survival.rb"

ruby $SKILL "Pirate Invasion" 4 sansha
ruby $SKILL Blockade 3 gu
ruby $SKILL "The Assault" 4
ruby $SKILL "Duo of Death" 3 angel
```

## Arguments

| Arg | Required | Description |
|-----|----------|-------------|
| mission_name | Yes | Mission name (quoted or CamelCase) |
| level | No | Level 1-5 (default: 4) |
| faction | No | Faction name or 2-letter code |

## Faction Codes

| Code | Faction |
|------|---------|
| `an` | Angel Cartel |
| `br` | Blood Raiders |
| `gu` | Guristas |
| `sa` | Sansha's Nation |
| `se` | Serpentis |
| `am` | Amarr |
| `ca` | Caldari |
| `ga` | Gallente |
| `mi` | Minmatar |
| `rd` | Rogue Drones |
| `ml` | Mordu's Legion |

## Output

Returns the full mission guide text including:
- NPC groups per pocket (ship types, quantities, range)
- Damage types dealt and recommended resist profile
- Triggers and aggro mechanics
- Bounties and loot estimates
- Tips and recommended strategies

## URL Pattern

`https://eve-survival.org/?wakka={MissionName}{Level}{Faction}`

If a faction-specific page doesn't exist, falls back to the generic (no faction) page.
