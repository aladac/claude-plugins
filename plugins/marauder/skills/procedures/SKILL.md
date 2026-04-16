---
name: Operational Procedures
description: |
  Manage operational procedures (P01-P10+) — mutable standing orders stored in DB under subject `procedure.P*`. View, create, update, or delete behavioral directives.

  <example>
  Context: User wants to see all procedures
  user: "show me the procedures"
  </example>

  <example>
  Context: User wants to update a procedure
  user: "update P03 to include NAS sync"
  </example>

  <example>
  Context: User wants to add a new procedure
  user: "add a procedure about always checking disk space before large operations"
  </example>

  <example>
  Context: User wants to remove a procedure
  user: "drop P07"
  </example>
version: 1.0.0
---

# Operational Procedures

Mutable standing orders governing BT-7274 behavior. Lower priority than system prompt rules but higher than ad-hoc instructions. Stored in the PSN memory DB under subject `procedure.P*`.

## Storage

- **DB subject pattern**: `procedure.P01` through `procedure.P10` (expandable)
- **Format**: `Title — Description with rationale`
- **CLI access**: `marauder memory search --subject procedure`

## Commands

| Command | Purpose |
|---------|---------|
| `/proc` | List all procedures in a table |
| `/proc:show` | Show expanded detail for one procedure |
| `/proc:update` | Modify an existing procedure |
| `/proc:add` | Add a new procedure |

## Operations

### List All

```bash
marauder memory search --subject "procedure" --limit 20
```

Render as a numbered table with ID, title, and one-line summary.

### Show One

```bash
marauder memory recall "procedure P03" --limit 1
```

Show full content of the matched procedure.

### Update

1. Find the existing procedure by number: `marauder memory search --subject "procedure.P03"`
2. Note the memory ID from the result
3. Forget the old version: `marauder memory forget <ID>`
4. Store the updated version: `marauder memory store "procedure.P03" "New content"`

### Add

1. Determine the next available number by listing existing procedures
2. Store: `marauder memory store "procedure.P{N}" "Title — Description"`

### Remove

1. Find the procedure: `marauder memory search --subject "procedure.P{N}"`
2. Forget it: `marauder memory forget <ID>`
3. Optionally renumber remaining procedures

## Display

When showing procedures, use this table format:

```
| # | Procedure | Summary |
|---|-----------|---------|
| P01 | Verify Before Acting | Never assume current state... |
| P02 | Terse by Default | No trailing summaries... |
```

Optionally push to the visor via `POST /code` with language "markdown" for HUD display.

## Rules

- Procedures are **mutable** — the Pilot can add, remove, reorder, or reword at any time
- Reference by number: "update P3", "drop P7", "swap P3 and P5"
- Always confirm destructive operations (drop, renumber) before executing
- When adding, suggest the next sequential number unless the Pilot specifies one

## Related
- **Skill**: `Skill(skill: "marauder:memory")` - Memory patterns
- **Agent**: `marauder:memory-curator` - Memory cleanup
- **Commands**: `/proc`, `/proc:show`, `/proc:update`, `/proc:add`
