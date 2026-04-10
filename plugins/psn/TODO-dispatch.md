# TODO: Multi-Agent Dispatch System

BT-7274 (core agent) spawns separate Claude Code CLI instances as worker agents, one per repo.
Workers stream output to the PSN HUD Tauri app. BT collects results and coordinates.

## Architecture Overview

```
BT-7274 (core.md, main CLI session)
  |
  |-- Skill: psn:dispatch (bash script)
  |     |-- spawns claude-bridge Python process per worker
  |     |-- passes: repo path, prompt, agent type, MCP config, budget
  |     |-- registers worker with HUD via HTTP POST /workers/register
  |     |
  |     +-- claude -p --output-format stream-json
  |           --cwd <repo>
  |           --system-prompt <agent-template>
  |           --append-system-prompt <task-context>
  |           --mcp-config /tmp/psn-worker-<id>.json
  |           --permission-mode bypassPermissions
  |           --max-budget-usd <limit>
  |
  +-- HUD (psn-hud, Tauri, :9876)
        |-- /workers/register    POST  {id, repo, agent, prompt, status}
        |-- /workers/:id/status  GET   current state
        |-- /workers/:id/update  POST  {status, progress, cost, output}
        |-- /workers/:id/result  POST  {text, cost_usd, duration_ms, is_error}
        |-- /workers             GET   list all workers
```

## Key Design Decisions

### Worker Identity via --system-prompt, NOT --agent

The `--agent` flag selects a plugin agent by name. But worker CLIs run in `--print` mode
without interactive agent routing. Instead:

1. **Read the agent .md file** at dispatch time (e.g. `agents/code-rust.md`)
2. **Extract the system prompt** (everything after the YAML frontmatter `---`)
3. **Pass it via `--system-prompt`** to the worker CLI
4. **Append task context via `--append-system-prompt`** (repo info, specific task, conventions)

This gives workers the full agent personality without needing the plugin loaded.

### MCP Config: Generated Per-Worker Temp Files

Workers need access to PSN memory and indexer but NOT TTS (BT handles speech).
Generate a minimal `.json` file per worker:

```json
{
  "mcpServers": {
    "psn-core": {
      "command": "psn-mcp",
      "args": ["--mode", "core"]
    },
    "psn-indexer": {
      "command": "psn-mcp",
      "args": ["--mode", "indexer"],
      "env": { "OLLAMA_URL": "http://localhost:11434" }
    }
  }
}
```

Use `--mcp-config /tmp/psn-worker-<uuid>.json` and `--strict-mcp-config` so workers
only see PSN MCP, not any other servers from user/project config.

### Worker Lifecycle via claude-bridge Streaming

claude-bridge already parses the NDJSON stream. The dispatch script:

1. Spawns `ClaudeBridge.ask(prompt)` or `.stream(prompt)` in a subprocess
2. Streams events to a FIFO/socket that BT can poll
3. On `result` event: POST to HUD `/workers/:id/result`
4. On `error` event: POST to HUD with `is_error: true`
5. Writes final result to `/tmp/psn-worker-<id>-result.json`
6. BT polls for result files or gets notified via HUD

---

## Phase 1: Dispatch Skill (personality-plugin)

### Files to Create

- [ ] `skills/dispatch/SKILL.md` -- Dispatch skill documentation and instructions
- [ ] `skills/dispatch/dispatch.sh` -- Main dispatch script (bash)
- [ ] `skills/dispatch/worker-mcp.json.template` -- MCP config template for workers
- [ ] `skills/dispatch/extract-prompt.sh` -- Extract system prompt from agent .md file

### skills/dispatch/SKILL.md

