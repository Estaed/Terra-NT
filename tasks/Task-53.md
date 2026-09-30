# Task-53: The route draws itself, and the Result camera follows the sheet
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; the gate is machine-checkable and the look is an eye check afterwards.

**Lane**
- OWNS: `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/shared/map/terra_map.dart`, `terra_nt/lib/shared/map/dashed_route_polyline.dart`, `terra_nt/lib/shared/map/route_reveal.dart`, `terra_nt/lib/core/theme/motion.dart`, `terra_nt/lib/core/theme/metrics.dart`, `terra_nt/test/features/itinerary/result_screen_test.dart`, `terra_nt/test/shared/map/terra_map_test.dart`, `terra_nt/test/shared/map/route_reveal_test.dart`, `terra_nt/test/core/theme/tokens_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/explore/` (Task-54), `terra_nt/lib/shared/map/map_markers.dart` (Task-54), `terra_nt/lib/features/itinerary/widgets/`, `terra_nt/lib/data/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

Opening a route feels like the trip being laid out. When Result shows a route (after
Loading, or opened from Saved Routes), the dashed route draws from the first stop to
the last and the numbered pins appear in order along it, then everything rests. It
takes about a second and a half, and the sheet and its buttons are usable at once.
When the sheet snaps to another anchor, the map camera eases so every pin sits in the
map strip still visible above the sheet. Today pins 5–7 of Full NT hide under the sheet
at the top anchor.

## Why

`reports/reviews/2026-09-30/report.md` rows M1 and M2 (Result). Today the route and all
pins are simply there when the screen opens. This is the product's "your trip is ready"
moment, and it has no motion at all, while the rest of the app already has entrances.

## Acceptance

- [ ] The Lane GATE passes: analyzer clean, full suite green, release APK builds.
- [ ] A widget test shows the reveal progressing (the polyline partly drawn mid-way, complete at the end) and pins appearing in stop order.
- [ ] With reduced motion (`MediaQuery.disableAnimations`), the route and pins appear complete on the first frame. A test covers it.
- [ ] Opening a different saved route replays the reveal. Editing (reorder, remove, skip) does not replay it.
- [ ] Every animation controller is disposed. A test leaves Result mid-reveal and asserts no exception or ticker leak.
- [ ] Snapping the sheet to each anchor animates the camera to fit all pins in the visible strip (test through the map controller's camera).
- [ ] Welcome, Loading and Explore, which also use `TerraMap`, behave as before (existing tests stay green).
- [ ] (eye) On the emulator, open Full NT from Saved Routes and watch the route draw. Compare against the static `reports/reviews/2026-09-30/10-result-meta.png`: it should read as one smooth gesture, not a slideshow. Drag the sheet up: all seven pins stay visible.

## Out of scope

- Explore's camera and markers (Task-54), and the stop list's own motion (Task-59).
- Changing sheet anchors or the header content.

New durations or curves go into `core/theme/motion.dart` by name (Blueprint D21). No new
package: tween the camera through `MapController`.
