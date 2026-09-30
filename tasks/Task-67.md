# Task-67: Concrete choices get icons, and Loading's failures say what happened
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator approved the 2026-10-01 audit wave and named Codex; icons by name from flutter_lucide, judged by eye.

**Lane**
- OWNS: `terra_nt/lib/features/onboarding/steps/onboarding_steps.dart`, `terra_nt/lib/data/seed/onboarding_options.dart`, `terra_nt/lib/features/loading/loading_screen.dart`, `terra_nt/lib/core/util/plan_failure_copy.dart`, `terra_nt/test/features/onboarding/steps/onboarding_steps_test.dart`, `terra_nt/test/features/onboarding/onboarding_screen_test.dart`, `terra_nt/test/features/loading/loading_screen_test.dart`, `terra_nt/test/core/util/plan_failure_copy_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/itinerary/` (Task-66), `terra_nt/lib/features/explore/` (Task-66), `terra_nt/lib/core/util/onboarding_rules.dart`, `terra_nt/lib/core/util/plan_request.dart`, `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**Where a choice is a concrete thing, the user recognises it at a glance. Where planning fails
for a reason other than no signal, the screen names that reason.**

Source: `reports/research/2026-10-01-visual-audit.md` rows 2, 3, 5, 6 and its "leave alone"
list. Icons are Lucide names checked against `flutter_lucide` 1.34.0, rendered through
`AppIcon` with existing tokens.

- **Vehicle:** `car_front` (4x4), `caravan` (Campervan), `car` (Standard Car), `bus_front` (Guided Tour).
- **Stay:** `tent` (Camping), `house` (Motel/Cabin), `hotel` (Hotel). The camping-or-resort
  question: `tent`, `bed_double`, `hotel`.
- **Trip focus:** the same category icons Explore's markers already use for Nature, Culture,
  Adventure and Relaxation.
- One neutral leading icon per option; labels stay. No icon tiles or colour blocks.
- **Leave text-only:** companions, budget, activity level, age, trip length, heat, 4x4
  confidence, off-grid. The audit judged icons there to be decoration.
- **Loading failure states:** "couldn't plan this trip" gets `circle_alert`, an expired session
  gets `log_in`. The no-signal failure keeps its `no_signal` scene.
- **Loading's panel:** Loading repeats progress imagery (a map car, a second looping car in the
  panel and a pulsing badge). Keep the map journey and simplify the panel's progress cue to one.

## Why

The visual audit found no missing artwork, only missing recognition on concrete choices and
generic failure states.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Widget tests: each listed option shows its icon. The text-only questions show none. Each failure kind shows its icon, and no-signal keeps the scene. The panel shows one progress cue.
- [ ] At 360 px and 2x text, every onboarding step and every Loading state shows no overflow (test).
- [ ] (eye) On the emulator: the vehicle, stay and focus steps and a planning failure. The icons read as quiet cues in the Tarik Base / Terra NT language (the `tasarim` skill), not decoration. Loading feels calmer than `reports/screens/2026-09-30-wave3/t60-loading.png`.

## Out of scope

- Launcher icon and splash (a separate art decision). New generated artwork.
- Any change to onboarding logic or the planner request.
