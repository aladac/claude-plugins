---
name: gh:cleanup
description: Clean up GitHub Actions runs across aladac, saiden-dev, and tengu-apps
allowed-tools:
  - TaskCreate
  - TaskUpdate
  - Bash
  - AskUserQuestion
---

# GitHub Actions Cleanup

Delete failed, skipped, and cancelled workflow runs plus runs older than 2 weeks across all GitHub organizations.

## Standing Restrictions

- NEVER mass-delete workflow runs without presenting the count and target repos via AskUserQuestion first.
- Show how many runs will be deleted before proceeding.

## Execution Flow

1. **Scan and present for confirmation**:
   Run the cleanup script in dry-run or preview mode to determine what will be deleted. Present the count of runs and target repos via AskUserQuestion. Only proceed after approval.

2. **Create task with spinner**:
   ```
   TaskCreate(subject: "Clean up GitHub Actions", activeForm: "Cleaning up GitHub Actions runs...")
   ```

3. **Execute the cleanup script**:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/commands/gh/cleanup.sh
   ```

4. **Complete and report**:
   ```
   TaskUpdate(taskId: "...", status: "completed")
   ```
   Show the summary output from the script.

## What Gets Deleted

- **Failed** runs (conclusion: failure)
- **Skipped** runs (conclusion: skipped)
- **Cancelled** runs (conclusion: cancelled)
- **Old** runs (completed more than 2 weeks ago)

## Organizations Scanned

- `aladac` (personal)
- `saiden-dev` (open source)
- `tengu-apps` (Tengu PaaS)

## Example

User: `/gh:cleanup`

```
=== aladac ===
  aladac/ruby-esi: 5 runs (3 failed/skipped, ~2 old)
  aladac/personality: 8 runs (2 failed/skipped, ~6 old)

=== saiden-dev ===
  saiden-dev/tensors: 4 runs (0 failed/skipped, ~4 old)

=== tengu-apps ===
  (clean)

--- Summary ---
Total deleted: 17
  Failed/skipped/cancelled: 5
  Older than 2 weeks: ~12
```
