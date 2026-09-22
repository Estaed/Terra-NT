# Otopilot report — 2026-09-23 goal run (Terra NT)

Plan: `reports/otopilot-2026-09-23-plan.md`. SOURCE goal, UNTIL 07:00, Claude bees, images via Codex after 02:01.
Goal gate at start: 5 open. Ledger: `reports/otopilot-2026-09-23-findings.md`.

## Checkpoints

### Wave 1 — 01:05 (Task-34 sonnet, Task-35 sonnet, audit bee sonnet)

| Task | Result | Attempts | Gate | Main commit |
|---|---|---|---|---|
| 35 | green | 1 | lane 63; main 462 | `b4b4263` |

Emulator tour (orchestrator, stub on :8787): 5 findings into the ledger (launch routing, map fit ×2, Plan AI empty state, Profile signed-out). A stale `.git/index.lock` (no git process, 84 s old) blocked one cherry-pick; removed after checking.

### Wave 2 — 01:17 (Task-36, Task-37 sonnet; launched beside Task-34, OWNS disjoint)

| 34 | green | 1 | lane 45; main 463 | `1ea492b` |

Task-34's bee found that the orchestrator's own Task-33 integration patch put `retry: true` on the first attempt (the replace hit `initState`, not `_tryAgain`) — against a real server the first request would have thrown `StateError`. Fixed inside its lane; the new MockClient test covers it.
| 36 | green | 1 | lane 20; main 466; PRD Q2 amended | `bce845f` |
| 37 | green | 1 | lane 46; main 471; V19 recorded | `4dcc486` |
| 39 | green | 1 | lane 84; main 471; V20 recorded | `75cd5d1` |
| 41 | green | 1 | lane 34; main 473; V21 recorded | `270960d` |
| 38 | green | 1 | lane 99; main 482 | `277de58` |

**Goal gate at 01:55: 0 open (5 → 1 → 0).** Run continues on the rubric (ledger, images) until UNTIL.
| 40 | green | 2 (0 → 8 fail full suite → 0) | lane 39; main 485; D16 recorded | `46c07fc` |
| 42 | green | 1 | lane 87; main 509; V22 recorded | `ac1de43` |
| 44 | green | 1 | lane 28; main 511 | `4104549` |
| 43 | green | 2 (0 → 1 fail full suite → 0) | lane 75; main 516 | `a90d66f` |

## Phase 4 — closeout

Eleven tasks, all green, two of them on a second attempt. Baseline 462 tests → **516** on main;
`flutter analyze` clean throughout; the goal gate went 5 → 1 → **0** and the findings ledger is empty.

| Task | What landed | Attempts | Main commit |
|---|---|---|---|
| 34 | Loading keeps V1's 7000 ms minimum on success; retry idempotency tested with `MockClient` | 1 | `d4ddc4d` |
| 35 | Account's verified read no longer swallows every exception; its tests override the auth seam | 1 | `b4b4263` |
| 36 | Cold start with nobody signed in lands on Login (PRD Q2 amended) | 1 | `bf6713a` |
| 37 | Map fit clears the status bar and Explore's search field (V19) | 1 | `746aa72` |
| 38 | Auth wrapper no longer throws past the seam on a null user; blank stop names dropped; `lib/data` coverage 98.1% | 1 | `0940426` |
| 39 | An edited leg shows `<n> km straight line to <stop>` instead of `Drive time unavailable` (V20) | 1 | `9d567d3` |
| 40 | Plan AI shows an empty state until a route exists this session (D16) | 2 (0 → 8 → 0) | `04cb4b6` |
| 41 | Explore POI pins carry their tag colour (V21) | 1 | `e24806f` |
| 42 | Nine bundled place illustrations replace the placeholders; `photoUrl` renders remotely (V22) | 1 | `634e65d` |
| 43 | Warm-up fit regression from Task-37 fixed; Loading warms Result's tiles | 2 (0 → 1 → 0) | `3b491bb` |
| 44 | Account's verification row says `Checking…` while it loads | 1 | `dcc1f4b` |

Assets (orchestrator, not a lane): nine 1200×800 `gpt-image-2` illustrations
(`terra_nt/assets/images/places/`, ~150 KB each) and the app's own adaptive + legacy launcher
icon, commit `2f0e013`. Codex cost for all ten images: **3 %** of one 5-hour window.

**Two defects the run found in the orchestrator's own earlier work**, both now fixed and tested:
the Task-33 integration patch put `retry: true` on the *first* attempt (Task-34's bee), and the
same night's acceptance of an integration-test edit had silently dropped V1's 7000 ms transition
(found while preparing this run).

**Process notes.** Two tasks needed a second attempt for the same reason: a lane's GATE is a
subset of the suite, so tests owned by no lane can still be left red by a correct change. Both
were fixed by widening OWNS for attempt 2 and re-running; neither needed a code change. A stale
`.git/index.lock` (no git process) blocked one cherry-pick and was removed after checking.
The run also paused once when Windows reclaimed a background command for memory pressure; the
emulator and two leftover Gradle daemons were stopped, freeing ~6 GB.

**Deviations and decisions recorded tonight:** `docs/PRD.md` D15 (the operator's standing
authority for this run), D16 (Plan AI empty state), V19 (map fit), V20 (straight-line leg),
V22 (place images), plus dated amendments to Q2 (launch routing) and §3.10 (`Checking…`).
V21 covers the tag-coloured pins.

**Eye check (orchestrator, emulator, 02:45–02:50).** Captures in `reports/shots/final-*.png`.
Verified on a clean install against real Firebase and the stub: Login is the first screen and
carries `Forgot your password? Reset it`; creating an account lands on Welcome; Explore's pins
are tag-coloured and no longer sit under the search field; Plan AI shows `No route yet` with
`Plan My Route`; Saved Routes and Stop detail render the new illustrations; Result's numbered
pins clear the status bar. One cosmetic leftover, logged for the morning: both saved-route
thumbnails show Uluru, because the thumbnail keys on the route's last stop and both seeded
routes end there.

Quota at close: Claude 5-hour 28 %, weekly 57 % (ceiling was 70 %); Codex 3 % of one 5-hour
window for all ten images.

Run closed: max waves (6 of 6; goal gate 0, findings ledger empty, 02:52, well inside UNTIL 07:00).
