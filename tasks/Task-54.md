# Task-54: Explore comes alive
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; one screen, one owner, machine gate plus an eye check.

**Status: DONE** — verified 2026-09-30, eye check pending: 1
> **Verified against:** 5d7aa21a58 terra_nt/lib/core/util/poi_filter.dart 9edaeea445 terra_nt/lib/features/explore/explore_screen.dart 2516d42d92 terra_nt/lib/shared/map/map_markers.dart 649a3f3b2d terra_nt/test/core/util/poi_filter_test.dart 51c3b576ef terra_nt/test/features/explore/explore_screen_test.dart 74bcc7039c terra_nt/test/integration/explore_map_test.dart

**Lane**
- OWNS: `terra_nt/lib/features/explore/explore_screen.dart`, `terra_nt/lib/shared/map/map_markers.dart`, `terra_nt/lib/core/util/poi_filter.dart`, `terra_nt/test/features/explore/explore_screen_test.dart`, `terra_nt/test/integration/explore_map_test.dart`, `terra_nt/test/core/util/poi_filter_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/shared/map/terra_map.dart` (Task-53), `terra_nt/lib/core/theme/` (Task-53), `terra_nt/lib/features/itinerary/` (Task-53), `terra_nt/lib/data/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

Explore reacts to the user:

- **Selecting a place** eases the camera to it, keeping it clear of the card and the
  search field. The marker grows or pulses to show the selection, and the place card
  slides up. Tapping another place crossfades the card content instead of snapping.
  Closing the card slides it away.
- **Markers carry identity.** Each marker shows its tag's Lucide icon inside the
  coloured ring, instead of an anonymous dot.
- **The place card leads somewhere.** It gets a "Navigate" action that opens Google Maps
  directions to that place, the same way Stop detail's Navigate does. Reuse
  `core/util/maps_url.dart`.
- **A search with exactly one match** selects that place and flies to it. More matches
  still filter the markers as today.

## Why

`reports/reviews/2026-09-30/report.md` rows M2 (Explore), M5, I7, Q2 and Q3. Explore is
the app's first screen for a returning user, and it currently has no motion. The card is
a dead end, and a single search result sits unselected at the map's edge
(`13-explore-search.png`).

## Acceptance

- [x] The Lane GATE passes.
- [x] Widget tests: selecting a place moves the camera toward it; a single search match selects it and opens the card; Navigate launches the directions URL for that place (through the existing launcher seam used in tests); clearing search leaves no selection.
- [x] Reduced motion: selection, card and camera change without animation. A test covers it.
- [x] Every marker keeps a touch target of at least 48 logical pixels.
- [x] No controller or ticker leak when leaving Explore mid-animation (test).
- [ ] (eye) On the emulator, tap three places and search "uluru". Compare with `reports/reviews/2026-09-30/01-explore.png`, `12-explore-card.png` and `13-explore-search.png`: the markers read as place types at a glance, and the motion feels quick and connected, not busy.

## Out of scope

- Map tiles and style (stays CARTO dark), and marker clustering.
- Adding a place to a trip.

Use existing motion tokens. If one is truly missing, say so in the report rather than
editing `core/theme/`.
