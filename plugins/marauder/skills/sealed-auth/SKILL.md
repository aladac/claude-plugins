---
name: Sealed Authentication
description: |
  Handle SEALED errors from MCP tools by running the authentication protocol. Triggers when any tool returns {"sealed": true} in its response, indicating a protected operation requires passphrase verification.

  <example>
  Context: A tool returned a SEALED error
  user: (tool response contains "sealed": true)
  assistant: "SEALED OP. memory_forget (core). Authenticate."
  </example>

  <example>
  Context: Agent needs to delete a core memory
  user: "Delete memory 1234"
  assistant: (memory_forget returns SEALED) "SEALED OP. Authenticate." → [Confirm] [Cancel]
  </example>
version: 1.0.0
---

# Sealed Authentication Protocol

When any MCP tool returns a response containing `"sealed": true`, this protocol activates.

## Flow

1. **Detect** — parse the tool response for `"sealed": true` and extract the `"operation"` field
2. **Announce** — speak and display: `SEALED OP. [operation]. Authenticate.`
3. **Prompt** — use `AskUserQuestion` with exactly two options:
   - **Confirm** — proceed with authentication
   - **Cancel** — abort the operation
4. **On Cancel** — respond: "Standing down." — do NOT proceed
5. **On Confirm** — pull passphrase from 1Password and verify:

```bash
op item get sealed-auth --vault DEV --fields password --reveal
```

6. **Call `auth_verify`** — pass the retrieved passphrase to the `auth_verify` MCP tool
7. **Handle result:**
   - `"authenticated": true` → **re-call the original protected tool** (it will now succeed within the 5-min auth window)
   - `"authenticated": false` + `"error": "DENIED..."` → respond: "DENIED. Auth mismatch." with remaining attempts
   - `"locked": true` → respond: "LOCKED. Cooldown: [N] minutes."

## Protected Operations

| Operation | Tool | Trigger |
|-----------|------|---------|
| Delete core memory | `memory_forget` | Target has `classification = 'core'` |
| Store procedure | `memory_store` | Subject starts with `procedure.P` |
| Set passphrase | `auth_set` | Changing existing passphrase |

## Rules

- **NEVER** display, log, or echo the passphrase — it goes directly from `op` to `auth_verify`
- **NEVER** ask the user to type the passphrase — always pull from 1Password
- The auth window lasts 5 minutes — subsequent protected operations within that window proceed without re-authentication
- If `op` CLI fails (not installed, not signed in, item not found), report the error and do NOT proceed
- If the user selects Cancel, do NOT attempt authentication — immediately stand down
