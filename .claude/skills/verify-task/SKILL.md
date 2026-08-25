---
name: verify-task
description: Validates the implementation of a specific tasks/Task-XX.md with a goal-oriented fix loop — runs static analysis, tests and build checks, fixes what fails, and only then marks the task DONE in Task-XX.md and TASKS_INDEX.md. Use after implementing any task. Phase 4 of the workflow in CLAUDE.md Part 1.
---

# verify-task

## Objective

Validate the implementation of a specific `tasks/Task-XX.md` using a goal-oriented
fix loop, and update its status **only** when truly complete.

Takes the task id as an argument (e.g. `/verify-task Task-03`). If none is given,
ask which task — do not guess from recent edits.

## Workflow

1. **Read the task.** Open the provided `Task-XX.md` and understand the Acceptance
   Criteria *and* the core goal behind them. The checklist is the floor, not the
   ceiling: a task whose boxes tick but whose goal is unmet is not done.

2. **Run verification commands.** Static analysis, linters, unit tests, build
   checks — whatever `CLAUDE.md` → Part 2 → Verification Rules mandates for this
   project. Run them for real and read the actual output; never assume a command
   passed.

3. **Analyze the codebase** to confirm the Acceptance Criteria are *functionally*
   met, not merely present. A stub that satisfies a test but not the goal fails.

4. **Goal-Oriented Loop.** If there are errors, bugs, or unmet criteria, DO NOT
   stop. Iteratively fix the code, or output precise instructions to resolve the
   issues, then re-run step 2. Repeat until the code works perfectly and achieves
   the task's goal. Stay inside the task's scope while doing it — do not refactor
   adjacent code (`CLAUDE.md` Part 1 → Surgical changes). If a fix requires a
   decision outside the task's scope, halt and ask rather than widening the task.

5. **Only when all checks pass and the goal is met**, update the status
   automatically:
   - In `Task-XX.md`: check off every `- [x]` box and add `Status: DONE` at the top.
   - In `TASKS_INDEX.md`: check off the corresponding box.

   Never tick a box for something you did not actually verify, and never mark a
   task DONE with a known-failing check — report the failure instead.

6. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands
   not covered in this skill, DO NOT make assumptions or guess. Immediately halt
   execution, consult `CLAUDE.md` Part 1 for operational principles, and explicitly
   ask the user for clarification.

## Done when

Every verification command exits clean, every Acceptance Criterion is functionally
met, and both `Task-XX.md` and `TASKS_INDEX.md` reflect that. Report what was run
and what it output — a bare "verified" is not a result.
