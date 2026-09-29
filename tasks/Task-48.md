# Task-48 — The progress bar is a road, and the car is a real vehicle

> **Execution:** agent `ultracode` · effort `xhigh`
> *Why:* One shared glyph and one shared progress widget, judged by eye on the emulator
> (onboarding header, Loading, the auth map backdrop) and by the suite.

**Lane**
- OWNS: `terra_nt/lib/shared/map/car_glyph.dart`, `terra_nt/lib/features/onboarding/widgets/progress_drive.dart`, `terra_nt/lib/features/onboarding/onboarding_screen.dart` (the header row: back button, progress, step count — nothing below it), `terra_nt/lib/core/theme/metrics.dart` (append only), their tests under `terra_nt/test/`
- MUST NOT TOUCH: `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `terra_nt/lib/core/theme/motion.dart`, `terra_nt/lib/core/theme/colors.dart`, `terra_nt/lib/features/loading/`, `terra_nt/lib/features/onboarding/steps/`, `terra_nt/lib/shared/map/route_car_backdrop.dart`, `terra_nt/lib/shared/widgets/`, `docs/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: none (the sprite is committed before `BASE_SHA`)

## Goal

The onboarding progress reads as a trip being driven, not a thin line in a boxed pill, and the
car everywhere (onboarding, Loading's looping bar, the map behind Login) is the rendered 4x4
sprite instead of the drawn icon with a blob shadow.

## Why

Operator, 2026-09-29: the app "looks very amateur" and the progress bar was named first
(`docs/PRD.md` D18). Captures of the current state: `reports/screens/2026-09-29-tour/tour-01-step15.png`
(header), `tour-02-loading.png` (Loading bar), `reports/shots/final-01-launch.png` (map car).

## Direction — the contract is the outcome, the route is yours

1. **Car:** `CarGlyph` draws `assets/images/car.png` (a right-facing side-view 4x4 on a
   transparent background, already committed, listed by the existing `assets/images/` line).
   Keep what the glyph does today: it flips to face its direction of travel and bobs on
   `AppMotion.mapCarBob`. Drop the blob shadow. Size it so it reads as a vehicle at phone size
   in all three places; add any new size to `metrics.dart` by name.
2. **Progress:** no bordered pill container around the bar. The track reads as a road — for
   example a quiet track with a faint dashed centre line, the travelled part in
   `AppColors.primary` — and the car sits on it at the leading edge, riding the fill on each
   step change as it does now. The step count reads as words ("Step 3 of 15"), sentence case,
   in an existing type role. The looping variant Loading uses keeps its API and behaviour.
3. Tokens by name only: existing colours, radii and motion tokens; no new colour, no gradient,
   no glow, no shadow.
4. Behaviour stays: back button, step changes, V12 (advance on Next only), all timings.

## Acceptance Criteria (DoD)

- [ ] `CarGlyph` renders an `Image.asset('assets/images/car.png')` (widget test), still
      mirrors for a negative direction, and disposes its controller (existing leak test green).
- [ ] The onboarding header shows `Step 1 of 15` on the first step and `Step 15 of 15` on the
      last (widget test); no `DecoratedBox`/`Container` border wraps the progress bar.
- [ ] `cd terra_nt && flutter analyze` is clean; `cd terra_nt && flutter test` passes.
- [ ] (eye) Onboarding header, Loading's bar and the Login map on the emulator: the car reads
      as a 4x4 at phone size, the bar reads as a road, nothing clips at 411 dp width.
