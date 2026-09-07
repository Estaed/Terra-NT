# Otopilot run report — 2026-09-08

> **Interim, written 01:55 while the run is paused.** The Codex 5-hour window hit its
> limit mid-flight at roughly 02:13 UTC+? (`ERROR: You've hit your usage limit ... try
> again at 5:20 AM`). Two bees died in flight; no new bee has been spawned since. The run
> is waiting on the window reset and this file is rewritten when it closes out.

Plan: `reports/otopilot-2026-09-08-plan.md`. Direction: Claude orchestrates, `codex exec`
bees, worktree-isolated, one commit each, gate run by the orchestrator in the worktree and
again on `main` after cherry-pick.

`BASE_SHA` `45aca57`, baseline gate clean at 104 tests.
**`main` is currently green: `flutter analyze` clean, 161 tests pass.**

## Outcome per task

| Task | Result | Attempts | Failing command / reason | Final SHA on `main` |
|---|---|---:|---|---|
| Task-07 Map foundation | **green**, review-visual pending | 2 | attempt 1 BLOCKED, zero code — see *Attempt-1 blockers* | `09d43e1` |
| Task-12 Loading + auto-save | **green** | 1 | — | `e33eb5f` |
| Task-18 Profile + delete account | **green** | 1 | — | `e21315c` |
| Task-17 Saved Routes | **green** | 2 | attempt 1 BLOCKED, zero code — see *Attempt-1 blockers* | `49eaa18` |
| Task-19 Account + Language | **green** | 1 | — | `91488e6` |
| Task-13 Result screen | **green**, review-visual pending | 1 | — | `2065651` |
| Task-08 Car backdrop | **green**, review-visual pending | 1 | — | `0f7bca1` |
| Task-10 Onboarding shell | **red, attempt 1 incomplete** | 1 of 2 | bee killed by quota mid-write; `flutter test test/features/onboarding/` **hangs past 600 s** on the partial tree — a pending timer that never completes. Worktree kept for attempt 2. | — |
| Task-15 Stop detail | **red, attempt 1 incomplete** | 1 of 2 | bee killed by quota mid-write; `flutter analyze` clean, `flutter test test/features/itinerary/` **12 pass / 1 fail** — `has no layout exception at 360px width`. Trajectory `baseline 0 fail -> attempt 1: 1 fail`. Worktree kept for attempt 2. | — |
| Task-09 Login + Welcome | **quota-stopped at 87%** — never attempted | 0 | not tried; unblocked and ready | — |
| Task-11 Onboarding step bodies | **quota-stopped** — never attempted | 0 | not tried; blocked behind Task-10 | — |

Seven of eleven green and integrated, each gated twice — once in its own worktree, once on
`main` after the cherry-pick — and marked DONE in both `tasks/Task-XX.md` and
`docs/TASKS_INDEX.md` inside its own integrated commit.

## Awaiting eye check — do this first at the desk

`review-visual` from the main loop, against `docs/screenshots/` and `docs/PRD.md` §7:

- **Task-07** map foundation — `lib/shared/map/`
- **Task-08** car-follows-route backdrop — `lib/shared/map/route_car_backdrop.dart`
- **Task-13** Result screen — `lib/features/itinerary/result_screen.dart`

Their gates prove the code runs, not that the screen looks right. They are **green,
review-visual pending**, not plain green.

## Attempt-1 blockers — my brief was wrong, not the bees

Task-07 and Task-17 both came back BLOCKED having written nothing, on two points:

1. **`core/theme/` was read as forbidden.** My brief said "own only the paths in OWNS".
   No Lane block actually lists `core/theme/` as MUST NOT TOUCH, and Part 2 explicitly
   says to add a missing value there. Fixed by a brief section stating where each kind of
   value goes: prototype dimensions append to `core/theme/metrics.dart`, screen-specific
   durations stay in the feature's own lane (which `motion.dart`'s own header already
   says), colours/radii/type are never new. Every later brief carries it.
2. **A real spec contradiction, not resolved and not silently overridden.**
   `lib/app/routes.dart`'s comment says *"Feature tasks replace the placeholder body
   associated with their destination"*, but every screen task's Lane block lists
   `terra_nt/lib/app/` under MUST NOT TOUCH. So **no bee can wire its screen into the
   app.** The screens and their tests exist and pass; the placeholder→real-body swap is
   still owed. Recorded in `BACKLOG.md`; it belongs with Task-20, which is main-loop
   routed anyway. **The contradiction is the operator's to resolve** — either the comment
   in `routes.dart` is wrong or the MUST NOT TOUCH lines are.

Both re-ran and went green. Counted honestly as 2 attempts each.

## Integration notes

- **`terra_nt/lib/core/theme/metrics.dart` conflicted on every cherry-pick after the
  first.** Four lanes appended their own prototype-measured dimensions to it. Every
  conflict was a plain append collision; both sides were kept and the gate re-run on
  `main` each time. This is the one file that is genuinely shared across lanes — a future
  plan should allocate it to one lane per wave, or split it per domain.
- **One bee-introduced name was corrected at integration.** Task-17 added
  `AppMetrics.iconXxxl = 32.0`, but `metrics.dart`'s own comment reserves `iconHuge` for
  32 on its pre-allocated icon ladder. Renamed to `iconHuge` at the merge and the gate
  re-run. Mechanical, and it honours a naming contract the file already recorded.

## Quota

| Point in the run | Codex, fullest window |
|---|---|
| Preflight | 0% — operator had just reset it |
| After wave 1 (4 bees) | 46% |
| After Task-19 | 76% |
| After Task-08 and Task-13 | 87% |
| Task-10 and Task-15 in flight | **limit hit, both killed** |

The pool was measured before every spawn decision, as the protocol requires. 87% still
read `GO` (the gate trips at 90% `NARROW` / 97% `STOP`), and two more bees fit inside that
verdict on paper — they did not in practice. **The verdict is computed from percentage
used, not from the tokens the next bee will draw, and a mid-tier Flutter bee on this
project costs roughly 10–13% of the window.** A future run should treat anything above
~80% as room for at most one more mid-tier bee.

**The direction was not flipped.** No new bee was spawned after the limit. Per the
protocol, Claude bees on the operator's own pool are not an unattended substitute.

## Resuming

The window resets at **05:20**. A timer is armed for 05:25, and on it the run continues
with the same direction and the same approved selection:

1. **Task-10 attempt 2** and **Task-15 attempt 2** — worktrees `D:\TarikOS\.lanes\tnt-10`
   and `tnt-15` are kept intact with the partial work in place, and each brief gets the
   first gate output plus the trajectory line above it.
2. **Task-09** — unblocked, never attempted.
3. **Task-11** — after Task-10 lands.

If the pool empties again, the same rule applies: no new bee, integrate what exists,
finish this report.

## Worktrees

Removed after integration: `tnt-07`, `tnt-12`, `tnt-17`, `tnt-18`, `tnt-19`, `tnt-08`,
`tnt-13`. **Deliberately kept:** `tnt-10` and `tnt-15`, holding attempt-1 work for the
resume. They are removed at closeout.