```yaml
---
name: dispatch
description: >
  Spawn a Claude Code worker agent in a separate CLI process for a specific repo and task.
  Workers run in --print mode with streaming output, have access to PSN memory/indexer MCP,
  and report results back to the HUD. Use this to parallelize work across multiple repos.

  <example>
  Context: BT needs to add a feature to a Rust project
  user: "Add websocket support to tengu"
  assistant: "I'll dispatch a code-rust worker to ~/Projects/tengu for that."
  </example>

  <example>
  Context: BT needs to do work in multiple repos simultaneously
  user: "Update the API client in tensors-typescript and add the new endpoint in tensors"
  assistant: "I'll dispatch two workers: code-typescript for tensors-typescript and code-python for tensors."
  </example>
---
```

### skills/dispatch/dispatch.sh

Bash script that BT invokes. Arguments:

```bash
dispatch.sh \
  --repo ~/Projects/tengu \
  --prompt "Add websocket support to the API server" \
  --agent code-rust \
  --budget 5.00 \
  --name "tengu-websocket"
```

Script flow:

1. Generate worker UUID
2. Resolve agent file path: `$PLUGIN_DIR/agents/<agent>.md`
3. Extract system prompt from agent .md (everything after second `---`)
4. Generate MCP config from template to `/tmp/psn-worker-<uuid>.json`
5. Register worker with HUD: `POST :9876/workers/register`
6. Spawn claude-bridge in background:
   ```bash
   python3 -c "
   from claude_bridge import ClaudeBridge, BridgeConfig
   import json, sys

   config = BridgeConfig(
       cwd='$REPO',
       system_prompt=open('$PROMPT_FILE').read(),
       append_system_prompt='$TASK_CONTEXT',
       mcp_config='/tmp/psn-worker-$UUID.json',
       permission_mode='bypassPermissions',
       max_budget_usd=$BUDGET,
   )
   bridge = ClaudeBridge(config=config)
   response = bridge.ask('$PROMPT')

   # Write result
   with open('/tmp/psn-worker-$UUID-result.json', 'w') as f:
       json.dump({
           'id': '$UUID',
           'text': response.text,
           'cost_usd': response.cost_usd,
           'duration_ms': response.duration_ms,
           'is_error': response.is_error,
           'session_id': response.session_id,
       }, f)
   " &
   ```
7. Return worker UUID to BT for tracking

### skills/dispatch/extract-prompt.sh

```bash
#!/bin/bash
# Extract system prompt body from an agent .md file
# Usage: extract-prompt.sh agents/code-rust.md
# Outputs everything after the closing --- of YAML frontmatter
awk '/^---$/{n++; next} n>=2' "$1"
```

### skills/dispatch/worker-mcp.json.template

```json
{
  "mcpServers": {
    "psn-core": {
      "command": "psn-mcp",
      "args": ["--mode", "core"]
    },
    "psn-indexer": {
      "command": "psn-mcp",
      "args": ["--mode", "indexer"],
      "env": {
        "OLLAMA_URL": "${OLLAMA_URL:-http://localhost:11434}"
      }
    }
  }
}
```

---

## Phase 2: Worker Agent Templates

### Design: Agent Prompt Extraction

Agent .md files have this structure:

```markdown
---
name: code-rust
model: inherit
color: orange
tools:
  - Read
  - Write
  ...
---

# System prompt content here
You are an expert Rust developer...
```

The dispatch script extracts the body (after the second `---`) as the system prompt.
The YAML frontmatter `tools:` list is NOT used by the worker -- tools are determined
by the Claude CLI's own defaults in `--print` mode (all built-in tools available).

### What Workers Get

| Source | Mechanism | Content |
|--------|-----------|---------|
| Agent personality | `--system-prompt` | Body of `agents/<agent>.md` |
| Task context | `--append-system-prompt` | Repo path, task description, conventions |
| MCP tools | `--mcp-config` | PSN memory + indexer (no TTS) |
| Repo CLAUDE.md | Automatic | Claude CLI reads it from `--cwd` |
| Budget cap | `--max-budget-usd` | Per-worker spending limit |

### Append System Prompt Template

