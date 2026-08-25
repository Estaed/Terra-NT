---
name: generate-tasks
description: Derives actionable technical task files from PRD.md and the referenced prototypes, writing tasks/Task-XX.md plus a TASKS_INDEX.md tracker. Use after the PRD exists and before implementation starts, or when the task breakdown needs regenerating. Phase 2 of the workflow in CLAUDE.md Part 1.
---

# generate-tasks

## Objective

Derive actionable, technical task files from `PRD.md` and the referenced prototypes.

## Workflow

1. **Read the sources.** `PRD.md`, `CLAUDE.md` (both parts — Part 2 is the binding
   technical contract), and every prototype/design file the PRD references. If
   `CLAUDE.md` → Part 2 is still the placeholder, **stop**: tasks written without a
   fixed stack and folder layout will contradict each other. Say so and ask.

2. **Derive, do not transcribe.** Do NOT copy-paste the PRD into task files. Work
   out the technical solutions required to fulfil it. If the PRD says "Build
   Homepage", you must figure out what technical steps and architecture are needed
   to solve that, based on the prototypes and on Part 2. The PRD's *what* becomes
   the task's *how*.

3. **Divide into small, sequential tasks** inside a `tasks/` directory:
   `tasks/Task-00.md`, `tasks/Task-01.md`, … Ordering matters — each task should be
   implementable given only the tasks before it. Scaffolding, theme/tokens, and
   routing come before screens; screens come before polish. One task should be a
   single sitting of work, not a milestone.

4. **Each task file contains:**
   - **Objective** — what this task accomplishes and what problem it solves.
   - **Execution Guide** — how to implement it: files to touch, architectural
     patterns to use based on the derived solutions, and the design file that is
     the source of truth for anything visual.
   - **Acceptance Criteria (DoD)** — a strict `- [ ]` checklist of functional
     requirements and tests. Each item must be objectively checkable by running a
     command or reading the code — never "looks right" or "works well".

5. **Generate `TASKS_INDEX.md`** at the repo root tracking every task as
   `- [ ] Task-XX: Description`, in execution order.

6. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands
   not covered in this skill, DO NOT make assumptions or guess. Immediately halt
   execution, consult `CLAUDE.md` Part 1 for operational principles, and explicitly
   ask the user for clarification.

## Done when

`tasks/` holds numbered task files whose Acceptance Criteria are all machine- or
code-checkable, `TASKS_INDEX.md` lists them in order with unchecked boxes, and no
task depends on something no earlier task produces.
