# Task-41 — Explore POI pins carry their tag colour

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* One marker widget reads an existing token map; widget tests assert colours.
> An audit improvement beyond the prototype under `docs/PRD.md` D15, recorded as V21.

**Lane**
- OWNS: `terra_nt/lib/shared/map/map_markers.dart`, `terra_nt/lib/features/explore/explore_screen.dart` (the `PoiPinMarker(...)` call only), `terra_nt/test/shared/map/`
- MUST NOT TOUCH: `terra_nt/lib/core/util/tag_colors.dart` (consume `tagColor()`), `terra_nt/lib/core/theme/`, `terra_nt/lib/features/itinerary/` (Task-40), `terra_nt/lib/data/`, `terra_nt/test/features/explore/` unless an existing expectation on the pin's colour must change, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/shared/map/ test/features/explore/`
- DEPENDS ON: Task-37

## Objective

Every POI pin on Explore is the same primary ring on `surface2`, so a driver cannot tell a
wildlife park from a cultural site without tapping. `Poi.tag` and `tagColor()` (the
`--tag-*` tokens, with the `inkTertiary` fallback) already exist.

## The contract — fixed

- `PoiPinMarker` gains `required Color accent`. Unselected: ring `accent`, fill
  `AppColors.surface2`, plus a centred dot of `accent` at the existing smallest dot
  metric (reuse a named metric; append one to `metrics.dart` only if none fits — that
  file is `core/theme/`, so if a new one is needed, report it instead and use the closest
  existing metric). Selected: fill `accent`, ring `accent` (was primary/primary).
- Explore passes `accent: tagColor(poi.tag)`.
- Numbered route pins (`NumberedPinMarker`) are unchanged.

## Acceptance Criteria (DoD)

- [ ] A widget test pumps `PoiPinMarker(accent: tagColor('Wildlife'))` and asserts the ring and the dot colour equal `tagColor('Wildlife')`; selected asserts the fill.
- [ ] An unknown tag renders with `AppColors.inkTertiary` (the fallback), asserted.
- [ ] `grep -n "accent: tagColor" lib/features/explore/explore_screen.dart` matches.
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
