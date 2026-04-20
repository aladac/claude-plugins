---
name: Comms Rules
description: |
  Manage communication rules (C01-C21+) — brevity codes, prowords, and shortcuts stored in DB under subject `comms.C*`. View, create, update, or delete comms vocabulary.

  <example>
  Context: User wants to see all comms rules
  user: "show me the comms rules"
  </example>

  <example>
  Context: User wants to update a comms rule
  user: "update C16 shortcut to xx"
  </example>

  <example>
  Context: User wants to add a new comms rule
  user: "add a comms rule for MAYDAY"
  </example>

  <example>
  Context: User wants to remove a comms rule
  user: "drop C20"
  </example>
version: 1.0.0
---

# Comms Rules

Brevity codes and prowords for Pilot↔BT communication. Stored in the MARAUDER memory DB under subject `comms.C*`.

## Storage

- **DB subject pattern**: `comms.C01` through `comms.C21` (expandable)
- **Master index**: `comms.index` — full table of all rules with shortcuts
- **Agent memory mirror**: `~/.claude/agent-memory/marauder-core/comms_rules.md`

## Commands

| Command | Purpose |
|---------|---------|
| `/comms` | List all comms rules in a table |
| `/comms:show` | Show expanded detail for one rule |
| `/comms:update` | Modify an existing rule |
| `/comms:add` | Add a new comms rule |

## Operations

### List All

```bash
marauder memory search --subject "comms" --limit 25
```

Render as a quick reference table:

```
| # | Term | Shortcut | Meaning |
|---|------|----------|---------|
| C01 | NATO PHONETIC | — | Spell via NATO alphabet over TTS |
| C02 | WILCO | w | Will comply, executing |
| ...
```

### Show One

```bash
marauder memory recall "comms C05" --limit 1
```

Show full content of the matched rule.

### Update

1. Find the existing rule: `marauder memory search --subject "comms.C05"`
2. Note the memory ID
3. Forget the old version: `marauder memory forget <ID>`
4. Store the updated version: `marauder memory store "comms.C05" "New content"`
5. Update the master index: `comms.index`
6. Update the agent memory mirror: `comms_rules.md`

### Add

1. Determine the next available number by listing existing rules
2. Store: `marauder memory store "comms.C{N}" "Term — shortcut — description"`
3. Update `comms.index` and `comms_rules.md`

### Remove

1. Find the rule: `marauder memory search --subject "comms.C{N}"`
2. Forget it: `marauder memory forget <ID>`
3. Update `comms.index` and `comms_rules.md`

## Shortcut Interpretation

When the Pilot sends a bare shortcut (single letter or short code), interpret it as the comms rule:

| Input | Interpretation |
|-------|---------------|
| `w` | WILCO — proceed with execution |
| `n` | NEGATIVE — do not proceed |
| `a` | AFFIRM — yes, confirmed |
| `r` | ROGER — acknowledged, no action |
| `x` | EXECUTE — run now, no discussion |
| `h` | HOLD — freeze current action |
| `s` | STANDBY — wait |
| `b` | BREAK — topic change |
| `sr` | SITREP — give status report |
| `sa` | SAY AGAIN — repeat last |
| `sp` | SPLASH — confirm completion |
| `rtb` | RTB — abort, return to main context |
| `e1`/`e2`/`e3` | EMCON levels |

## Rules

- Comms rules are **mutable** — the Pilot can add, remove, or reword at any time
- Reference by number: "update C3", "drop C20"
- Always update all three locations: DB entry, master index, agent memory mirror
- When adding, suggest the next sequential number unless the Pilot specifies one

## Related
- **Skill**: `Skill(skill: "marauder:procedures")` — Operational procedures (P-series)
- **Agent**: `marauder:memory-curator` — Memory cleanup
- **Commands**: `/comms`, `/comms:show`, `/comms:update`, `/comms:add`
