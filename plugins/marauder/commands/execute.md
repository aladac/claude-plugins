---
description: Execute PLAN.md phase by phase with commit gates between phases
---
Execute the implementation plan phase by phase. Read PLAN.md and TODO.md from the current project, implement each phase, stop for review and commit approval between phases.

## Instructions

1. **Read the plan** — read `PLAN.md` and `TODO.md` from the current project root. If neither exists, stop and tell the Pilot.
2. **Branch gate** — before any implementation work, check if you are on the correct feature branch:
   - If on `main`/`master`, you MUST create a feature branch first.
   - Use AskUserQuestion to propose a branch name (e.g., `feature/phase-28-sere-display`) and ask the Pilot to confirm yes/no.
   - Only proceed after the Pilot approves the branch name. Create the branch and switch to it.
   - If already on a feature branch that matches the plan, confirm with the Pilot and continue.
   - PLAN.md and TODO.md are **feature-branch-bound** — they live on the feature branch, not on main/master. This prevents overwriting plans for other features.
3. **Recall context** — search memory for project-specific decisions, conventions, and calibration data before starting.
4. **Work in chunks, not phases** — break each phase into 2-4 logical commits. Each commit should represent one reasoning step that a reviewer can follow (e.g., "add migration", "add model", "add specs" — not one blob). Never create a single-commit PR.
5. **Implement one chunk** — complete the smallest logical unit of work within the phase.
6. **Run tests** — if the project has a test suite, run relevant specs. If tests fail, stop and present the issue. Do NOT continue to the commit gate with failing tests.
7. **Present chunk results** — after completing a chunk (tests passing), stop and show:
   - Summary of what was implemented
   - Files changed (`git diff --stat`)
   - Any decisions made or deviations from the plan
   - Test results
8. **Wait for commit approval** — use AskUserQuestion to present the chunk for review. Accept any of: `x`, `ok`, `go`, `commit`, `y`, `yes`. If the Pilot gives feedback or corrections, apply them before re-presenting.
9. **Commit the chunk** — use a descriptive single-sentence commit message. Do NOT push unless the Pilot says to. Never squash commits — the lead requires reviewers to follow reasoning through commit history.
10. **Continue to next chunk** — repeat from step 5 for the next chunk within the phase, or move to the next phase when all chunks are committed.
11. **After final phase** — present overall summary, update TODO.md (mark completed tasks), and ask if the Pilot wants to push.

## Rules

- **One phase at a time** — never implement ahead. The Pilot may want to adjust the plan between phases.
- **Multiple commits per PR** — never create single-commit PRs. Break work into logical steps. Each commit = one reasoning step a reviewer can follow.
- **Never squash** — commits tell the story. The lead requires reviewable commit history.
- **Stop on failure** — if tests fail, a dependency is missing, or something unexpected happens, stop immediately. Present the problem and wait for guidance.
- **Track progress** — use TaskCreate/TaskUpdate to show progress within large phases.
- **Mark TODO.md** — after each committed phase, update TODO.md to check off completed tasks (`- [x]`).
- **No skipping** — implement phases in order unless the Pilot explicitly says to skip one.
- **Deviations** — if you need to deviate from the plan (better approach found, blocker discovered), explain why at the phase gate. Do not silently change the approach.

## Resuming

If the session started mid-plan (some phases already committed), detect completed phases from TODO.md checkmarks and git history, then continue from the next incomplete phase.
