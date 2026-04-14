---
name: EVE DOTLAN Maps
description: |
  Query DOTLAN EveMaps for system info, region maps, security status, sovereignty, and jump routes. Scrapes dotlan.net for structured EVE navigation intel.

  <example>
  Context: User wants system info
  user: "dotlan info on Aramachi"
  </example>

  <example>
  Context: User wants to check a route
  user: "how many jumps from Umokka to Jita"
  </example>

  <example>
  Context: User wants region overview
  user: "show me The Citadel security map"
  </example>

  <example>
  Context: User wants to check kills in a system
  user: "is Tama dangerous right now"
  </example>
version: 1.0.0
---

# EVE DOTLAN Maps Skill

Query DOTLAN EveMaps for navigation intel.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/eve-dotlan/eve-dotlan.rb"

# System info (security, stations, kills, jumps)
ruby $SKILL system Aramachi

# Route between two systems
ruby $SKILL route Umokka Jita
ruby $SKILL route Aramachi Jita --shortest
ruby $SKILL route Aramachi Jita --safest

# Region URL (opens or returns URL)
ruby $SKILL region "The Citadel" sec
ruby $SKILL region "The Citadel" sov

# Nearby systems
ruby $SKILL nearby Aramachi
```

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `system` | `<name>` | System info from dotlan |
| `route` | `<from> <to> [--shortest\|--safest]` | Jump route between systems |
| `region` | `<name> [sec\|sov]` | Region map URL |
| `nearby` | `<name>` | Adjacent systems |

## Prerequisites

- Ruby installed
- Internet access to evemaps.dotlan.net
