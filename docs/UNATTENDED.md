# Running these tasks unattended

Written 2026-09-07. Audience: **a delegate agent (a bee) handed a task file at 3am, with
nobody awake to ask.** The operator reads it too, when deciding what a night shift may
attempt.

`CLAUDE.md` → Part 1 → *Execution routing* stays the authority on which agent runs what.
This file answers the question that routing does not: **what a delegate does when the task
it was handed says `plan mode yes` and there is no one to plan with.**

## The rule, first

> **Plan mode is for asking, not for listing files.**

That sentence is already in `CLAUDE.md`. Its consequence for an unattended run is the
whole point of this document:

- If a task opens Plan mode because the **"how" is still open**, a delegate cannot run it.
  There is nobody to answer. **Stop and report — never guess.** A guessed architecture
  decision is the most expensive kind of failure here, because it is invisible: it
  compiles, it passes, and every task after it is written against it.
- If a task opens Plan mode only because it is **large or fiddly**, the "how" is written
  down in its Execution Guide and a delegate can run it. Volume is not ambiguity.

The test is one question, and it is not a judgement call: **does the Execution Guide name
the files, the signatures, the values and the order?** If yes, build it. If a decision is
still open, it will be visible as an ⛔ marker, an unresolved `docs/PRD.md` question, or a
sentence in the task saying the shape is undecided.

## What a delegate must never do, awake or not

These are not style preferences. Each one makes a deviation invisible to every session
afterwards, which is precisely what nobody is around to catch at 3am.

1. **Never add a package.** Blueprint's Stack table is closed. If the task seems to need one,
   that is a finding to report, not a `pubspec.yaml` edit.
2. **Never edit `CLAUDE.md` Blueprint.** If the code contradicts it, Blueprint wins and you stop.
   Editing it to match what you just wrote is the one edit that hides the problem forever.
3. **Never resolve an open `docs/PRD.md` question.** An unanswered question is an input you
   do not have, not a gap to fill with something plausible.
4. **Never relax an acceptance criterion, threshold or test** so the task can pass. Fix the
   code. If a criterion is genuinely unverifiable as written, stop and say so.
5. **Never mark a task DONE.** `verify-task` is the only thing that does that, and it runs
   from the main loop. Your result is a claim; the orchestrator's captured exit code is the
   evidence.
6. **Never write a golden or visual-regression test.** They are not part of Done here, and
   `docs/PRD.md` Q1 is still open — pinning a golden against a prototype with known defects
   would pin the defects.

## Reporting a stop is a success, not a failure

A bee that stops with *"Task-14's V3 revert semantics are undecided; here is the specific
ambiguity"* has done its job well. A bee that picks an interpretation and ships it has
cost the project more than the night was worth. Say which decision is missing, what the
candidate readings are, and what you would need in order to proceed.

## Per-task notes

### Task-06 — App shell (routing, tab shell, bottom nav)

**The architecture call this task reserved is already made.** `docs/ADVICE.md` line 46:
build the tab shell with **`IndexedStack` + one `Navigator` per tab**. `go_router` is held
in reserve *only* for the case where that loses tab state, and `auto_route` is forbidden
outright because it requires `build_runner`, which Blueprint bans.

So a delegate does **not** choose a router. It builds the `IndexedStack` + per-tab
`Navigator` version. If the DoD's four state-preservation tests cannot be made to pass
that way, **stop and report** — adding `go_router` is an operator decision that amends the
Stack table, and no bee may take it.

### Task-10 — Onboarding shell

Runnable unattended. Every timing is fixed (320 ms card slide, 380 ms auto-advance) and
the auto-advance rules are enumerated per step. Two traps the DoD tests for directly:

- The counter divides by **15**, the map fraction by **14**. Both are correct. Do not
  "fix" the inconsistency.
- A second pick inside the 380 ms window must **cancel and restart** the pending advance,
  never queue a second one. Queuing double-advances and silently skips a question.

### Task-13 — Result screen frame

Runnable unattended once Task-07 exists. The sheet is a height-driven panel;
`DraggableScrollableSheet` is forbidden and the DoD greps for it. Anchors are absolute
pixels (190 / 430 / 700), never fractions of screen height, and the snapping itself
delegates to Task-04's `nearestSnap` rather than being reimplemented.

### Task-14 — Stop list, edit mode, reorder / remove / restore

**Keep Plan mode. Not delegable.** Its own routing note says the interaction shape *is*
the work. Deviation V3 splits one prototype action into two scoped ones whose exact
semantics — what a per-row revert restores versus what "Restore N removed" restores when
both a removal and a manual reorder are in play — are the thing to be decided, not
implemented from a description.

### Task-16 — Explore

**Keep Plan mode. Not delegable.** Re-reviewed on 2026-09-05 and deliberately left as
main-loop work: one filtered state has to drive the marker layer, the card list and the
info card together, on the app's first `interactive: true` map.

### Task-20 — Mobile readiness

**Keep in the main loop.** It is a verification pass against a real build on a real
device. A bee cannot look at a phone.

## Tasks whose acceptance is an eye

Tasks **07, 08, 09, 11, 15** are gated by commands like every other task — Q1 forbids a
visual acceptance criterion anywhere — but their *point* is what appears on screen.

Run them unattended, gate them normally, and then report them as
**green, review-visual pending**, never as plain green, listing the built artefact so the
operator's first job at the desk is to look at it. A gate is not an eye: it proves the
code runs, not that the screen is right.

## Reference

- `CLAUDE.md` → Part 1 *Execution routing* — which agent, which effort, whether Plan opens
- `CLAUDE.md` → Blueprint — the binding architecture and the verification rules
- `docs/TASKS_INDEX.md` — the routing summary table and current status
- `docs/ADVICE.md` — the standing technology decisions, including the router one
- `docs/PRD.md` §9 — the open questions; §7 — deviations V1–V9
