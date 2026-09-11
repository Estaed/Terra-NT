# Tasks — Terra NT Route Planner

Sliced from [docs/PRD.md](PRD.md) against `CLAUDE.md` → Part 2 on 2026-08-26.
Execution order is top to bottom: **each task is implementable given only the tasks above
it.**

## Delivery phases

**Everything below is phase 1.** The full phase table is [`docs/PRD.md` §5.1](PRD.md); the
order is deliberate, and each phase depends on the one before it.

| Phase | Scope | State |
|---|---|---|
| **1 — Foundation** | All 9 screens, real navigation, local persistence, seeded itineraries, mocked auth. Product data and core flows are local; remote CARTO map tiles are the only network resource. | **In progress — this file** |
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
- [x] Task-03: Domain models and seed data (pure Dart)
- [x] Task-04: Pure logic utilities
- [x] Task-05: Repositories, persistence, and the two seams
- [x] Task-06: App shell — routing, tab shell, bottom nav

## Map layer

- [x] Task-07: Map foundation — flutter_map, CARTO tiles, marker widgets
- [x] Task-08: Car-follows-route animated backdrop

## Screens

- [x] Task-09: Login and Welcome screens
- [x] Task-10: Onboarding shell — progress, step machine, auto-advance
- [x] Task-11: Onboarding step bodies (15 questions, 5 types)
- [x] Task-12: Loading screen and auto-save on generate
- [x] Task-13: Result screen — map panel, draggable sheet, header, export
- [x] Task-14: Result screen — stop list, edit mode, reorder / remove / restore
- [x] Task-15: Stop detail screen
- [x] Task-16: Explore — interactive map, POI selection, search
- [x] Task-17: Saved Routes — list, swipe-to-delete, empty state
- [x] Task-18: Profile and inline delete-account confirm
- [x] Task-19: Account and Language screens

## Integration

- [x] Task-20: Mobile readiness — bounded phone checks and integrated device journey

## Added after Task-20

- [x] Task-21: Create account screen
- [x] Task-22: Bug fixes and improvements batch (2026-09-11)

Task-20 is DONE. The device journey ran on an Android 16 emulator at a 411x914 logical
viewport; the report is in the task file. Its two open decisions were answered on
2026-09-10: the map zoom buttons are removed (deviation V10) and the Result sheet now
opens at the prototype middle anchor.

---

## Execution routing

The rule is `CLAUDE.md` → Part 1, *Execution routing*. Each task file carries its own
`Execution` block; **this table is a summary of those blocks, not a second source of truth.**
When they disagree, the task file wins. Task-00…02 are DONE and are not routed again.

| Task | Agent | Plan mode | Effort |
|---|---|---|---|
| 03 Domain models and seed | `codex` | no | high |
| 04 Pure logic utilities | `codex` | no | high |
| 05 Repositories and seams | `codex` | no | high |
| 06 App shell / routing | `codex` | no | high |
| 07 Map foundation | `codex`, then `review-visual` | no | high |
| 08 Car-follows-route backdrop | `codex`, then `review-visual` | no | high |
| 09 Login and Welcome | `codex`, then `review-visual` | no | high |
| 10 Onboarding shell | `codex` | no | high |
| 11 Onboarding step bodies | `codex`, then `review-visual` | no | high |
| 12 Loading and auto-save | `codex` | no | high |
| 13 Result — map, sheet, export | `codex`, then `review-visual` | no | high |
| 14 Result — list and edit mode | main loop | **yes** | high |
| 15 Stop detail | `codex`, then `review-visual` | no | high |
| 16 Explore | main loop | **yes** | high |
| 17 Saved Routes | `codex` | no | high |
| 18 Profile | `codex` | no | high |
| 19 Account and Language | `codex` | no | high |
| 20 Mobile readiness integration | main loop | no | medium |
| 21 Create account | `codex`, then `review-visual` | no | high |

**`verify-task` runs from the main loop** even when a Codex lane wrote the code — the agent
that produced the work must not be the one that relaxes its test. That never changes.

## Rerouted 2026-09-07 — the backlog is now mostly unattended-runnable

Tasks **06, 07, 08, 09, 10, 13 and 15** moved from the main loop to `codex`. The operator's
goal was a backlog that can run overnight; the audit behind the move is in
**`docs/UNATTENDED.md`**, which is also the note a delegate reads when it is handed one of
these files at 3am.

