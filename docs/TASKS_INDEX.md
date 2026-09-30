# Tasks — Terra NT Route Planner

Sliced from [docs/PRD.md](PRD.md) against `CLAUDE.md` → Blueprint on 2026-08-26.
Execution order is top to bottom: **each task is implementable given only the tasks above
it.**

## Delivery phases

**Everything below is phase 1.** The full phase table is [`docs/PRD.md` §5.1](PRD.md); the
order is deliberate, and each phase depends on the one before it.

| Phase | Scope | State |
|---|---|---|
| **1 — Foundation** | All 9 screens, real navigation, local persistence, seeded itineraries, mocked auth. Product data and core flows are local; remote CARTO map tiles are the only network resource. | **In progress — this file** |
| **2 — Backend** | Firebase or equivalent: real Google Sign-In, real accounts, saved routes off the device. | **In progress from 2026-09-22** (`docs/PRD.md` D12, D13) — wave 1 (Task-23…25) DONE; wave 2 is Task-26…29 below |
| **3 — AI** | Real itinerary generation replacing the seeded implementation. The app's side is `docs/PHASE-3-CONTRACT.md`; the server and model are a teammate's. | **In progress from 2026-09-22** (`docs/PRD.md` D14) — wave 1 is Task-30…33 below |

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

## Phase 2 — Backend, wave 1 (written 2026-09-22)

The decision is `docs/PRD.md` D12; the working notes are `docs/PHASE-2-3-FOUNDATION.md`.
Sequential: each task needs the one before it.

- [x] Task-23: Firebase project and app wiring
- [x] Task-24: Real email/password accounts behind `AuthRepository`, with failure states
- [x] Task-25: Real Google Sign-In

## Phase 2 — Backend, wave 2 (written 2026-09-22, `docs/PRD.md` D13)

Task-26 runs alone first; 27, 28 and 29 are independent of each other and run in
parallel after it.

- [x] Task-26: Saved routes carry their stops; the auth seam grows for wave 2 and phase 3
- [x] Task-27: Saved routes in Firestore under the account, device copy first
- [x] Task-28: Password reset on Login; email verification on Account
- [x] Task-29: Crashlytics, and the disclosure row in Profile

## Phase 3 — AI, wave 1 (written 2026-09-22, `docs/PRD.md` D14)

The contract is `docs/PHASE-3-CONTRACT.md`. Task-30 and 31 need only Task-26 and run
beside wave 2's parallel group; 32 and 33 run in parallel after them.

- [x] Task-30: Stable answer keys and the `PlanRequest` builder
- [x] Task-31: `PlanFailure` and `parsePlanResponse`, with one fixture per failure row
- [x] Task-32: `RemoteItineraryRepository`, the `PLAN_API_URL` switch, and the stub server
- [x] Task-33: Loading: cancel, failure and retry; the empty detailed-plan line

## Goal run 2026-09-23 (self-written waves, `reports/otopilot-2026-09-23-plan.md`)

- [x] Task-34: Loading keeps V1's 7000 ms on success; retry is tested end to end
- [x] Task-35: Account reads verification through the seam; tests override the seam
- [x] Task-36: Phase-2 launch routing: nobody signed in lands on Login
- [x] Task-37: Map fit clears the status bar and the overlays on Explore and Result
- [x] Task-38: Audit bugs: the auth wrapper's null user, empty stop names; notifier coverage
- [x] Task-39: An edited leg shows the straight-line distance instead of "Drive time unavailable"
- [x] Task-40: Plan AI shows an empty state until a route exists this session
- [x] Task-41: Explore POI pins carry their tag colour
- [x] Task-42: Place images replace the placeholders on Stop detail, Explore and Saved Routes
- [x] Task-43: Tile warmup matches Explore's new fit; Loading warms the Result map
- [x] Task-44: Account's verification row says "Checking…" while it loads

## Demo readiness, 2026-09-29 (`docs/PRD.md` D17, `reports/otopilot-2026-09-29-plan.md`)

Task-45 and Task-46 are independent and run in parallel; Task-47 was done by the main loop.

- [x] Task-45: The planning server: the contract's endpoint on the operator's machine, model behind one switch
- [x] Task-46: Seven more places on Explore, and every place gets a picture
- [x] Task-47: iOS configured from Windows; a dark launch screen on both platforms

## Polish pass, 2026-09-29 (`docs/PRD.md` D18, `reports/otopilot-2026-09-29b-plan.md`)

Four independent features, one wave. `Entrance`, the motion tokens and the two images
(`assets/images/car.png`, `brand_mark.png`) were committed by the main loop first.

- [x] Task-48: The progress bar is a road, and the car is a real vehicle
- [x] Task-49: Loading looks like a route being planned, not a placeholder
- [x] Task-50: Content enters instead of popping in; buttons answer the touch
- [x] Task-51: First impressions: Login, Create account and Welcome look like a product

## Attended polish, 2026-09-30 (`docs/PRD.md` D19)

- [x] Task-52: Visible tab/question motion and endpoint pickers

## Motion, illustration and truth, 2026-09-30 (Blueprint D21, `reports/reviews/2026-09-30/report.md`, `reports/otopilot-2026-09-30-plan.md`)

Written by Codex (`agent codex`), five waves of two, run unattended with the operator's approval.

- [x] Task-53: The route draws itself, and the Result camera follows the sheet
- [x] Task-54: Explore comes alive
- [x] Task-55: Back goes where the user came from
- [x] Task-56: Route facts are true: day count, pins in view, honest date label
- [x] Task-57: Welcome and the empty Plan AI tab open on a journey scene
- [x] Task-58: Onboarding shows where the trip is going
- [x] Task-59: The stop list shows what changed, and pictures travel into Stop detail
- [x] Task-60: Loading draws the chosen trip, and no signal is not a dead end
- [x] Task-61: Onboarding flows without friction
- [x] Task-62: Honest settings, readable labels, and Saved routes with their own covers

