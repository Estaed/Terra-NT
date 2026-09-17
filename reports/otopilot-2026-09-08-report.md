# Otopilot run report — 2026-09-08

**All eleven approved tasks are green, gated and integrated on `main`.**
Final state: `flutter analyze` clean, **195 tests pass**, head `c80667f`.

Plan: `reports/otopilot-2026-09-08-plan.md`. Direction: Claude orchestrates, `codex exec`
bees, worktree-isolated, one commit each. Every commit was gated twice — once in the bee's
own worktree, once on `main` after the cherry-pick — by the orchestrator, never by the bee
that wrote it.

`BASE_SHA` `45aca57`, baseline clean at 104 tests. The run added **91 tests**.

## Outcome per task

| Task | Result | Attempts | Trajectory | Final SHA |
|---|---|---:|---|---|
| Task-07 Map foundation | green · **review-visual pending** | 2 | attempt 1 BLOCKED, zero code | `09d43e1` |
| Task-12 Loading + auto-save | green | 1 | — | `e33eb5f` |
| Task-18 Profile + delete account | green | 1 | — | `e21315c` |
| Task-17 Saved Routes | green | 2 | attempt 1 BLOCKED, zero code | `49eaa18` |
| Task-19 Account + Language | green | 1 | — | `91488e6` |
| Task-13 Result screen | green · **review-visual pending** | 1 | — | `2065651` |
| Task-08 Car backdrop | green · **review-visual pending** | 1 | — | `0f7bca1` |
| Task-10 Onboarding shell | green | 2 | `0 fail -> 8 did-not-complete -> 0 fail` | `13eda00` |
| Task-15 Stop detail | green · **review-visual pending** | 2 | `0 fail -> 1 fail -> 0 fail` | `6e4d922` |
| Task-11 Onboarding step bodies | green · **review-visual pending** | 1 | — | `a46422b` |
| Task-09 Login + Welcome | green · **review-visual pending** | 2 | `0 fail -> 5 fail -> 0 fail` | `c80667f` |

Not attempted, exactly as instructed: **Task-14**, **Task-16**, **Task-20**. Their
`Execution` blocks route to the main loop; nothing in this run touched them or their rows.

## Do this first at the desk — awaiting eye check

`review-visual` from the main loop, against `docs/screenshots/` and `docs/PRD.md` §7. These
six are **green, review-visual pending** — never plain green. Their gates prove the code
runs, not that the screen looks right:

- **Task-07** map foundation — `lib/shared/map/`
- **Task-08** car-follows-route backdrop — `lib/shared/map/route_car_backdrop.dart`
- **Task-09** Login and Welcome — `lib/features/auth/`
- **Task-11** onboarding step bodies — `lib/features/onboarding/steps/`
- **Task-13** Result screen — `lib/features/itinerary/result_screen.dart`
- **Task-15** Stop detail — `lib/features/itinerary/stop_detail/`

**One thing will block that check.** Every screen above is built and tested but **not
reachable by running the app** — see the next section.

## The one real blocker, and it is yours to decide

`terra_nt/lib/app/routes.dart` still renders `AppPlaceholderScreen` for every destination.
Its own comment says *"Feature tasks replace the placeholder body associated with their
destination"* — but **every screen task's Lane block lists `terra_nt/lib/app/` under MUST
NOT TOUCH.** So no bee could wire its screen in, and reinterpreting routing is exactly what
otopilot is forbidden to do. Task-17's first bee stopped dead on this.

The screens and their widget tests exist and pass; only the placeholder→real-body swap is
owed. It is one small main-loop commit and belongs with Task-20's integrated device
journey, which is main-loop routed anyway. Recorded in `BACKLOG.md`.

**Either the comment in `routes.dart` is wrong, or the MUST NOT TOUCH lines are.** That is a
Blueprint / task-file contradiction and Part 1 rule 8 says it is your call, not mine.

## What went wrong, honestly

**1. Two bees returned BLOCKED with zero code, and it was my brief's fault.** Task-07 and
Task-17 read my "own only the paths in OWNS" as forbidding a new named constant in
`core/theme/`. No Lane block lists that directory as MUST NOT TOUCH, and Blueprint explicitly
says to add a missing value there. Fixed mid-run with a brief section stating where each
kind of value goes — prototype dimensions append to `metrics.dart`, screen-specific
durations stay in the feature's own lane (which `motion.dart`'s header already says),
colours/radii/type are never new. Both re-ran green. Counted as 2 attempts each.

