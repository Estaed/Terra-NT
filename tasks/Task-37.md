# Task-37 — Map fit clears the status bar and the overlays on Explore and Result
**Status: DONE** — verified 2026-09-23 01:39 (otopilot goal run: lane gate 46 tests, integrated gate green on main, 471 tests; emulator recheck pending)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* A padding computation with a widget test at a phone viewport with a top inset.
> Found on the emulator tour (`tour-04-explore.png`, `tour-05-06-pair.png`); a visual
> improvement beyond the prototype, recorded as V19 under `docs/PRD.md` D15.

**Lane**
- OWNS: `terra_nt/lib/shared/map/terra_map.dart`, `terra_nt/lib/features/explore/explore_screen.dart`, `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/core/theme/metrics.dart` (append-only: new named constants at the end), `terra_nt/test/shared/map/`, `terra_nt/test/features/explore/`, `terra_nt/test/features/itinerary/result_screen_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/app/` (Task-36), `terra_nt/lib/features/loading/` (Task-34), `terra_nt/lib/data/`, `terra_nt/lib/shared/map/route_car_backdrop.dart` and `tile_warmup.dart` (decorative/backdrop fits stay as they are), `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/shared/map/ test/features/explore/ test/features/itinerary/result_screen_test.dart`
- DEPENDS ON: Task-35

## Objective

Explore and Result fit the camera to the markers with a flat 30 / 28 px pad. The maps run
full-bleed under the status bar, and Explore's search field floats over the top, so the
northernmost pins (Darwin, Mindil, Litchfield on Explore; stops 1–3 on Result) sit under
the clock and under the search box. The prototype has the same flat pad but no status bar.

## The contract — fixed

- The fit padding's **top** becomes: `MediaQuery.paddingOf(context).top` + the height of
  whatever floats over the map's top edge on that screen (Explore: the search field's
  height and its top margin, both already named in `metrics.dart`) + the existing flat
  pad. Left/right/bottom keep the flat pad; Result's bottom keeps what
  `resultFitPaddingFor` already computes for the sheet.
- The fit is recomputed when the top inset changes (rotation is out of scope; first
  layout is enough), using the existing one-shot fit path in `terra_map.dart`.
- No new colour, radius or duration. A new metric, if needed, is appended to
  `metrics.dart` by name.

## Acceptance Criteria (DoD)

- [x] A widget test pumps Explore at 411×914 with `MediaQueryData(padding: EdgeInsets.only(top: 48))` and asserts the computed fit padding's top is ≥ 48 + the search field height + 30.
- [x] The same for Result: top ≥ 48 + 28.
- [x] Existing Explore and Result tests pass unchanged.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