## Offline map, 2026-09-30 (Blueprint D22, `reports/research/2026-09-30-offline-map.md`)

- [x] Task-63: Map areas you have opened stay on the phone for 30 days

## Audit wave, 2026-10-01 (`reports/research/2026-10-01-qol-audit.md`, `…-visual-audit.md`)

- [x] Task-64: With no signal, nothing waits for the network
- [x] Task-65: Saved routes can be undone, renamed and put in order
- [x] Task-66: Road facts are right and every control speaks
- [x] Task-67: Concrete choices get icons, and Loading's failures say what happened
- [x] Task-68: Saved copies of the demo routes get the corrected road facts
- [x] Task-69: The offline note leaves the route visible, and times stay whole at large text

### Later — not yet written as tasks

- Show a stop's `sources` on Stop detail — parsed past in Task-31; no design.
- First iOS build and tour on a Mac (`docs/IOS-SETUP.md`).

Closed 2026-09-29: `photoUrl` already renders (Task-42, `PlaceholderTile` takes an `http(s)`
image); `AppMotion.loadingCompletionDelay` is used again since Task-34 restored V1's 7000 ms;
iOS Firebase is Task-47; the Profile placeholder email is kept as a defensive fallback — since
Task-36 nobody reaches Profile signed out, and both sign-in paths carry an email.

---

## Execution routing

The rule is `CLAUDE.md` → Part 1, *Execution routing*. Each task file carries its own
`Execution` block; **this table is a summary of those blocks, not a second source of truth.**
When they disagree, the task file wins. Task-00…02 are DONE and are not routed again.

| Task | Agent | Effort |
|---|---|---|
| 03 Domain models and seed | `codex` | high |
| 04 Pure logic utilities | `codex` | high |
| 05 Repositories and seams | `codex` | high |
| 06 App shell / routing | `codex` | high |
| 07 Map foundation | `codex`, then `review-visual` | high |
| 08 Car-follows-route backdrop | `codex`, then `review-visual` | high |
| 09 Login and Welcome | `codex`, then `review-visual` | high |
| 10 Onboarding shell | `codex` | high |
| 11 Onboarding step bodies | `codex`, then `review-visual` | high |
| 12 Loading and auto-save | `codex` | high |
| 13 Result — map, sheet, export | `codex`, then `review-visual` | high |
| 14 Result — list and edit mode | main loop | high |
| 15 Stop detail | `codex`, then `review-visual` | high |
| 16 Explore | main loop | high |
| 17 Saved Routes | `codex` | high |
| 18 Profile | `codex` | high |
| 19 Account and Language | `codex` | high |
| 20 Mobile readiness integration | main loop | medium |
| 21 Create account | `codex`, then `review-visual` | high |
| 22 Bug fixes and improvements batch | main loop as chef, `claude` bees | medium |
| 23 Firebase project and app wiring | main loop (operator login and console steps) | medium |
| 24 Real accounts behind `AuthRepository` | `codex` | high |
| 25 Real Google Sign-In | `codex`, then main-loop device tour | high |
| 26 Saved routes carry stops; seam growth | `codex` (Claude bees tonight) | high |
| 27 Firestore saved routes | `codex` (Claude bees tonight), then main-loop console steps + tour | high |
| 28 Password reset, email verification | `codex` (Claude bees tonight) | high |
| 29 Crashlytics | `codex` (Claude bees tonight) | high |
| 30 Answer keys, `PlanRequest` | `codex` (Claude bees tonight) | high |
| 31 `PlanFailure`, `parsePlanResponse` | `codex` (Claude bees tonight) | high |
| 32 `RemoteItineraryRepository`, stub | `codex` (Claude bees tonight), then main-loop stub tour | high |
| 34 Loading minimum display, retry test | `codex` (Claude bees tonight) | high |
| 35 Account seam override | `codex` (Claude bees tonight) | high |
| 33 Loading failure state | `codex` (Claude bees tonight), then main-loop device tour | high |
| 45 Planning server | `ultracode`, then main-loop live generation | xhigh |
| 46 Seven places, tag pictures | `ultracode`, then main-loop emulator tour | xhigh |
| 47 iOS config, dark launch | main loop | medium |
| 48–51 Polish pass | `ultracode`, then main-loop emulator tour | xhigh |
| 52 Visible motion and endpoint pickers | main loop (attended decision and phone tour) | high |

Wave 2 and phase 3 (2026-09-22) are routed to Claude bees, not Codex, by operator
decision for the overnight run ("claude swarm kullan"). Dependency graph for the run:
26 → {27, 28, 29, 30, 31} → {32, 33}; 32 needs 27, 30 and 31, 33 needs 31.

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

From `CLAUDE.md` → Blueprint, so no task restates them:

- `flutter analyze` clean — zero errors, **zero warnings** — is part of every DoD.
- Tier 1 (`core/util/`, `data/models/`, `data/seed/`) imports no Flutter.
- No colour, size, radius or duration literal outside `core/theme/`.
- Exactly two abstraction seams exist: `ItineraryRepository` and `AuthRepository`.
- "Offline" means local product data, mocked auth and seeded generation. CARTO tiles remain
  network-backed; phase 1 adds no tile download, cache-management feature or third seam.
- **No golden or visual-regression tests** — they are not part of the Definition of Done.
- Run all `flutter`/`dart` commands from `terra_nt/`.