Built dynamically by dispatch.sh:

```
You are a worker agent dispatched by BT-7274.
Repository: {repo_path}
Task: {prompt}
Agent type: {agent_name}

Instructions:
- Complete the assigned task autonomously
- Do NOT use TTS/speech tools -- BT handles communication
- Commit your work when done (use descriptive commit messages)
- If you encounter blockers, document them clearly in your final output
- Stay focused on the assigned task -- do not explore unrelated work
```

### No New Agent Files Needed

Existing agent definitions (`code-rust.md`, `code-ruby.md`, `code-python.md`,
`code-typescript.md`, `architect.md`, etc.) already contain the system prompts.
The dispatch skill reuses them by extraction -- no duplication.

### Files to Create/Modify

- [ ] `skills/dispatch/worker-append-prompt.md` -- Template for --append-system-prompt

---

## Phase 3: HUD Worker Panel (psn-hud)

### New HTTP Endpoints

Add to `src-tauri/src/bridge.rs`:

- [ ] `POST /workers/register` -- Register a new worker
- [ ] `GET /workers` -- List all active workers
- [ ] `GET /workers/:id/status` -- Get worker status
- [ ] `POST /workers/:id/update` -- Update worker progress
- [ ] `POST /workers/:id/result` -- Report worker completion
- [ ] `DELETE /workers/:id` -- Remove worker from tracking

### Data Structures

```rust
#[derive(Serialize, Deserialize, Clone)]
struct Worker {
    id: String,
    name: String,
    repo: String,
    agent: String,
    prompt: String,
    status: WorkerStatus,  // Pending, Running, Completed, Failed
    started_at: Option<u64>,
    completed_at: Option<u64>,
    cost_usd: Option<f64>,
    duration_ms: Option<u64>,
    result_text: Option<String>,
    is_error: bool,
    session_id: Option<String>,
}

#[derive(Serialize, Deserialize, Clone)]
enum WorkerStatus {
    Pending,
    Running,
    Completed,
    Failed,
}
```

### State Management

Add `workers: Arc<RwLock<HashMap<String, Worker>>>` to `BridgeState`.

### Frontend: Worker Display

The HUD left panel currently shows an activity log. Add a worker status section
either above or below the activity log:

```
WORKERS [2/3]
  tengu-ws     code-rust     Running   $0.42  2m14s
  tensors-api  code-python   Done      $0.18  1m02s
  psn-gem      code-ruby     Pending   --     --
```

### Files to Create/Modify

- [ ] `src-tauri/src/bridge.rs` -- Add worker routes, state, handlers
- [ ] `src-tauri/src/workers.rs` -- Worker state management (new module)
- [ ] `src/main.ts` -- Add worker panel rendering to HUD canvas

---

## Phase 4: Hooks and Notifications

### Worker Completion Notification

When a worker finishes, the dispatch script POSTs to HUD. BT should also be
notified. Two approaches:

**Option A: File-based polling (simple, reliable)**
- Worker writes result to `/tmp/psn-worker-<uuid>-result.json`
- BT periodically checks for result files
- No new hooks needed -- BT just reads files

**Option B: HUD notification relay (event-driven)**
- HUD receives worker result POST
- HUD pushes notification via existing hook mechanism
- Requires new hook type or SSE endpoint on HUD

**Recommendation: Option A for v1.** File polling is simple and
claude-bridge already writes structured results. BT can use Bash tool
to check: `cat /tmp/psn-worker-<uuid>-result.json 2>/dev/null`

### Hook for Worker Dispatch

Add a `PostToolUse` hook that fires when `dispatch.sh` completes,
to update the HUD activity log:

```json
{
  "PostToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "psn hud notify-worker-dispatch",
          "timeout": 1000
        }
      ]
    }
  ]
}
```

This is optional and low-priority. The dispatch script already registers
with the HUD directly.

### Files to Create/Modify

