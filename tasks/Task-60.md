# Task-60: Loading draws the chosen trip, and no signal is not a dead end
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; the failure and fallback paths are fully testable with the existing fake repositories.

**Lane**
- OWNS: `terra_nt/lib/features/loading/loading_screen.dart`, `terra_nt/lib/shared/map/route_car_backdrop.dart`, `terra_nt/lib/core/util/plan_failure_copy.dart`, `terra_nt/lib/data/repositories/notifiers.dart`, `terra_nt/lib/data/repositories/itinerary_repository.dart`, `terra_nt/lib/data/seed/seed_data.dart`, `terra_nt/test/features/loading/loading_screen_test.dart`, `terra_nt/test/shared/map/route_car_backdrop_test.dart`, `terra_nt/test/core/util/plan_failure_copy_test.dart`, `terra_nt/test/data/repositories/repositories_test.dart`, `terra_nt/test/data/models_seed_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/itinerary/` (Task-59), `terra_nt/lib/data/repositories/remote_itinerary_repository.dart`, `terra_nt/lib/data/repositories/preferences_store.dart`, `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `tools/`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: Task-56

## Goal

**Loading is about the user's own trip, and a failed plan still gets them on the road.**

- **The chosen trip.** While planning, the backdrop draws the route the user asked for:
  their region and chosen start and end. Today, choosing Darwin → Katherine (Top End)
  still shows the car driving the fixed Darwin → Uluru route
  (`reports/reviews/2026-09-30/15-loading-seed-route.png`). The car drives that route.
  Welcome's ambient backdrop, which shares `route_car_backdrop.dart`, keeps working.
- **The failure state has a picture.** When the planner cannot be reached, the failure
  state shows the bundled scene `assets/images/scenes/no_signal.jpg` in place of the
  small route glyph.
- **An offline way forward.** Beside "Try again", the failure state offers an offline
  route. It comes from the places already on the device, chosen to match the user's
  region and endpoints, and it is clearly labelled as an offline suggestion. It opens in
  Result and saves like a generated route. For this app, "Couldn't reach the planner" is
  the screen a user in the outback will actually see.

## Why

`reports/reviews/2026-09-30/report.md` rows M7/B4, I6 and Q1. The app's premise is
areas with no phone signal, yet the no-signal path currently ends in a wall.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Unit tests: the backdrop route for Top End with Darwin → Katherine starts at Darwin and ends at Katherine; Red Centre routes stay in the south; every region and endpoint pair gives a route of at least 2 points.
- [ ] Unit tests: the offline suggestion for each region and endpoint pair is non-empty, starts and ends at the chosen endpoints when those are places the app knows, and is labelled as offline.
- [ ] Widget tests: the failure state shows Try again, the offline action and Back; the offline action lands on Result with that route and saves it; Try again still resends the same request.
- [ ] The two seams stay two: the offline route comes through the existing `ItineraryRepository` implementations, and no new abstraction is added.
- [ ] (eye) On the emulator, with the planner server stopped, plan Darwin → Katherine: the backdrop draws the Top End, and the failure state looks designed, not like an error dump. Compare with `15-loading-seed-route.png`.

## Out of scope

- The planning server (`tools/`) and the success-path request/response contract.
- Result's own motion (on main from Task-53).
