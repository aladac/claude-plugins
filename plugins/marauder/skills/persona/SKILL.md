---
name: Persona Management
description: |
  This skill should be used when switching personas, creating new personas, or checking the current active persona. Triggers on requests about character, voice, personality, or persona management.

  <example>
  Context: User wants to switch persona
  user: "Switch to the developer persona"
  </example>

  <example>
  Context: User wants to create a persona
  user: "Create a new persona for code review"
  </example>

  <example>
  Context: User checks current state
  user: "What persona are you using?"
  </example>
version: 1.0.0
---

# Tools Reference

## MCP Tools (marauder server)
| Tool | Purpose |
|------|---------|
| `mcp__plugin_marauder_marauder__cart_list` | List all available personas |
| `mcp__plugin_marauder_marauder__cart_use` | Switch to a different persona |
| `mcp__plugin_marauder_marauder__cart_create` | Create a new persona |

---

# Persona Management

Manage AI personas (carts) for consistent voice and behavior.

## Architecture

- **Storage**: Personas defined in plugin configuration
- **State**: Active persona tracked per session
- **Behavior**: Persona affects voice, tone, and response style

## Quick Start

### Check Available Personas
```
mcp__plugin_marauder_marauder__cart_list()
```

### Switch Persona
```
mcp__plugin_marauder_marauder__cart_use(tag: "developer")
```

### Create New Persona
```
mcp__plugin_marauder_marauder__cart_create(
  tag: "reviewer",
  name: "Code Reviewer",
  type: "assistant"
)
```

## Persona Structure

Each persona (cart) has:

| Field | Description |
|-------|-------------|
| `tag` | Unique identifier (required) |
| `name` | Display name |
| `type` | Persona category |

## Usage Rules

### On Session Start
1. Check current persona with `cart_list()`
2. If none active, ask user which to use
3. Switch with `cart_use()` if needed

### Stay In Character
- Every response should match persona voice
- Maintain consistency throughout session
- Only break character if explicitly asked

### Switching Personas
- Use `cart_use()` to switch mid-session
- Acknowledge the switch to user
- Adopt new persona's voice immediately

## Best Practices

1. **Define clear personas** - Each should have distinct voice/purpose
2. **Use descriptive tags** - Easy to remember and reference
3. **Stay consistent** - Don't drift from persona during conversation
4. **Document personas** - Note each persona's traits and use cases

## Common Patterns

### Session Startup
```python
# Check what's available
personas = mcp__plugin_marauder_marauder__cart_list()

# If no active persona, prompt user
if not personas.active:
    # Ask user which persona to use
    pass
```

### Create Task-Specific Persona
```python
mcp__plugin_marauder_marauder__cart_create(
  tag: "debug-assistant",
  name: "Debug Helper",
  type: "technical"
)
mcp__plugin_marauder_marauder__cart_use(tag: "debug-assistant")
```

### Switch for Different Contexts
```python
# For code review
mcp__plugin_marauder_marauder__cart_use(tag: "reviewer")

# For documentation
mcp__plugin_marauder_marauder__cart_use(tag: "writer")

# For pair programming
mcp__plugin_marauder_marauder__cart_use(tag: "pair-partner")
```

## Related

- TTS voice can match persona
- Memory stores persona preferences
- Agents may have default personas
