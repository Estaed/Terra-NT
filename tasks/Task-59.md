# Task-59: The stop list shows what changed, and pictures travel into Stop detail
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; list state is subtle but covered by widget tests.

**Status: DONE** — verified 2026-09-30, eye check pending: 1
> **Verified against:** c40b64cebe terra_nt/lib/app/tab_shell.dart faa347e503 terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart b5f9e4e4eb terra_nt/lib/features/itinerary/widgets/plan_entry_list.dart afe8b309f9 terra_nt/lib/features/itinerary/widgets/result_stop_list.dart e766f180f9 terra_nt/test/app/tab_shell_test.dart 22c522461a terra_nt/test/features/itinerary/result_plan_again_test.dart ec25062638 terra_nt/test/features/itinerary/stop_detail/stop_detail_screen_test.dart e0b770c6f2 terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart

**Lane**
- OWNS: `terra_nt/lib/features/itinerary/widgets/result_stop_list.dart`, `terra_nt/lib/features/itinerary/widgets/plan_entry_list.dart`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart`, `terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart`, `terra_nt/test/features/itinerary/stop_detail/stop_detail_screen_test.dart`, `terra_nt/test/features/itinerary/result_plan_again_test.dart`, `terra_nt/lib/app/tab_shell.dart` and `terra_nt/test/app/tab_shell_test.dart` (added 2026-09-30 by the operator: the tab Navigators need a `HeroController` for the Hero flight)
- MUST NOT TOUCH: `terra_nt/lib/features/loading/` (Task-60), `terra_nt/lib/data/` (Task-60), `terra_nt/lib/shared/map/` (Task-60), `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**Changes to the trip are visible as they happen, and moving between list and detail
feels like one surface.**

- **List motion.** Removing a stop collapses its row. Restoring one opens its row back
  up. Skipping fades the row to its skipped state. A reorder drop settles into place.
  Today all of these snap instantly.
- **Travelling picture.** A stop's picture on the Result card flies into Stop detail's
  hero and back on return (a shared-element transition).
- **Haptics.** A light haptic answers skip, remove, restore, a reorder drop and Stop
  detail's Skip.
- **Hours block.** Stop detail's "Hours" card reads as a tidy label/value block. Today
  the value is right-aligned and breaks into four ragged lines
  (`reports/reviews/2026-09-30/16-stop-hours.png`).

## Why

`reports/reviews/2026-09-30/report.md` rows M3, M4, M8 and B9. When a row just vanishes,
the user cannot tell what they changed.

## Acceptance

- [x] The Lane GATE passes.
- [x] Existing edit-mode behaviour holds: per-row revert, "Restore N removed stops", skip/unskip round trip, drive-time lines (existing tests stay green).
- [x] Widget tests: remove animates out and the row is gone at the end; restore animates in at its original index; the Hero tags on both sides match for every stop.
- [x] Reduced motion: changes apply instantly, and the Hero flight is skipped or instant (test).
- [x] No controller leak when leaving mid-animation (test).
- [x] Device tour (Blueprint Verification 6: drag gesture): the main loop reorders, removes and restores on `emulator-5554`; no Flutter exception in logcat.
- [ ] (eye) On the emulator, open Darwin from Full NT and come back, then remove and restore a stop. It should feel continuous. The hours card should read cleanly against `16-stop-hours.png`.

## Out of scope

- Result's header, sheet and map (Task-53 and Task-56 are on main).
- Stop content and copy.
