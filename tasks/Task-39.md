# Task-39 — An edited leg shows the straight-line distance instead of "Drive time unavailable"
**Status: DONE** — verified 2026-09-23 01:46 (otopilot goal run: lane gate 84 tests, integrated gate green on main, 471 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* Tier 1 pure Dart in one function with unit tests. An improvement beyond V9
> from the audit, authorised under `docs/PRD.md` D15; recorded as V20 at integration.

**Lane**
- OWNS: `terra_nt/lib/core/util/itinerary_ops.dart`, `terra_nt/test/core/util/util_test.dart`, `terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart` (only its `Drive time unavailable` expectations)
- MUST NOT TOUCH: `terra_nt/lib/features/` (the row widget already renders whatever string this returns), `terra_nt/lib/core/util/plan_response.dart` (Task-38), `terra_nt/lib/data/`, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/core/util/ test/features/itinerary/widgets/result_stop_list_test.dart`
- DEPENDS ON: Task-36

## Objective

After a reorder or removal, V9 replaces a leg whose original successor no longer follows
with `Drive time unavailable`. In a road-trip app the useful fallback is the distance to
the stop that now follows. Coordinates are already on every stop; a great-circle distance
is honest if it says it is a straight line.

## The contract — fixed

- `driveNextForPosition` keeps its signature and every current `null` / baseline result.
- Where it returns `Drive time unavailable` today **and** both the current and the next
  stop have coordinates, it returns `'$km km straight line to ${next.name}'` where `km` is
  the haversine distance (Earth radius 6371 km) rounded to the nearest 5 km, minimum 5.
  Example: Darwin → Kakadu National Park reads `205 km straight line to Kakadu National Park`
  (compute it in the test from the seed; do not hard-code a number you did not compute).
- A private `double _haversineKm(double lat1, double lng1, double lat2, double lng2)` in
  the same file; no new file, no package.
- The existing test expectations of `Drive time unavailable` become the new string; the
  unchanged-leg and last-stop expectations stay.

## Acceptance Criteria (DoD)

- [x] `util_test.dart`: `[0, 2, 1]` position 0 on `seedStops` returns `<n> km straight line to <seedStops[2].name>` with `n` a multiple of 5 within ±5 km of a haversine computed in the test.
- [x] The unchanged-leg case still returns the seeded `driveNext`; the last position still returns null.
- [x] `lib/core/util/itinerary_ops.dart` imports no `package:flutter`.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
