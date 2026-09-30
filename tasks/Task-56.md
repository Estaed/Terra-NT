# Task-56: Route facts are true: day count, pins in view, honest date label
> **Execution:** agent `codex` · effort `high`
> *Why:* It touches persisted saved routes, so precision matters and every case is testable; the operator routed this run to Codex.

**Lane**
- OWNS: `terra_nt/lib/data/models/saved_route.dart`, `terra_nt/lib/data/models/itinerary.dart`, `terra_nt/lib/core/util/stop_json.dart`, `terra_nt/lib/core/util/itinerary_ops.dart`, `terra_nt/lib/core/util/saved_routes_ops.dart`, `terra_nt/lib/data/seed/seed_data.dart`, `terra_nt/lib/data/repositories/notifiers.dart`, `terra_nt/lib/data/repositories/preferences_store.dart`, `terra_nt/lib/data/repositories/firestore_saved_routes.dart`, `terra_nt/lib/features/loading/loading_screen.dart`, `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/shared/map/terra_map.dart`, `terra_nt/test/core/util/stop_json_test.dart`, `terra_nt/test/core/util/util_test.dart`, `terra_nt/test/core/util/saved_routes_order_test.dart`, `terra_nt/test/data/models_seed_test.dart`, `terra_nt/test/data/repositories/repositories_test.dart`, `terra_nt/test/features/loading/loading_screen_test.dart`, `terra_nt/test/features/itinerary/result_screen_test.dart`, `terra_nt/test/shared/map/terra_map_test.dart`, `terra_nt/test/integration/itinerary_profile_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/app/` (Task-55), `terra_nt/lib/features/explore/`, `terra_nt/lib/features/saved/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: Task-53

## Goal

**Every fact Result and Saved Routes show about a route agrees and stays true.**

- **Day count.** A route carries its own day count. Opening "Full NT" from Saved Routes
  shows its own days, the same number the Saved Routes row shows. Today Saved says
  8 days and Result says 7, because the header reads the last onboarding answer.
  - A generated route saves the days it was planned with.
  - Saved routes stored before this change have no day count. They must load intact
    and show their stored meta line as it is; they must never be dropped or replaced by
    the seed.
  - The Firestore copy keeps the same shape.
- **Pins in view.** Pins are never cropped at the map edge. On "7 Days in the Red
  Centre", stop 1 is currently hidden behind stop 2 at the right edge and stop 4 touches
  the left edge (`reports/reviews/2026-09-30/14-red-centre-fit.png`). The fit leaves room
  for the pin's own size, and pins that overlap at the fitted zoom can both be told apart
  and tapped.
- **Date label.** The generated route's date label says something that stays true for
  as long as it sits in Saved Routes. "Generated just now" is permanent today.

## Why

`reports/reviews/2026-09-30/report.md` rows B2, B3 and B6. A route planner that shows
the wrong number of days, or hides a stop, loses the user's trust.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Unit tests: stop/route JSON round-trip with days; an old stored entry without days loads intact with its original meta; an explicitly empty stored list stays empty; the seed routes carry days that match their meta.
- [ ] Widget tests: open "Full NT" from state where the onboarding answer is 3 days, and the header shows the route's own days; a generated route's header and its Saved row agree.
- [ ] A fit test: for both seed routes at phone size, every pin's full marker lies inside the visible map strip.
- [ ] (eye) On the emulator, open both seed routes from Saved Routes: the day counts match their rows and every numbered pin is fully visible. Compare with `09-saved-meta.png`, `10-result-meta.png` and `14-red-centre-fit.png`.

## Out of scope

- The route-drawing motion (Task-53, already on main) and navigation (Task-55).
- Loading's backdrop and failure state (Task-60).

Persisted data can be lost on this path. The migration test is mandatory, not optional.
