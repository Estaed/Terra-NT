# Task-04 — Pure logic utilities

Status: DONE

> **Execution:** agent `codex` · effort `high`
> *Why:* Pure functions with table-driven tests; the Execution Guide fixes every edge case, so there is no shape left to decide.

**Lane**
- OWNS: `terra_nt/lib/core/util/`, `terra_nt/test/core/util/`
- MUST NOT TOUCH: `terra_nt/lib/data/` (Task-03 models and seed, Task-05 repositories), `terra_nt/lib/features/` (Task-06), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/core/util/`
- DEPENDS ON: Task-03

## Objective

Implement every algorithm the app needs as a pure function, before any widget exists. Part
2's Verification Rules name most of these explicitly; this task is where that test suite
comes from. Tier 1: **no `package:flutter` import.**

Doing this first is deliberate. Each of these is a place the prototype either hides a
subtlety (arc-length sampling) or contradicts itself (`docs/PRD.md` §7), and both are far
cheaper to get right in a unit test than inside a widget.

## Execution Guide

**Files:** `terra_nt/lib/core/util/`, one file per concern.

### `route_sampler.dart`

Source: `terra-nt-bg-map.html` L89–110. Build a cumulative-distance table over the
polyline, then sample a point at fraction `0..1` by walking that table.

**The subtlety:** the car must travel *along the polyline through every intermediate
stop*. Lerping raw lat/lng between two arbitrary points cuts a chord and skips waypoints
whenever the fraction jump is large. Clamp `f` to `0..1`; guard the zero-length segment
(`cum[i] == cum[i-1]` → segment fraction 0).

### `onboarding_rules.dart`

`canNext(int step, OnboardingAnswers a)` — source L918–934. Steps 1, 9 and 11 are ungated
(two sliders and the two-card choice); step 3 requires `focus.isNotEmpty`; the other
eleven require their answer to be non-null.

Also `progressPercent(step)` = `round(((step + 1) / 15) * 100)` and
`mapFraction(step)` = `step / 14`. Note the two denominators differ — 15 for the counter,
14 for the map. That is correct, not a typo.

### `sheet_snap.dart`

`nearestSnap(double height, {double usableHeight = 700})`. Nominal anchors are
`[190, 430, 700]`. Clamp the top anchor and input to `usableHeight`, discard duplicate
anchors after clamping, and keep every lower anchor that fits. Source L974–984: the scan
keeps the **first** nearest on a tie, so a tie resolves to the *lower* value. The Result
layout supplies the actual available sheet height. For a positive height below 190,
all anchors coalesce at that height rather than overflowing; a zero-height layout does
not render or invoke the draggable sheet.

### `swipe_snap.dart`

Source L1032–1057. `clampOffset(double)` → `-76..0`. `isOpenAfterRelease(double offset)` →
`offset < -38`. `didMove(double delta)` → `delta.abs() > 4` (the tap-vs-drag threshold).

### `maps_url.dart`

Source L1005–1015. Build
`https://www.google.com/maps/dir/?api=1&origin=<lat,lng>&destination=<lat,lng>&travelmode=driving`,
appending `&waypoints=` joined by `|` when there are intermediate stops, URL-encoded.
Returns null below 2 stops.

**Deviation V4 applies:** skipped stops are excluded before the URL is built. Implement
the filter as part of the builder's input contract, and test it.

Also `singleDestinationUrl(Stop)` for Stop detail's "Navigate" (D7).

### `itinerary_ops.dart`

The order operations, kept pure so Task-14 stays thin:

- `reorder(List<int> order, int from, int to)` — matches the prototype's splice semantics.
- `remove(List<int> order, int originalIndex)`.
- **`revertOne(List<int> order, int originalIndex)`** — moves that one stop back to its own
  original index, clamped to the current list length. Removing and re-inserting it may
  shift other present stops by one, but their relative order must not change and missing
  indices must stay missing. **Deviation V3**: the prototype's per-row icon wrongly calls
  a full reset.
