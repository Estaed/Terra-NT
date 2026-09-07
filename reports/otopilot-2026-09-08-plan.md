# Otopilot wave plan — 2026-09-08

Approved by the operator in the launch instruction: run 07, 08, 09, 10, 11, 12, 13, 15,
17, 18, 19 unattended; leave 14, 16 and 20 in the main loop. No questions overnight;
blockers go to `BACKLOG.md` with their reason and the run continues.

## Direction

| | |
|---|---|
| Orchestrator | **Claude** (this session) — holds the wake lock, runs `GATE`, cherry-picks, writes the report |
| Bees | **`codex exec`**, worktree-isolated, one commit each |
| Preflight flag | `--delegate codex` |
| `BASE_SHA` | `45aca57d7295e36a5790dc9ef8e697956cbbc56d` |
| Baseline gate | `cd terra_nt && flutter analyze && flutter test` → **clean, 104 tests pass** |
| Stop markers | zero across all 11 selected tasks |
| `BACKLOG.md` | no entries — no task here is a repeat |
| Timebox | 50 min wall clock per bee attempt |
| Attempts | 2 per task, second attempt reuses the same worktree with the first gate output attached |

The direction does not flip mid-run. Model ids are named in the spawn command, not
carried as durable doctrine: read `gpt-5.6-luna` as **small tier**, `gpt-5.6-terra` as
**mid tier**. `gpt-6-astra` never runs unattended.

## Quota snapshot — taken 2026-09-08, preflight

| Pool | 5-hour | 7-day | Verdict |
|---|---|---|---|
| Codex (delegate) | 0% | 0% | **GO** — the operator reset the window before starting |
| Claude (orchestrator) | 2% | 18% | healthy |

Re-measured before every wave with `onkontrol.py --quota-only --delegate codex`.

## One dependency correction, recorded rather than silent

**Task-09's `DEPENDS ON` line is incomplete.** It reads `Task-05, Task-06`, but its own
Execution Guide requires `RouteCarBackdrop` in ambient mode (L34) and asserts the
backdrop is non-interactive (L84) — that widget is Task-08's. Scheduling 09 in wave 1
would produce a guaranteed red on a missing import. It is therefore placed after Task-08.
This is a wave-ordering decision from the task's own body; no routing, ownership or
acceptance criterion was reinterpreted.

## Waves

Two invariants hold in every wave: no task depends on another in the same wave, and
`OWNS` sets are pairwise disjoint after normalisation.

### Wave 1 — four bees in parallel

| Task | Tier | Effort | OWNS | GATE | Est. attempts |
|---|---|---|---|---|---:|
| Task-07 Map foundation | mid | high | `lib/shared/map/`, `test/shared/map/` | `flutter analyze && flutter test test/shared/map/` | 1–2 |
| Task-12 Loading + auto-save | small | high | `lib/features/loading/`, `test/features/loading/` | `flutter analyze && flutter test test/features/loading/` | 1 |
| Task-17 Saved Routes | mid | high | `lib/features/saved/`, `test/features/saved/` | `flutter analyze && flutter test test/features/saved/` | 1–2 |
| Task-18 Profile | mid | high | `lib/features/profile/`, `test/features/profile/` | `flutter analyze && flutter test test/features/profile/` | 1–2 |

Mid tier on 07 (the widget contract every later map task imports), 17 (hand-rolled swipe
with absolute-pixel thresholds) and 18 (V6 — two clearing paths that must not share code).
Small tier on 12: V1 states the timing exactly and the screen is thin.

### Wave 2 — three bees in parallel

| Task | Tier | Effort | OWNS | GATE | Est. attempts |
|---|---|---|---|---|---:|
| Task-08 Car backdrop | mid | high | `lib/shared/map/route_car_backdrop.dart`, `lib/shared/map/car_glyph.dart`, `test/shared/map/route_car_backdrop_test.dart` | `flutter analyze && flutter test test/shared/map/` | 1–2 |
| Task-13 Result screen | mid | high | `lib/features/itinerary/`, `test/features/itinerary/` | `flutter analyze && flutter test test/features/itinerary/` | 2 |
| Task-19 Account + Language | small | high | `lib/features/profile/{account,language}/`, matching tests | `flutter analyze && flutter test test/features/profile/` | 1 |

### Wave 3 — three bees in parallel

| Task | Tier | Effort | OWNS | GATE | Est. attempts |
|---|---|---|---|---|---:|
| Task-09 Login + Welcome | small | high | `lib/features/auth/`, `test/features/auth/` | `flutter analyze && flutter test test/features/auth/` | 1–2 |
| Task-10 Onboarding shell | mid | high | `lib/features/onboarding/`, `test/features/onboarding/` | `flutter analyze && flutter test test/features/onboarding/` | 1–2 |
| Task-15 Stop detail | small | high | `lib/features/itinerary/stop_detail/`, matching tests | `flutter analyze && flutter test test/features/itinerary/` | 1–2 |

### Wave 4 — one bee

| Task | Tier | Effort | OWNS | GATE | Est. attempts |
|---|---|---|---|---|---:|
| Task-11 Onboarding step bodies | small | high | `lib/features/onboarding/steps/`, matching tests | `flutter analyze && flutter test test/features/onboarding/` | 1–2 |

## Dependency closure — what a red task takes with it

| If red | Skipped |
|---|---|
| Task-07 | 08, 13 → and through them 09, 10, 15, 11 |
| Task-08 | 09, 10, 11 |
| Task-13 | 15 |
| Task-18 | 19 |
| Task-10 | 11 |
| Task-12, Task-17 | nothing |

## Excluded tasks and why

| Task | Reason |
|---|---|
| Task-14 Result list / edit mode | `Execution` routes to the main loop, plan mode **yes** — the interaction semantics of V3 are to be decided, not implemented |
| Task-16 Explore | `Execution` routes to the main loop, plan mode **yes** — one filtered state drives three surfaces on the first interactive map |
| Task-20 Mobile readiness | `Execution` routes to the main loop — a bee cannot look at a phone |

The operator named the same three exclusions in the launch instruction.

## Awaiting eye check after the gate

Tasks **07, 08, 09, 11, 13, 15** route as `codex, then in the main loop review-visual`.
Each reports as **green, review-visual pending** — never plain green — and is listed
separately in the closing report for the operator to look at at the desk.
