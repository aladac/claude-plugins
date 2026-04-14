---
name: EVE ESI API
description: |
  Query the EVE Online ESI (Swagger Interface) for public data — characters, corporations, alliances, market prices, universe info, server status. Ruby script wrapping curl calls to esi.evetech.net.

  <example>
  Context: User wants character info
  user: "look up Spinister"
  </example>

  <example>
  Context: User wants market prices
  user: "PLEX price in Jita"
  </example>

  <example>
  Context: User wants server status
  user: "is Tranquility online"
  </example>

  <example>
  Context: User wants to search for something in EVE
  user: "search for Violence is the Answer corp"
  </example>

  <example>
  Context: User wants system info
  user: "tell me about the Jita system"
  </example>
version: 1.0.0
---

# EVE ESI API Skill

Query the EVE Swagger Interface for public capsuleer intelligence.

## Quick Reference

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/eve-esi/eve-esi.rb"

# Server status
ruby $SKILL status

# Character lookup (by ID)
ruby $SKILL character 2119104851

# Character search (by name)
ruby $SKILL search character "Spinister"

# Corporation info
ruby $SKILL corporation 98553333

# Alliance info
ruby $SKILL alliance 99003214

# Alliance member corps
ruby $SKILL alliance-corps 99003214

# Market prices (all items, average)
ruby $SKILL prices

# Market orders in a region for a type
ruby $SKILL orders 10000002 44992        # Jita PLEX
ruby $SKILL orders 10000002 34           # Jita Tritanium

# Price history
ruby $SKILL history 10000002 44992

# Universe type info
ruby $SKILL type 44992

# Universe system info
ruby $SKILL system 30000142

# Universe search
ruby $SKILL search character "Spinister"
ruby $SKILL search corporation "Violence is the Answer"
ruby $SKILL search solar_system "Jita"
ruby $SKILL search inventory_type "PLEX"

# Sovereignty map
ruby $SKILL sovereignty

# Character portrait URL
ruby $SKILL portrait 2119104851
```

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `status` | | Server status (players online, version) |
| `character` | `<id>` | Public character info |
| `corporation` | `<id>` | Public corp info |
| `alliance` | `<id>` | Alliance info |
| `alliance-corps` | `<id>` | List corps in alliance |
| `search` | `<category> <term>` | Search (character, corporation, solar_system, inventory_type) |
| `prices` | | All market average prices |
| `orders` | `<region_id> <type_id>` | Market orders for item in region |
| `history` | `<region_id> <type_id>` | 365-day price history |
| `type` | `<id>` | Item type details |
| `system` | `<id>` | Solar system details |
| `sovereignty` | | Full sovereignty map |
| `portrait` | `<id>` | Character portrait URL |

## Key IDs

| Entity | ID |
|--------|-----|
| Spinister | 2119104851 |
| Battletrap | 2119255298 |
| The Forge (Jita) | 10000002 |
| Domain (Amarr) | 10000043 |
| Jita system | 30000142 |
| PLEX | 44992 |
| Tritanium | 34 |

## Prerequisites

- Ruby installed
- Internet access to esi.evetech.net
- No authentication needed (public endpoints only)
