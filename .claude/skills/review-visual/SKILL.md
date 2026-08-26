---
name: review-visual
description: Runs the built app, captures what a task changed on screen — or whatever image it produces — and compares it by eye against the source of truth Part 2 names, reporting each difference as a recorded deviation, a defect in the reference, a build defect, or something the reference never covered. Advisory only; it never marks a task DONE and never writes a visual test. Use after verify-task reports DONE on a task whose output gets looked at. Phase 5 companion in CLAUDE.md Part 1.
---

# review-visual

## Objective

Look at what was actually built, next to what it was supposed to look like, and say
**same / better / worse** — with each difference sorted into one of four boxes, only one of
which is a bug.

`verify-task` proves the code runs, the tests pass and the analyzer is clean. None of that
can see a screen. This skill is the eye, and it is deliberately **advisory**: it reports,
the user decides, and no box anywhere gets ticked because of it.

## Why it is built this way

Three failures this exists to prevent, in the order they actually happen:

- **Reviewing the source instead of the screen.** Reading a widget tree and describing what
  it *would* render is not a visual review — it is the same guess that produced the code,
  checked against itself. If the app cannot be made to run, this skill has nothing to do and
  says so.
- **Treating the reference image as the specification.** Design sources have defects, and
  projects record deliberate departures from them. A difference is not evidence of a bug
  until it has been checked against the deviation list. Faithfully reproducing a flaw in the
  reference is a worse outcome than the difference was.
- **Becoming a gate.** The moment a visual comparison can fail a task, someone will pin it —
  a golden test, an acceptance criterion citing an image — and the project will have
  promoted an eyeball into a build blocker. Whether visual fidelity is verifiable *at all*
  is a question for the PRD, not for this skill. It reviews; it never verifies.

## Preconditions

Stop and say which one failed, rather than working around it:

1. **The task is DONE and green.** Run this after `verify-task`, never instead of it.
   Reviewing the appearance of a build that fails its own tests reports noise.
2. **`CLAUDE.md` → Part 2 names a source of truth for the output.** Usually a design file
   plus a deviation list. Where the output is an image rather than a screen — a detection
   overlay, a generated frame, a plotted result — it is whatever Part 2 names as the
   expected result. If Part 2 names none, stop: nominating one yourself is exactly how a
   folder of screenshots becomes a specification nobody agreed to.
3. **The app can be run.** If it cannot, stop. Report that the review is impossible and why.

## Workflow

1. **Read the boundaries first, before looking at anything.** From `CLAUDE.md` Part 2 and
   the PRD: what the source of truth is, where deviations are recorded, and — critically —
   **what the project has already decided about visual verification**. A project may have
   ruled the whole question open; that ruling governs this skill's output, not the other way
   round. Also read the task file: only the screens it touched are in scope.

2. **Run the real app** — the built-in `run` skill, on the configuration the project
   actually targets. Capture the screens the task touched, in the states it touched. Name
   each capture by screen and state. **A screen you could not reach is reported as
   unreviewed, not inferred.**

3. **Put each capture next to its reference** and describe the differences concretely —
   spacing, weight, colour, radius, copy, order, timing, state. Vague is useless: "the
   header looks off" is not a finding; "the header sits 8px lower and the title is one
   weight heavier" is.

4. **Sort every difference into exactly one box.** This is the whole value of the skill:

   | Box | What it means | What happens |
   |---|---|---|
   | **Recorded deviation** | The project's deviation list says the build *should* differ here | Not a finding. Cite the deviation's id and move on. |
   | **Defect in the reference** | The design source is itself wrong here, per what the project has already documented | Not a finding against the build. Say so, and do not "fix" the build toward it. |
   | **Build defect** | A real difference, not covered by either of the above | **The finding.** Describe it, cite the token or spec it violates. |
   | **Not covered** | The reference does not show this screen, state, or case | Not a finding. It is a **gap in the source of truth** — report it as one, and say what would close it. |

   A difference you cannot place in a box has not been understood yet. Say that instead of
   guessing which box it belongs in — the fourth box is not a dumping ground for the
   uncertain, it is specifically for what the reference never showed.

5. **Report.** Per screen: what matched, the build defects with enough detail to fix them,
   the deviations and reference defects you accounted for (so the reader knows they were
   checked, not missed), and everything unreviewed or uncovered. Then hand over: these are
   **candidates**, and which of them is worth fixing is the user's call.

6. **Fix only what was approved, only in the build-defect box.** If the user asks for fixes,
   apply them to the build and re-capture the affected screens to confirm. Never edit the
   design source, never edit the deviation list, and never widen the fix past what was
   approved — Part 1 rule 3 holds here as everywhere.

7. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands not
   covered in this skill, DO NOT make assumptions or guess. Immediately halt execution,
   consult `CLAUDE.md` Part 1 for operational principles, and explicitly ask the user for
   clarification.

## Never

- **Never mark anything DONE.** Not the task, not a checkbox, not a tracker row. `verify-task`
  owns that and this skill does not touch it.
- **Never write a golden test, a screenshot-diff test, or any visual-regression test**, and
  never propose one as a fix. Where a project has ruled on this, the ruling is binding; where
  it has not, adding one is a decision for the user, raised as its own task.
- **Never write an acceptance criterion that cites an image.** Criteria stay commands to run
  or values to assert in code.
- **Never edit the design source, the deviation list, the PRD or Part 2.** Differences that
  turn out to be spec problems get *reported* as such — the same rule `research` follows.
- **Never review from source code** when the app did not run. Report the blocker instead.

## Cost

Captures are expensive in context. Review the screens **one at a time**, and only the ones
the task touched — dumping ten images to review two of them buys nothing and crowds out the
reasoning. A task with no visual surface does not need this skill at all.

## Done when

Every screen the task touched has either been captured and compared, or reported as
unreviewed with the reason; every difference sits in exactly one of the four boxes; the
build defects are described precisely enough to act on; no test was written, no box was
ticked, and no source of truth was edited.