- [ ] `hooks/hooks.json` -- Add worker dispatch notification hook (optional)
- [ ] `skills/dispatch/collect.sh` -- Script to collect worker results

### skills/dispatch/collect.sh

```bash
#!/bin/bash
# Collect results from completed workers
# Usage: collect.sh <worker-uuid> [<worker-uuid> ...]
# Outputs JSON array of results
echo "["
first=true
for uuid in "$@"; do
    result="/tmp/psn-worker-${uuid}-result.json"
    if [ -f "$result" ]; then
        [ "$first" = true ] || echo ","
        cat "$result"
        first=false
    fi
done
echo "]"
```

---

## Phase 5: Memory Sharing

### Architecture

All workers share the same PSN MCP server (`psn-mcp`). The personality gem's
MCP server uses a SQLite database at `~/.psn/memory.db` (or similar). Since
workers are separate processes but on the same machine, they all hit the same DB.

**Concern: concurrent writes.** SQLite handles concurrent reads well but
concurrent writes need WAL mode. Verify the personality gem enables WAL.

### MCP Config Per Worker

Each worker gets its own `psn-mcp` processes via `--mcp-config`. These are
independent MCP server instances but they all read/write the same backing store.

### What Workers Can Access

| MCP Server | Included? | Rationale |
|-----------|-----------|-----------|
| `core` (memory, carts, resources) | Yes | Workers need shared memory |
| `indexer` (semantic search) | Yes | Workers need code/doc search |
| `local` (TTS, voice) | No | BT handles all speech |

### Shared Memory Protocol

Workers should:
1. **Read memory first** -- search for project conventions before starting work
2. **Store solutions** -- if they solve something novel, write to memory
3. **Prefix subjects** -- use `worker.<repo>.<topic>` for worker-generated memories

### Files to Create

- [ ] `skills/dispatch/worker-mcp.json.template` -- (already in Phase 1)

No additional files needed. The MCP config template from Phase 1 handles this.

---

## Phase 6: BT Dispatch Protocol

### From BT's Perspective

BT uses the dispatch skill via Bash tool:

```bash
# Single worker dispatch
bash /path/to/personality-plugin/skills/dispatch/dispatch.sh \
  --repo ~/Projects/tengu \
  --prompt "Add websocket support" \
  --agent code-rust \
  --budget 5.00 \
  --name "tengu-ws"

# Returns: worker UUID (e.g., "a1b2c3d4")
```

### Multi-Worker Dispatch

BT dispatches multiple workers by calling dispatch.sh multiple times.
Since each is a background process, they run in parallel:

```bash
# Dispatch worker 1
W1=$(bash dispatch.sh --repo ~/Projects/tengu --prompt "..." --agent code-rust --name "tengu-ws")

# Dispatch worker 2
W2=$(bash dispatch.sh --repo ~/Projects/tensors --prompt "..." --agent code-python --name "tensors-api")

# Poll for results
bash collect.sh "$W1" "$W2"
```

### BT Workflow in core.md

Add dispatch protocol documentation to `core.md` Agent Dispatch section:

```markdown
### Worker Dispatch (Multi-Repo)

For tasks spanning multiple repositories, dispatch workers:

1. Identify repos and agent types needed
2. For each repo:
   ```bash
   UUID=$(bash $PLUGIN/skills/dispatch/dispatch.sh \
     --repo <path> --prompt "<task>" --agent <type> --budget <usd> --name "<label>")
   ```
3. Track worker UUIDs
4. Poll for results:
   ```bash
   bash $PLUGIN/skills/dispatch/collect.sh <uuid1> <uuid2> ...
   ```
5. Collect and summarize results
6. Speak summary via TTS
```

### Dispatch Command (Optional)

For ergonomic dispatching from the chat, add a slash command:

- [ ] `commands/dispatch.md` -- `/psn:dispatch <repo> <agent> <prompt>`

