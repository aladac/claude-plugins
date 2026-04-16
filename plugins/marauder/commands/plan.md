---
description: Create PLAN.md and TODO.md from design analysis and agent validation
---
Plan implementation for a project. Analyze all design suggestions, validate with architect and code agents, then create PLAN.md and TODO.md in the project repo.

## Instructions

1. **Gather context** — search memory for all design suggestions, decisions, and references related to the current project
2. **Dispatch architect agent** — validate architecture, identify risks, propose structure
3. **Dispatch code agent(s)** — validate technical feasibility, check APIs exist, confirm dependencies
4. **Create PLAN.md** — detailed implementation plan with phases, components, and dependencies
5. **Create TODO.md** — ordered task list with cooperative effort estimates (see ETA rules below)
6. **Present status** — summarize what was planned and wait for implementation confirmation

Do NOT start implementing. Plan only. Present the plan and wait for explicit "go" from the Pilot.

## ETA Rules — Cooperative Velocity

**All estimates MUST reflect cooperative Pilot + Titan velocity, not human-solo speed.**

Before writing any estimate:

1. **Recall calibration data** — search memory for `marauder.eta_calibration` to get the latest actual-vs-estimated ratios
2. **Apply the calibration ratio** — our historical data shows we consistently overestimate by 2-3x. Divide naive estimates accordingly
3. **Use these heuristics:**
   - Agent phase: 5-10 min each (not 15-20)
   - Parallel phases: discount 50% (they run concurrently)
   - Integration bug buffer: 1.5x (not 3x)
   - Mechanical changes (find-replace across files): 15-30 min regardless of file count
   - Decision gates (Pilot approval, soak testing): count as session boundaries, not hours
4. **Present both columns** — show the naive estimate AND the cooperative estimate so the Pilot can see the adjustment
5. **Count sessions, not just hours** — calendar time depends on session boundaries (soak tests, restarts, approval gates). State how many sessions each phase needs
6. **Update calibration data** — after implementation, record the actual time in `marauder.eta_calibration` memory to improve future estimates

### Example Format

| Phase | Naive | Coop | Sessions | Notes |
|-------|-------|------|----------|-------|
| DB migration | 4 hours | ~2 hours | 1 | Pure code, no decision gates |
| Hook rollout | 2 days | ~5 hours | 2 | Needs soak gap between deploy and full rollout |
