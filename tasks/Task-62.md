# Task-62: Honest settings, readable labels, and Saved routes with their own covers
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; the removal and cover choices are unit-testable, the look is an eye check.

**Status: DONE** — verified 2026-09-30, eye check pending: 1
> **Verified against:** 8e5437ba11 terra_nt/lib/app/widgets/bottom_nav.dart e86ccfdf43 terra_nt/lib/data/repositories/notifiers.dart 39e1dc5b3b terra_nt/lib/data/seed/place_images.dart 1d0f50eede terra_nt/lib/features/profile/profile_screen.dart 5a6c8ad8fb terra_nt/lib/features/saved/saved_routes_screen.dart 336ef04b98 terra_nt/test/app/tab_shell_test.dart 7edbd4c084 terra_nt/test/data/place_images_test.dart 32776d2173 terra_nt/test/data/repositories/repositories_test.dart 117d4c4f15 terra_nt/test/features/profile/profile_screen_test.dart e5bcee1a1b terra_nt/test/features/saved/saved_routes_screen_test.dart c428557fa7 terra_nt/test/integration/itinerary_profile_test.dart

**Lane**
- OWNS: `terra_nt/lib/features/profile/profile_screen.dart`, `terra_nt/lib/data/repositories/notifiers.dart`, `terra_nt/lib/app/widgets/bottom_nav.dart`, `terra_nt/lib/features/saved/saved_routes_screen.dart`, `terra_nt/lib/data/seed/place_images.dart`, `terra_nt/test/features/profile/profile_screen_test.dart`, `terra_nt/test/features/saved/saved_routes_screen_test.dart`, `terra_nt/test/data/repositories/repositories_test.dart`, `terra_nt/test/data/place_images_test.dart`, `terra_nt/test/integration/itinerary_profile_test.dart`, `terra_nt/test/app/tab_shell_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/onboarding/` (Task-61), `terra_nt/lib/core/util/` (Task-61), `terra_nt/lib/data/models/onboarding_answers.dart` (Task-61), `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: Task-56, Task-57, Task-60

## Goal

**The app only promises what it does, and the lists are easy to read.**

- **Offline Maps goes.** The "Offline Maps — Download maps for areas with no signal"
  row goes, together with the state behind it. It is a switch that downloads nothing and
  resets on launch (`reports/reviews/2026-09-30/11-profile-offline.png`). No new
  persisted key appears, and none is left behind.
- **Saved covers.** Each saved route gets a cover that matches its region, using the
  bundled scenes `assets/images/scenes/top_end.jpg`, `red_centre.jpg` and `full_nt.jpg`.
  Today "Top End" and "Full NT" both show the same Darwin sunset (`09-saved-meta.png`).
  The cover is a wider, clearer crop than today's small square, and long titles still
  wrap without colliding with the date or chevron.
- **Readable labels.** Unselected bottom-tab labels and saved-route dates use the
  brighter existing ink token. Today they measure 3.30:1 against their surface.
- **Haptic.** A light haptic answers swipe-to-delete on Saved Routes.

## Why

`reports/reviews/2026-09-30/report.md` rows B5, I5 and Q5. A setting that lies is worse
than no setting, and identical covers make routes harder to tell apart.

## Acceptance

- [x] The Lane GATE passes.
- [x] Tests: Profile has no Offline Maps row; after mutating every remaining setting, the persisted keys are exactly the existing set (repositories test).
- [x] Tests: the cover chooser picks Top End, Red Centre and Full NT scenes for matching routes and falls back to the first stop's picture for anything else.
- [x] Swipe-to-delete, open, empty state and explicit-empty-list behaviour are unchanged (existing tests stay green).
- [x] At 360 px and 2x text, Saved rows and the bottom nav do not overflow (test).
- [ ] (eye) On the emulator, compare Saved Routes, Profile and the tab bar with `09-saved-meta.png` and `11-profile-offline.png`: routes are told apart by their pictures, and dates and tab labels read without effort.

## Out of scope

- Real offline map downloads.
- Onboarding (Task-61) and Result.
