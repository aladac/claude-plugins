---
name: EVE University Wiki
description: |
  Search and read the EVE University Wiki (wiki.eveuniversity.org) via MediaWiki API. Ship fits, game mechanics, mission guides, PvP tactics, exploration, industry — the most comprehensive EVE learning resource.

  <example>
  Context: User wants ship info
  user: "look up the Tengu on eve uni"
  </example>

  <example>
  Context: User wants to learn a mechanic
  user: "eve uni page on shield tanking"
  </example>

  <example>
  Context: User searches for a topic
  user: "search eve uni for wormhole classes"
  </example>

  <example>
  Context: User wants a specific section
  user: "show me the fittings section for Vargur"
  </example>
version: 1.0.0
---

# EVE University Wiki

Search and read the EVE University Wiki — the most comprehensive EVE Online knowledge base.

## Usage

```bash
SKILL="${CLAUDE_PLUGIN_ROOT}/skills/eve-uni/eve-uni.rb"

# Search
ruby $SKILL search "shield tanking"
ruby $SKILL search "level 4 missions"

# Full page
ruby $SKILL page "Tengu"
ruby $SKILL page "Pirate Invasion"

# Specific section
ruby $SKILL section "Tengu" "Fittings"
ruby $SKILL section "Shield Tanking" "Modules"

# Categories
ruby $SKILL categories "Caldari ships"
```

## Commands

| Command | Args | Description |
|---------|------|-------------|
| `search` | `<query>` | Search wiki pages, returns top 15 results with snippets |
| `page` | `<title>` | Get full page content (HTML converted to text) |
| `section` | `<title> <section>` | Get a specific section from a page |
| `categories` | `<title>` | List categories for a page |

## Output

Returns structured text with:
- Page title and URL
- Categories
- Full content converted from HTML to readable text
- Section headers preserved as markdown

## Notes

- Uses the MediaWiki API at `wiki.eveuniversity.org/api.php`
- Page titles are case-sensitive (first letter capitalized)
- If a page isn't found by exact title, falls back to search
- No authentication required — all content is public