**2. The house rule and this protocol contradict each other on git.** The TarikOS bee
preamble says *"GIT YOK: add/commit/push/checkout/stash"*; otopilot requires the bee to make
exactly one commit and defines the gate over it. Seven bees committed anyway; Task-10's and
Task-09's read the preamble strictly and left green worktrees uncommitted. For Task-10 I
gated the worktree independently and packaged the commit myself — the bee wrote the code, I
measured it, so producer and measurer stayed separate. Then I added a narrowing section to
the briefs: `add` and `commit` inside your own worktree are authorised; `push`, `checkout`,
`branch`, `merge`, `rebase`, `stash` remain forbidden. Task-11 and Task-09 committed cleanly
after that. **This one is worth fixing at the source** — either the preamble or the otopilot
skill should say which wins, rather than each bee deciding.

**3. The quota gate reads the wrong quantity.** At 87% the checker still said `GO` (it trips
at 90% `NARROW` / 97% `STOP`), so I spawned two more bees. Both were killed mid-write when
the window emptied. The verdict is computed from percentage *used*, not from what the next
bee will *draw*, and a mid-tier Flutter bee on this project costs 10–13% of the window.
**Treat anything above ~80% as room for at most one more mid-tier bee.**

**4. Parallel lanes contend on the Flutter SDK lock.** Task-09's first bee could not run its
gate at all — `flutter analyze` and `flutter test` both exited 1 on an SDK lock held by a
sibling lane, while `dart analyze` worked. Worktree isolation does not isolate the SDK. Four
concurrent Flutter bees is past the safe limit; three was fine all night.

**5. A stale `index.lock` killed a cherry-pick.** Thirteen `git` processes were hung on the
main repo for hours — every one read-only (`status --porcelain`, `rev-parse`,
`symbolic-ref`), the harness's own probes. One had left a 0-byte lock. I verified every
command line was read-only before removing the lock and clearing the hung probes. No bee
process was touched.

**6. My diagnosis of Task-10 was wrong, and the bee corrected it.** I read the hang as a
pending-timer deadlock and wrote that into the attempt-2 brief. The bee found it was an
infinite gated-navigation loop in the badge test and fixed that instead. Worth recording:
the trajectory line and the raw gate output were what mattered; my interpretation of them
was not, and a confident wrong diagnosis in a brief could have sent it the wrong way.

## Integration notes

- **`core/theme/metrics.dart` conflicted on nearly every cherry-pick.** Six lanes appended
  their own prototype-measured dimensions. All plain append collisions; both sides kept and
  the gate re-run on `main` each time. **A future plan should allocate this file to one lane
  per wave, or split it per domain** — it is the only genuinely shared file in the tree.
- **One bee-introduced name corrected at integration.** Task-17 added
  `AppMetrics.iconXxxl = 32.0`, but `metrics.dart`'s own comment reserves `iconHuge` for 32
  on its pre-allocated icon ladder. Renamed at the merge, gate re-run.
- **One dependency correction, made before the run and recorded in the plan.** Task-09's
  `DEPENDS ON` reads `Task-05, Task-06` but its body requires `RouteCarBackdrop` (Task-08).
  Scheduled after Task-08 rather than in wave 1. **The task file should be corrected.**

## Quota

| Point | Codex, fullest window |
|---|---|
| Preflight | 0% (operator had just reset it) |
| After wave 1 (4 bees) | 46% |
| After Task-19 | 76% |
| After Task-08 + Task-13 | 87% |
| Task-10 and Task-15 in flight | **limit hit — both killed** |
| After reset, 05:25 | 17% |
| End of run | 18% |

The window emptied at ~02:13 and reset at 05:20. Per the protocol I spawned nothing new,
kept the two partial worktrees, armed a timer for 05:25, and resumed with the same direction
and the same approved selection. **The direction was never flipped** — Claude bees would
have spent your own pool unattended.

## Worktrees

All removed; `git worktree list` shows only the main checkout. One leftover: the directory
`D:\TarikOS\.lanes\tnt-10` (~72 MB) survives as build artefacts only — its git registration
is pruned and its work is on `main`. A lingering dart process holds `.dart_tool` lock files.
Delete it when convenient; there is no unfinished work in it.

## Recommended next steps

1. **Wire the screens into `lib/app/`** and resolve the `routes.dart` contradiction — this
   unblocks everything visual.
2. **`review-visual`** on the six screens listed above.
3. **`/code-review`** over the accumulated diff (`45aca57..c80667f`) — a group of eleven
   tasks is exactly the batch Part 1 wants reviewed together. Feed it the task files and
   Blueprint.
4. Then Task-14, Task-16 and Task-20 in the main loop, as routed.
