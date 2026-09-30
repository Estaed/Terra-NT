# Task-57: Welcome and the empty Plan AI tab open on a journey scene
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; the artwork is generated and committed by the orchestrator before this wave, and this task composes it.

**Status: DONE** — verified 2026-09-30, eye check pending: 1
> **Verified against:** af3c0dc0c6 terra_nt/lib/app/tab_shell.dart b425867d9e terra_nt/lib/features/auth/welcome_screen.dart 685c0e7de9 terra_nt/lib/features/itinerary/result_screen.dart 9df6fca3bd terra_nt/lib/features/itinerary/widgets/result_empty_state.dart 5d79177d3b terra_nt/lib/shared/widgets/journey_scene.dart bec0580c1d terra_nt/test/app/tab_shell_test.dart a7705b020c terra_nt/test/features/auth/auth_screen_test.dart df906b7b6a terra_nt/test/features/auth/welcome_tile_warmup_test.dart ea84b4e96c terra_nt/test/features/itinerary/result_empty_state_test.dart 2585c314db terra_nt/test/shared/widgets/journey_scene_test.dart

**Lane**
- OWNS: `terra_nt/lib/features/auth/welcome_screen.dart`, `terra_nt/lib/features/itinerary/widgets/result_empty_state.dart`, `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/app/tab_shell.dart`, `terra_nt/lib/shared/widgets/journey_scene.dart`, `terra_nt/test/features/auth/auth_screen_test.dart`, `terra_nt/test/features/auth/welcome_tile_warmup_test.dart`, `terra_nt/test/features/itinerary/result_empty_state_test.dart`, `terra_nt/test/shared/widgets/journey_scene_test.dart`, `terra_nt/test/app/tab_shell_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/onboarding/` (Task-58), `terra_nt/lib/data/seed/onboarding_options.dart` (Task-58), `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `terra_nt/lib/features/auth/login_screen.dart`, `terra_nt/lib/features/auth/create_account_screen.dart`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: Task-53, Task-55, Task-56

## Goal

**The two "start here" surfaces lead with a picture of the trip instead of a small
icon or a card floating over darkness.**

- **Welcome** opens on the bundled scene `assets/images/scenes/start_trip.jpg`: a
  painted NT road trip with the white 4x4. The title, message, "Create My Route" and
  "Skip for Now" sit clearly with it. Today it is a compact card over a near-invisible
  map (`reports/reviews/2026-09-30/08-welcome-illustration.png`).
- **Empty Plan AI** puts the same scene above "No route yet". Today it is a sparkle icon
  in a black void (`05-plan-empty.png`).
- **A way back to saved trips.** When the user has saved routes, empty Plan AI also
  offers a quiet secondary action that opens Saved Routes.
- **Shared widget.** The scene treatment is one widget (`journey_scene.dart`) so both
  screens crop, fade in and frame the art the same way.

Text always leads. Art never sits behind essential text or covers a button. A short
screen scrolls rather than hiding an action.

## Why

`reports/reviews/2026-09-30/report.md` rows I1, I2, I8 and Q4, and
`illustration-review.md`. These are the first things a new user and a returning user
without a route see.

## Acceptance

- [x] The Lane GATE passes.
- [x] Existing Welcome behaviour holds: both actions, the invisible tile warm-up, no bottom nav (existing tests stay green).
- [x] The scene is decorative to accessibility services and not tappable (test).
- [x] At 360 logical px wide and at 2x text scale: no overflow and every action is reachable (tests).
- [x] The secondary Saved Routes action shows only when saved routes exist, and switches to the Saved tab (test).
- [ ] (eye) On the emulator, compare Welcome and empty Plan AI with `08-welcome-illustration.png` and `05-plan-empty.png`: the scene reads as NT at a glance, the text is easy to read, and the primary button is the first thing the thumb finds.

## Out of scope

- Generating artwork. The assets are already on main; if one is missing, stop and report.
- Login and Create account screens, and onboarding (Task-58).
