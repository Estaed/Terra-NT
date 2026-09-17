# Backlog — what was left unfinished

Delete these instructions once real entries exist.

## Scope — this file holds only what *implementation* deferred

Terra NT already has three lists that came out of the spec, and this is not a fourth:

- `docs/PRD.md` §8 — out of scope for v1, decided on purpose.
- `docs/PRD.md` §9 — open questions (⛔ Q1–Q6). Undecided, blocking named tasks.
- `docs/PRD.md` §9 *Deferred* — the phase 2 and 3 decisions.

**Nothing from those three gets copied here.** This file is for shortcuts discovered while
writing code: a case knowingly not handled, a TODO that would otherwise die in a comment,
a corner cut to keep a task green.

Kept out of the task files on purpose. A task file describes a slice that is either DONE
or not; mixing "and also this half-thing is still owed" into it makes DONE mean nothing.

## Rules

- One line per item, newest at the bottom. Date it.
- Say **what** was skipped and **why** — the why is what lets a later reader decide
  whether it still matters.
- Link the task it came out of: `Task-07`.
- An item that turns out to matter gets promoted into a real task and removed from here.
- Review it when a group of tasks goes green, not continuously.

## Deferred

<!-- 2026-01-01 — Task-00 — what was skipped, and why. -->

2026-09-08 — Task-06/all screen tasks — **the screens built tonight are not reachable in the running app.**
`lib/app/routes.dart` renders `AppPlaceholderScreen` for every destination and its own comment says
*"Feature tasks replace the placeholder body associated with their destination"* — but every screen task's
Lane block lists `terra_nt/lib/app/` under MUST NOT TOUCH, so no bee could do it. Task-17's first bee
blocked on exactly this. The screens and their widget tests exist and pass; only the placeholder→real-body
swap in `lib/app/` is owed. It is one small main-loop commit and belongs with Task-20's integrated device
journey, which is main-loop routed anyway. **Resolve the contradiction as part of it: either the routing
note in `routes.dart` is wrong, or the MUST NOT TOUCH lines are.**

2026-09-08 — Task-07, Task-17 — brief-level ambiguity, fixed mid-run, recorded so it is not reintroduced.
The first bee briefs said "own only the paths in OWNS", which two bees read as forbidding a new named
constant in `core/theme/` — a directory no Lane block actually lists as MUST NOT TOUCH, and one Blueprint
explicitly tells you to add to when a value is missing. Both returned BLOCKED with zero code. Later briefs
carry a "Where a value that is missing from the token set goes" section: prototype dimensions append to
`core/theme/metrics.dart`, screen-specific durations stay in the feature's own lane (which is what
`motion.dart`'s header already says), colours/radii/type are never new.
