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
   passed. **If the task's own DoD names a build or run command, running it is part
   of this step** — do not substitute a cheaper check for it.

   **Do not launch an emulator, device or browser unless the DoD asks for one.**
   This step repeats on every turn of the fix loop, so it has to stay fast and
   deterministic: a device install per iteration makes the loop unusable, and a
   check that fails merely because nothing is attached fails for the wrong reason.
   Driving the real app is a separate, explicitly invoked job — the built-in `run`
   skill — and belongs after this skill reports DONE, not inside it.

3. **Analyze the codebase** to confirm the Acceptance Criteria are *functionally*
   met, not merely present. A stub that satisfies a test but not the goal fails.

   **A green suite is not evidence until you have seen it go red.** Before trusting it,
   break the thing it claims to protect — change a value, invert a condition, delete a
   guard — and confirm the suite fails and names the right thing. Then restore it and
   confirm green again. Tests that cannot fail are the most expensive kind: they cost
   the same to run and report success forever. Where a criterion is a transcription or
   a mapping, also diff the produced values against the source they came from; "the
   constant exists" and "the constant is right" are different claims.

4. **Goal-Oriented Loop.** If there are errors, bugs, or unmet criteria, DO NOT
   stop. Iteratively fix the code, or output precise instructions to resolve the
   issues, then re-run step 2. Repeat until the code works perfectly and achieves
   the task's goal. Stay inside the task's scope while doing it — do not refactor
   adjacent code (`CLAUDE.md` Part 1 → Surgical changes). If a fix requires a
   decision outside the task's scope, halt and ask rather than widening the task.

   **The loop has an exit.** Stop and report when one criterion has survived three fix
   attempts, or when two consecutive iterations produce the same failure output —
   whichever comes first. The second is the real signal: identical output twice means the
   last fix addressed nothing, and a third guess from the same hypothesis is not an
   experiment. An error message that keeps changing is progress; keep going. When you do
   stop, report what was tried, what the output actually said, and what your current
   hypothesis is, then ask for direction — do not keep looping.

   **Fix the code, never the criterion.** If an Acceptance Criterion turns out to be
   unverifiable as written, or contradicts `CLAUDE.md` → Part 2, halt and say so. Do not
   reword the DoD, relax a threshold, or drop a check so the task can pass: that is the
   one edit that makes this skill report success while the goal is unmet, and afterwards
   it is indistinguishable from a task that genuinely passed. Changing a DoD is the
   user's call.

5. **Only when all checks pass and the goal is met**, update the status
   automatically:
   - In `Task-XX.md`: check off every `- [x]` box and add `Status: DONE` at the top.
   - In `docs/TASKS_INDEX.md`: check off the corresponding box.

   Never tick a box for something you did not actually verify, and never mark a
   task DONE with a known-failing check — report the failure instead.

6. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands
   not covered in this skill, DO NOT make assumptions or guess. Immediately halt
   execution, consult `CLAUDE.md` Part 1 for operational principles, and explicitly
   ask the user for clarification.

## Done when

Every verification command exits clean, every Acceptance Criterion is functionally
met, and both `Task-XX.md` and `docs/TASKS_INDEX.md` reflect that. Report what was run
and what it output — a bare "verified" is not a result.