- **`restoreRemoved(List<int> order, int totalStops)`** — re-inserts every missing index at
  its original position while preserving the relative order of stops that were never
  removed. **Deviation V3**, same reason.
- `removedCount(order, totalStops)` and `removedLabel(n)` → `"Restore N removed stop"` +
  `"s"` unless `n == 1`.
- `derivedMeta(int stopCount, int days)` → **Deviation V2**: `"<days> days · <count> stops"`,
  never the hard-coded string.
- `driveNextForPosition(List<int> order, int position, List<Stop> baselineStops)` → the
  baseline stop's `driveNext` only when its original successor is immediately next in the
  live order; `"Drive time unavailable"` for any other non-final leg; `null` at the live
  last position. `baselineStops` is the currently opened itinerary, never a global seed.

### `tag_colors.dart`

Source L797. Nature → green, Culture → purple, Adventure → orange, Wildlife → blue,
Relaxation → yellow, **unknown → `inkTertiary`**. Returns a token constant from Task-01.

> This is the one file in `core/util/` permitted to import `core/theme/`. It imports no
> Flutter widget code and stays unit-testable.

### `saved_routes_ops.dart`

`upsert(List<SavedRoute>, SavedRoute)` — source L1022–1030. Matches on id: existing entry
is **replaced in place at its current position**; a new entry is **inserted at the top**.

## Acceptance Criteria (DoD)

- [x] `grep -rn "package:flutter" lib/core/util/` returns nothing.
- [x] Sampler: `f=0` returns the first point, `f=1` the last, and a mid-fraction returns a point **on the correct segment** — asserted against a hand-computed expectation, not a snapshot.
- [x] Sampler: a jump from `f=0` to `f=1` sampled at 20 steps produces a path whose successive points are each within one segment of the last (proves it walks the line, not a chord).
- [x] `canNext` is tested for all 15 steps: false for each of the 12 gated steps with its answer unset, true once set, and true unconditionally for steps 1, 9 and 11.
- [x] `canNext(3, …)` is false with `focus == []` and true with one selection.
- [x] `progressPercent(0) == 7` and `progressPercent(14) == 100`; `mapFraction(0) == 0.0` and `mapFraction(14) == 1.0`.
- [x] `nearestSnap` is tested at exact points, between points, and **at the exact midpoints 310 and 565**, asserting the tie resolves to the lower value.
- [x] `nearestSnap(height, usableHeight: 600)` keeps 190 and 430, uses 600 as the top anchor, and never returns above 600; the default still returns 700 at the top.
- [x] `isOpenAfterRelease(-38) == false` and `isOpenAfterRelease(-39) == true`; `clampOffset` is tested beyond both bounds.
- [x] `maps_url`: a 2-stop route produces **no** `waypoints` parameter; a 3+-stop route joins intermediates with an encoded `|`; fewer than 2 stops returns null.
- [x] `maps_url`: a route whose middle stop is skipped omits that stop from the URL (V4).
- [x] `revertOne` returns the named stop to its clamped original index, preserves the relative order of every other present stop, and does not restore a missing index; it is a no-op when already at that position.
- [x] `restoreRemoved` re-inserts removed stops at their original indices **while preserving a manual reorder** applied to the stops that were never removed — asserted with a case that has both a removal and a reorder.
- [x] `driveNextForPosition` returns the baseline copy for an unchanged adjacent pair, `"Drive time unavailable"` after a reorder or removal changes the next leg, and null at the live last stop. A Red Centre case proves the helper uses that itinerary's recomputed baseline rather than `seedStops`.
- [x] `removedLabel(1)` ends in `"stop"` and `removedLabel(2)` in `"stops"`.
- [x] `derivedMeta(7, 8) == "8 days · 7 stops"`, and `derivedMeta(6, 8)` reflects the drop.
- [x] `tagColor` returns the mapped token for all five known tags and `inkTertiary` for an unknown one.
- [x] `upsert` inserts a new id at index 0; an existing id is replaced **at its original index**, asserted with a 3-entry list where the match is in the middle.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/core/util/` exits 0.
