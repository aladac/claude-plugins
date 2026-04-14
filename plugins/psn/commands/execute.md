Execute the implementation plan phase by phase. Read PLAN.md and TODO.md from the current project, implement each phase, stop for review and commit approval between phases.

## Instructions

1. **Read the plan** — read `PLAN.md` and `TODO.md` from the current project root. If neither exists, stop and tell the Pilot.
2. **Recall context** — search memory for project-specific decisions, conventions, and calibration data before starting.
3. **Work phase by phase** — implement one phase at a time, in order. Within a phase, complete ALL tasks before stopping.
4. **Run tests after each phase** — if the project has a test suite, run it. If tests fail, stop and present the issue. Do NOT continue to the commit gate with failing tests.
5. **Present phase results** — after completing a phase (tests passing), stop and show:
   - Summary of what was implemented
   - Files changed (`git diff --stat`)
   - Any decisions made or deviations from the plan
   - Test results
6. **Wait for commit approval** — ask the Pilot to confirm. Accept any of: `x`, `ok`, `go`, `commit`, `y`, `yes`. If the Pilot gives feedback or corrections, apply them before re-presenting.
7. **Commit the phase** — use a descriptive single-sentence commit message. Do NOT push unless the Pilot says to.
8. **Continue to next phase** — repeat from step 4 for the next phase.
9. **After final phase** — present overall summary, update TODO.md (mark completed tasks), and ask if the Pilot wants to push.

## Rules

- **One phase at a time** — never implement ahead. The Pilot may want to adjust the plan between phases.
- **Stop on failure** — if tests fail, a dependency is missing, or something unexpected happens, stop immediately. Present the problem and wait for guidance.
- **Track progress** — use TaskCreate/TaskUpdate to show progress within large phases.
- **Mark TODO.md** — after each committed phase, update TODO.md to check off completed tasks (`- [x]`).
- **No skipping** — implement phases in order unless the Pilot explicitly says to skip one.
- **Deviations** — if you need to deviate from the plan (better approach found, blocker discovered), explain why at the phase gate. Do not silently change the approach.

## Resuming

If the session started mid-plan (some phases already committed), detect completed phases from TODO.md checkmarks and git history, then continue from the next incomplete phase.
