# Task-40 — Plan AI shows an empty state until a route exists this session
**Status: DONE** — verified 2026-09-23 02:09 (otopilot goal run: attempt 2 — attempt 1 left 8 full-suite failures in tests assuming Result always opens on a route; integrated gate green on main, 485 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* One state flag in the itinerary notifier and one branch in Result, judged by
> widget tests. Found on the emulator tour; a feature beyond the prototype under
> `docs/PRD.md` D15 (recorded as a D-row at integration).

**Lane**
- OWNS: `terra_nt/test/app/tab_shell_test.dart` and `terra_nt/test/integration/itinerary_profile_test.dart` (added for attempt 2), `terra_nt/lib/data/repositories/notifiers.dart` (`ItineraryState` and `ItineraryNotifier` only), `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/features/itinerary/widgets/result_empty_state.dart` (new), `terra_nt/test/features/itinerary/result_empty_state_test.dart` (new), `terra_nt/test/features/itinerary/result_screen_test.dart`
- MUST NOT TOUCH: `terra_nt/test/data/` (Task-38), `terra_nt/lib/data/repositories/firebase_auth_repository.dart` (Task-38), `terra_nt/lib/core/util/` (Task-39), `terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart` (Task-39), `terra_nt/lib/app/`, `terra_nt/lib/shared/map/` (Task-41), `terra_nt/lib/core/theme/` except appending named metrics, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/itinerary/`
- DEPENDS ON: Task-37

## Objective

`ItineraryNotifier.build()` seeds the Full NT itinerary, so a user who skipped
onboarding — or a returning user at cold start — opens Plan AI onto a route they never
planned, titled and metered as if generated ("7 days · 7 stops"). With real generation
(phase 3) that is a fake result. Plan AI should say there is no route yet and offer to
plan one.

## The contracts — fixed

1. `ItineraryState` gains `final bool hasRoute;` — `false` from `build()`, `true` after
   `setItinerary`, `openSavedRoute` and `loadForAnswers`; `reset()` and `copyWith` keep
   it. `ItineraryState.forItinerary` takes it as a named parameter defaulting to `true`.
2. `ResultScreen` renders `ResultEmptyState` (new widget, own file) instead of the map
   and sheet when `hasRoute` is false. Layout reuses the Saved Routes empty-state pattern
   (`saved_routes_screen.dart`, the "No saved routes yet" block): `LucideIcons.sparkles`
   icon, title `No route yet`, body `Answer a few questions and we'll plan a route across
   the Territory.`, primary button `Plan My Route`. Same tokens as that block; no new
   colour, radius or duration.
3. `Plan My Route` does what the Result header's "Plan again" does after its confirm —
   reset the answers and session edits and return to onboarding step 0 — with no confirm
   (there are no edits to lose). Reuse the existing Plan-again code path; do not
   duplicate it.
4. The Result header, sheet and map are unchanged when `hasRoute` is true.

## Acceptance Criteria (DoD)

- [x] `result_empty_state_test.dart`: with a fresh container (no route) Plan AI's Result shows `No route yet`, the body line and `Plan My Route`; tapping the button lands on onboarding step 0 (`1/15`).
- [x] `result_screen_test.dart`: after `setItinerary`, the map and sheet render and the empty state does not.
- [x] A notifier test (in `result_screen_test.dart` or the new file — `test/data/` is Task-38's) asserts `hasRoute` false → true after `openSavedRoute`.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
