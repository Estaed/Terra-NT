# Tasks — Terra NT Route Planner

Sliced from [docs/PRD.md](PRD.md) against `CLAUDE.md` → Part 2 on 2026-08-26.
Execution order is top to bottom: **each task is implementable given only the tasks above
it.**

## Delivery phases

**Everything below is phase 1.** The full phase table is [`docs/PRD.md` §5.1](PRD.md); the
order is deliberate, and each phase depends on the one before it.

| Phase | Scope | State |
|---|---|---|
| **1 — Foundation** | All 9 screens, real navigation, local persistence, seeded itineraries, mocked auth. Runs entirely offline, no cloud account. | **In progress — this file** |
| **2 — Backend** | Firebase or equivalent: real Google Sign-In, real accounts, saved routes off the device. | Not sliced |
| **3 — AI** | Real itinerary generation replacing the seeded implementation. Pipeline is described in [`docs/PRD.md` §5.3](PRD.md). | Not sliced |

Phases 2 and 3 are **deferred, not cancelled**. Phase 1's job is to make them cheap to land,
which is why exactly two seams exist — `ItineraryRepository` and `AuthRepository` — and why
no third one is permitted. The decisions those phases still need are collected as **P1–P8**
in `docs/PRD.md` §9; none of them blocks any task here.

## Foundation

- [x] Task-00: Flutter project scaffold and repo layout
- [x] Task-01: Design tokens → ThemeData
- [x] Task-02: Shared design-system widgets
- [ ] Task-03: Domain models and seed data (pure Dart) ⛔ Q3
- [ ] Task-04: Pure logic utilities
- [ ] Task-05: Repositories, persistence, and the two seams
- [ ] Task-06: App shell — routing, tab shell, bottom nav ⛔ Q2

## Map layer

- [ ] Task-07: Map foundation — flutter_map, CARTO tiles, marker widgets
- [ ] Task-08: Car-follows-route animated backdrop

## Screens

- [ ] Task-09: Login and Welcome screens ⛔ Q5
- [ ] Task-10: Onboarding shell — progress, step machine, auto-advance ⛔ Q4
- [ ] Task-11: Onboarding step bodies (15 questions, 5 types)
- [ ] Task-12: Loading screen and auto-save on generate
- [ ] Task-13: Result screen — map panel, draggable sheet, header, export
- [ ] Task-14: Result screen — stop list, edit mode, reorder / remove / restore
- [ ] Task-15: Stop detail screen
- [ ] Task-16: Explore — interactive map, POI selection, search ⛔ Q6
- [ ] Task-17: Saved Routes — list, swipe-to-delete, empty state
- [ ] Task-18: Profile and inline delete-account confirm
- [ ] Task-19: Account and Language screens

---

## Blocking questions

⛔ marks a task that **cannot fully complete** until an open question in `docs/PRD.md` §9 is
answered. Each is answerable in one sentence, and each blocks only part of its task — the
rest proceeds.

| Q | Question | Blocks |
|---|---|---|
| Q2 | Where does a returning user land, now that the session persists? | Task-06 launch route |
| Q3 | What are the Red Centre itinerary's 4 stops? | Task-03 seed, then Task-17 |
| Q4 | Back from onboarding step 0 → Login or Welcome? | Task-10 back handler |
| Q5 | What does login validation say when it fails? | Task-09 validation |
| Q6 | What does Explore search show (results, no-matches, map filtering)? | Task-16 search |

**Q1 is different and blocks nothing — it limits everything.** How visual fidelity gets
verified is still unanswered: the prototype cannot render and the component bundle is
missing. Until it has an answer, **no task carries a visual acceptance criterion.** Every
criterion in every task file is a command to run or a value to assert in code. Nothing says
"looks right".

The ten reference captures added to `docs/screenshots/` on 2026-08-26 do not change that.
They are there to be *looked at* — build a screen, open the matching file, judge same /
better / worse — and that judgement belongs in conversation, not in a checkbox. Coverage is
partial and the captures carry the prototype's own defects, so citing one as a criterion
would pin a bug. `docs/screenshots/README.md` carries the full rule.

## Deviations these tasks implement

Recorded in `docs/PRD.md` §7 and carried by the task that implements each:

| | Deviation | Task |
|---|---|---|
| V1 | Loading runs 7000 ms so all five messages show | Task-12 |
| V2 | Result meta is derived, not hard-coded | Task-13 |
| V3 | Per-row revert and "restore removed" are scoped, separate actions | Task-04, Task-14 |
| V4 | Skipped stops are excluded from the export URL | Task-04, Task-13 |
| V5 | Result map pins track the live order | Task-13 |
| V6 | Delete account clears saved routes to empty, not to the seed | Task-05, Task-18 |

## Conventions every task inherits

From `CLAUDE.md` → Part 2, so no task restates them:

- `flutter analyze` clean — zero errors, **zero warnings** — is part of every DoD.
- Tier 1 (`core/util/`, `data/models/`, `data/seed/`) imports no Flutter.
- No colour, size, radius or duration literal outside `core/theme/`.
- Exactly two abstraction seams exist: `ItineraryRepository` and `AuthRepository`.
- **No golden or visual-regression tests** — they are not part of the Definition of Done.
- Run all `flutter`/`dart` commands from `terra_nt/`.
