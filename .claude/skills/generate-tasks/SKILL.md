---
name: generate-tasks
description: Derives actionable technical task files from PRD.md and the referenced prototypes, writing tasks/Task-XX.md plus a TASKS_INDEX.md tracker. Use after the PRD exists and before implementation starts, or when the task breakdown needs regenerating. Last of the once-per-project sequence in CLAUDE.md Part 1.
---

# generate-tasks

## Objective

Derive actionable, technical task files from `docs/PRD.md` and the referenced
prototypes.

## Workflow

0. **If `tasks/` already holds task files, stop and ask before writing anything.** Read
   them and `docs/TASKS_INDEX.md` first, then say concretely what you found — how many
   tasks exist, which are marked DONE, and where `docs/PRD.md` has moved on since they
   were written — and offer the three real choices: **add** what is missing and amend the
   tasks the PRD outgrew, **regenerate** only the un-started ones, or **leave them alone**.
   Wait for the answer.

   Never regenerate silently. The tick marks in `docs/TASKS_INDEX.md` and a task's
   `Status: DONE` are the only record that the work shipped and was verified; no command
   rebuilds them. Renumbering is just as destructive — task ids are referenced from the
   index, from other task files and from the commit log, so `Task-07` must mean the same
   thing tomorrow. **A DONE task is never rewritten in place**: if its scope genuinely
   changed, that is a new task appended at the end, not an edit to a finished one.

1. **Read the sources.** `docs/PRD.md`, `CLAUDE.md` (both parts — Part 2 is the binding
   technical contract), and every prototype/design file the PRD references. If
   `CLAUDE.md` → Part 2 is still the placeholder, **stop**: tasks written without a
   fixed stack and folder layout will contradict each other. Say so and ask.

   Surveying a large prototype or an unfamiliar codebase may be delegated to a
   read-only `Explore` agent, which keeps a pile of file dumps out of the main
   context. Delegate the *looking* only. Read `docs/PRD.md` and `CLAUDE.md` → Part 2
   yourself and hold them while you write: the slicing, the ordering and the
   criteria are judgements that depend on both documents at once, and a summary of
   them is not the same as having them.

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

5. **A task with a runtime surface gets a runtime criterion.** Compiling is not
   working, and a type checker proves nothing about behaviour. Derive the right
   check for *this* project rather than reaching for a familiar one — answer three
   questions from what `CLAUDE.md` → Part 2 and the code actually say:

   1. **What does this task produce that runs?** A screen, a page, an endpoint, a
      trained model, a scheduled job, a CLI — or nothing that runs at all.
   2. **How does that thing break at run time in a way analysis and unit tests
      would not catch?** Answer concretely, in this project's terms.
   3. **What is the cheapest deterministic, headless check that fails when it
      does?** That check is the criterion.

   Worked example, this project: a screen task produces a widget tree; it breaks by
   overflowing or hitting unbounded constraints at phone widths, which no analyzer
   sees; so the DoD says a widget test pumped at that width records no
   `FlutterError`. A UI-less project answers the same three questions differently
   and gets a different criterion — a headless page load asserting no console
   error, a request against a started server asserting a status, a forward pass on
   one fixed sample asserting output shape, a scored eval set asserting a metric
   floor. These are illustrations of the method, not a menu: a project type absent
   from this list still answers the three questions.

   Tasks that add only pure logic, models, tokens or config produce nothing that
   runs on its own — do not manufacture a runtime criterion for them.

   Add the project's **build or packaging command** only where a task touches the
   surface that command uniquely covers — native/plugin registration, asset
   declaration, manifests, bundling. On a task that only adds source the ordinary
   test run already compiles, it costs minutes and proves nothing extra.

   Keep every such criterion **deterministic and headless**. These run inside
   `verify-task`'s fix loop on every iteration, so a criterion that needs an
   emulator, an attached device, a network service or a human eye does not belong
   in a DoD. Running the real thing is a separate, manual step (the built-in `run`
   skill). This bites hardest where output is generated rather than computed: judge
   structure a machine can check — valid JSON, required fields present, a metric
   above a floor — never quality a person has to like. And while the PRD leaves
   *how fidelity gets verified at all* unanswered, no task carries a visual
   criterion — every item stays a command to run or a value to assert.

6. **Generate `docs/TASKS_INDEX.md`** tracking every task as
   `- [ ] Task-XX: Description`, in execution order.

   **If the PRD defines delivery phases, put the phase table at the top of this file**
   — which phase the listed tasks belong to, what the later phases hold, and a link to
   the PRD section that owns it. A one-line aside saying "phase 1 only" is not enough:
   this index is where someone looks to see what is being built, so a reader who has to
   go find the phasing elsewhere will assume the list is the whole project. Say plainly
   that later phases are **deferred, not cancelled**, and name whatever seams exist to
   make them cheap to land.

7. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands
   not covered in this skill, DO NOT make assumptions or guess. Immediately halt
   execution, consult `CLAUDE.md` Part 1 for operational principles, and explicitly
   ask the user for clarification.

## Done when

`tasks/` holds numbered task files whose Acceptance Criteria are all machine- or
code-checkable, `docs/TASKS_INDEX.md` lists them in order with unchecked boxes, and no
task depends on something no earlier task produces.
