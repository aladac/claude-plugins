---
name: Pretty Output Pattern
description: |
  Developer reference for implementing commands with TaskCreate/TaskUpdate spinners. Not user-facing — used when building marauder commands.
disable-model-invocation: true
version: 1.0.0
---

# Pretty Output Pattern

All marauder commands should provide clean visual feedback using Claude Code's native Task system.

## Why Pretty Output

- Users see a spinner with descriptive text instead of verbose command output
- Clean, consistent experience across all commands
- Verbose details only shown on error or in final summary
- Native Claude Code UI integration

## The Pattern

### 1. Create Task at Start

```
TaskCreate(
  subject: "Brief action description",
  description: "Detailed context for task tracking",
  activeForm: "Doing the thing..."  // Shown with spinner
)
```

### 2. Do Work Silently

Run the actual operations. Output is captured, not streamed.

### 3. Update Status on Completion

```
TaskUpdate(taskId: "...", status: "completed")
```

### 4. Show Clean Summary

After completing, display a concise summary:
- Success indicator
- Key metrics (files processed, time taken, etc.)
- Any warnings

## activeForm Guidelines

The `activeForm` text appears next to a spinner. Keep it:
- **Short**: Under 40 characters
- **Active voice**: "Indexing code...", not "Code is being indexed"
- **No periods**: "Fetching zone info" not "Fetching zone info."

### Good Examples

| Operation | activeForm |
|-----------|------------|
| Store memory | "Storing memory..." |
| Recall memories | "Searching memories..." |
| Index code | "Indexing 247 files..." |
| Save session | "Saving session state..." |
| TTS speak | "Synthesizing speech..." |

### Bad Examples

- "Working..." (too vague)
- "The system is currently processing your request." (too long)
- "Running the index_code command" (too technical)

## Command Template

```markdown
---
name: action:name
description: Brief description
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - relevant_tool
argument-hint: "[args]"
---

# Action Name

Brief description.

## Execution Flow

1. **Create task with spinner**:
   - TaskCreate with descriptive activeForm

2. **Execute operation**:
   - Call relevant tools
   - Capture results

3. **Complete task**:
   - TaskUpdate to mark completed

4. **Show summary**:
   - Clean output with key info
   - Errors/warnings if any

## Example

User: `/action:name arg`

Claude creates task: "Doing action..." (spinner)
Claude executes operation
Claude completes task
Claude shows:

```
Done: processed 42 items

Details:
- 40 successful
- 2 skipped (already exists)
```
```

## Error Handling

On error:
1. Still complete the task (don't leave it hanging)
2. Show clear error message
3. Include actionable next steps

```
Error: Could not connect to database

- Check network connectivity: `ping <host>`
- Verify the service is running
```

## Multiple Operations

For commands with multiple steps, update the activeForm:

```
TaskCreate(subject: "Full operation", activeForm: "Step 1 of 3...")
// do step 1
TaskUpdate(taskId: "...", activeForm: "Step 2 of 3...")
// do step 2
TaskUpdate(taskId: "...", activeForm: "Step 3 of 3...")
// do step 3
TaskUpdate(taskId: "...", status: "completed")
```

## When NOT to Use

- Quick queries that return instantly (< 500ms)
- Interactive prompts requiring user input
- Streaming output that user needs to see in real-time

## Related Tools

| Tool | Purpose |
|------|---------|
| `TaskCreate` | Create task with spinner |
| `TaskUpdate` | Update progress or complete |
| `TaskList` | Check existing tasks |
| `TaskGet` | Get task details |