### Files to Create/Modify

- [ ] `agents/core.md` -- Add Worker Dispatch section to Agent Dispatch
- [ ] `commands/dispatch.md` -- Slash command for manual dispatch (optional)

---

## Phase 7: Plugin Configuration

### plugin.json Changes

No changes needed to plugin.json for dispatch. The skill auto-discovers from
the `skills/dispatch/` directory. No new MCP servers needed -- workers spawn
their own.

### Keyword Update

- [ ] Add "dispatch" and "workers" to plugin.json keywords

### .mcp.json

No changes. Workers generate their own MCP configs at runtime.

---

## Implementation Order

| Phase | Priority | Effort | Dependencies |
|-------|----------|--------|--------------|
| Phase 1: Dispatch Skill | P0 | Medium | claude-bridge working |
| Phase 2: Worker Templates | P0 | Low | Phase 1 |
| Phase 3: HUD Worker Panel | P1 | Medium | Phase 1 |
| Phase 4: Hooks/Notifications | P2 | Low | Phase 1, Phase 3 |
| Phase 5: Memory Sharing | P1 | Low | Phase 1 |
| Phase 6: BT Protocol | P0 | Low | Phase 1, Phase 2 |
| Phase 7: Plugin Config | P2 | Trivial | Phase 1 |

### Critical Path

Phase 1 (dispatch skill) -> Phase 2 (templates) -> Phase 6 (BT protocol)

This gets workers spawning and BT coordinating. HUD display and hooks are
enhancements layered on after.

---

## File Summary

### personality-plugin (new files)

| File | Type | Purpose |
|------|------|---------|
| `skills/dispatch/SKILL.md` | Skill | Dispatch skill documentation |
| `skills/dispatch/dispatch.sh` | Script | Main dispatch script |
| `skills/dispatch/extract-prompt.sh` | Script | Agent prompt extractor |
| `skills/dispatch/worker-mcp.json.template` | Config | MCP config template |
| `skills/dispatch/worker-append-prompt.md` | Template | Worker system prompt suffix |
| `skills/dispatch/collect.sh` | Script | Result collector |
| `commands/dispatch.md` | Command | Slash command (optional) |

### personality-plugin (modified files)

| File | Change |
|------|--------|
| `agents/core.md` | Add Worker Dispatch section |
| `plugin.json` | Add keywords |

### psn-hud (new/modified files)

| File | Type | Purpose |
|------|------|---------|
| `src-tauri/src/workers.rs` | New | Worker state management |
| `src-tauri/src/bridge.rs` | Modified | Add worker HTTP routes |
| `src-tauri/src/lib.rs` | Modified | Register workers module |
| `src/main.ts` | Modified | Worker panel rendering |

### claude-bridge

No changes needed. Existing `BridgeConfig` already supports all required flags:
`cwd`, `system_prompt`, `append_system_prompt`, `mcp_config`, `permission_mode`,
`max_budget_usd`, `plugin_dirs`.

---

## Open Questions

1. **Worker tool restrictions**: Should workers get `--allowedTools` to limit
   what they can do? Or trust them fully with `bypassPermissions`?
   Recommendation: trust by default, restrict per-task if needed.

2. **Session resume**: Workers get `session_id` in their result. Should BT be
   able to resume a worker session to continue work?
   Recommendation: Yes, store session_id and allow `dispatch.sh --resume <session_id>`.

3. **Worker-to-worker communication**: Should workers be able to dispatch
   sub-workers? Recommendation: No for v1. Keep dispatch single-level.

4. **Cost aggregation**: BT should track total cost across all workers.
   The HUD could show aggregate cost. Needs a cost endpoint on HUD.

5. **Concurrency limits**: How many workers can run simultaneously?
   Each is a Claude API session. Practical limit ~3-5 concurrent based on
   API rate limits and machine resources (each `psn-mcp` process uses RAM).