Two findings drove it, and both are worth keeping in view:

1. **Plan mode was open on 06, 10 and 13 for volume, not for an undecided how.** Their
   Execution Guides already name the files, the values and the order. `CLAUDE.md`'s own
   test — *is the how already written down?* — answers yes for all three. Task-06's
   apparent architecture call was decided in `docs/ADVICE.md` before this task existed.
2. **07, 08, 09 and 15 were main-loop because acceptance is judged by eye** — but Q1
   forbids a visual acceptance criterion anywhere, so every one of their DoDs is already
   a command or a code assertion. The eye check is `review-visual`, which is advisory and
   runs afterwards. They now report as **green, review-visual pending**, never plain green.

**Three tasks stay in the main loop, and the reasons are structural, not caution:**

| Task | Why it is not delegable |
|---|---|
| **14** Result list / edit mode | Its own routing note says it: the interaction shape *is* the work. V3 splits one prototype action into two scoped ones whose semantics — what a per-row revert restores versus what "Restore N removed" restores when a removal and a manual reorder are both live — are to be decided, not implemented from a description. |
| **16** Explore | Reviewed 2026-09-05 and re-confirmed 2026-09-07. One filtered state must drive the marker layer, the card list and the info card together, on the app's first `interactive: true` map. |
| **20** Mobile readiness | A verification pass against a real build on a real device. A bee cannot look at a phone. |

**The tasks are no longer a single file.** Every task now carries a `DEPENDS ON` line, and
the resulting graph has genuine width: once Task-06 lands, 07, 09, 12, 17 and 18 have no
dependency on each other and can run as one wave. `codex` no longer means one lane at a
time.

---

## Resolved questions — 2026-09-05

Q2–Q6 no longer block implementation. Their binding answers are recorded in the named task
files and in `docs/PRD.md` §9.

| Q | Binding answer | Task |
|---|---|---|
| Q2 | Returning users with completed onboarding land on Explore. | Task-06 |
| Q3 | Red Centre is Alice Springs → Desert Park → Kings Canyon → Uluru-Kata Tjuta. | Task-03, Task-17 |
| Q4 | Back from onboarding step 0 goes to Welcome. | Task-10 |
| Q5 | Submit-time email/password validation uses the recorded exact inline copy. | Task-09 |
| Q6 | Search filters existing POIs and markers; there is no separate results list. | Task-16 |

**Q1 remains different and blocks nothing — it limits everything.** How visual fidelity gets
verified is still unanswered: the prototype cannot render and the component bundle is
missing. Until it has an answer, **no task carries a visual acceptance criterion.** Every
criterion in every task file is a command to run or a value to assert in code. Nothing says
"looks right".

The ten reference captures added to `docs/screenshots/` on 2026-08-26 do not change that.
They are there to be *looked at* beside the **running Flutter app** — not treated as proof
that the prototype markup would render correctly — and the resulting `review-visual`
judgement is advisory, never a task gate or checkbox. Coverage is partial and the captures
carry the prototype's own defects, so citing one as a criterion would pin a bug.
`docs/screenshots/README.md` carries the full rule. Task-20's functional phone checks are
gates; any screenshots captured from Flutter during that run remain advisory visual evidence.

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
| V7 | Back from onboarding step 0 returns to Welcome | Task-10 |
| V8 | Sheet anchors clamp to available phone height | Task-04, Task-13 |
| V9 | Drive-time copy follows baseline adjacency, not stale edited legs | Task-04, Task-14 |

## Conventions every task inherits

From `CLAUDE.md` → Part 2, so no task restates them:

- `flutter analyze` clean — zero errors, **zero warnings** — is part of every DoD.
- Tier 1 (`core/util/`, `data/models/`, `data/seed/`) imports no Flutter.
- No colour, size, radius or duration literal outside `core/theme/`.
- Exactly two abstraction seams exist: `ItineraryRepository` and `AuthRepository`.
- "Offline" means local product data, mocked auth and seeded generation. CARTO tiles remain
  network-backed; phase 1 adds no tile download, cache-management feature or third seam.
- **No golden or visual-regression tests** — they are not part of the Definition of Done.
- Run all `flutter`/`dart` commands from `terra_nt/`.
| 22 Bug fixes and improvements batch | main loop as chef, `claude` bees | no | medium |
