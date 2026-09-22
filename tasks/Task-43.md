# Task-43 — Tile warmup matches Explore's new fit; Loading warms the Result map
**Status: DONE** — verified 2026-09-23 02:29 (otopilot goal run: attempt 2 — attempt 1 left one stale warm-up assertion red on integration; main green, 516 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* A regression Task-37 introduced (found by the orchestrator while writing wave 6)
> plus one audit improvement, both judged by widget tests on the fit padding the hidden
> map receives.

**Lane**
- OWNS: `terra_nt/test/features/auth/welcome_tile_warmup_test.dart` (added for attempt 2), `terra_nt/lib/shared/map/tile_warmup.dart`, `terra_nt/lib/features/loading/loading_screen.dart`, `terra_nt/test/shared/map/tile_warmup_test.dart` (new or existing), `terra_nt/test/features/loading/`
- MUST NOT TOUCH: `terra_nt/lib/shared/map/terra_map.dart` (consume `exploreFitPaddingFor` / `resultFitPaddingFor`), `terra_nt/lib/shared/widgets/` and every file Task-42 owns, `terra_nt/lib/features/profile/` (Task-44), `terra_nt/lib/data/`, `terra_nt/lib/core/theme/`, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/shared/map/ test/features/loading/ test/integration/auth_onboarding_test.dart`
- DEPENDS ON: Task-40

## Objective

`TileWarmup` exists so Explore does not open on blank tiles: it mounts Explore's exact map
offstage while Welcome is up, so the same tiles land in `flutter_map`'s cache. Its own
comment says the fit padding and viewport must match exactly, because `zoom.round()`
picks the tile level. Task-37 changed Explore to `TerraMap.exploreFitPaddingFor(topInset,
bodyHeight)`; the warmup still passes the flat `TerraMap.exploreFitPadding`, so it can
now round to a different zoom and warm tiles Explore never requests.

Loading also sits for at least 7000 ms (V1, Task-34) before Result opens on a map whose
tiles are cold. Once the itinerary is known, the same trick warms Result's tiles.

## The contracts — fixed

1. `TileWarmup` passes `TerraMap.exploreFitPaddingFor(MediaQuery.paddingOf(context).top,
   shellBodyHeight)` — the same two arguments Explore passes (read `explore_screen.dart`
   to confirm how it derives `bodyHeight`; match it exactly).
2. Loading, from the moment a successful itinerary is in hand until it navigates, mounts
   an `Offstage` `TerraMap(interactive: false, bounds: <the itinerary's stop bounds>,
   fitPadding: TerraMap.resultFitPaddingFor(<Result's map viewport height>, topInset))`
   sized like Result's map area. Read `result_screen.dart` for the exact bounds helper and
   viewport height it uses; do not edit it. Nothing is mounted on failure or cancel.
3. No visible change on either screen.

## Acceptance Criteria (DoD)

- [x] A widget test pumps `TileWarmup` under `MediaQueryData(padding: EdgeInsets.only(top: 48))` and asserts the hidden `TerraMap.fitPadding` equals `TerraMap.exploreFitPaddingFor(48, <bodyHeight>)`.
- [x] A Loading widget test: after a successful fake response and before 7000 ms, exactly one offstage `TerraMap` is in the tree with `resultFitPaddingFor(...)` padding; after a failure, none.
- [x] Existing Loading and integration tests pass unchanged.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
