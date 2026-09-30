# Task-58: Onboarding shows where the trip is going
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; assets are pre-generated, behaviour is testable, the look is an eye check.

**Lane**
- OWNS: `terra_nt/lib/features/onboarding/onboarding_screen.dart`, `terra_nt/lib/features/onboarding/widgets/progress_drive.dart`, `terra_nt/lib/features/onboarding/steps/onboarding_steps.dart`, `terra_nt/lib/data/seed/onboarding_options.dart`, `terra_nt/test/features/onboarding/onboarding_screen_test.dart`, `terra_nt/test/features/onboarding/steps/onboarding_steps_test.dart`, `terra_nt/test/features/onboarding/widgets/progress_drive_test.dart`, `terra_nt/test/integration/auth_onboarding_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/auth/` (Task-57), `terra_nt/lib/shared/` (Task-57), `terra_nt/lib/app/` (Task-57), `terra_nt/lib/core/util/plan_request.dart`, `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**The 15 questions feel like a journey across the Territory, not a form over darkness.**

- **Backdrop.** The map behind the question card is visible enough to read as NT. Today
  it is so dark it reads as texture (`reports/reviews/2026-09-30/17-onboarding-step.png`).
  Its dotted route **reveals in step with progress**, so the car on the progress road
  and the route on the map tell one story.
- **Region question.** "Which region do you want to focus on?" shows each region as a
  picture card: `assets/images/scenes/top_end.jpg`, `red_centre.jpg` and `full_nt.jpg`.
  Each card has a short example line, e.g. "Top End — Darwin, Litchfield, Kakadu".
  Answer keys sent to the planner do not change.
- The card must stay readable over the brighter backdrop.

## Why

`reports/reviews/2026-09-30/report.md` rows I3, M6, I4 and Q7. Region is the single
answer that most changes the route, and it is currently four bare labels.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] The planner request built from any answer set is unchanged (existing `plan_request` tests stay green; answer keys are untouched).
- [ ] The route reveal follows the step index, moving forward and backward (widget test).
- [ ] Reduced motion shows the reveal state without animating (test).
- [ ] The region cards keep selection, manual Next and screen-reader labels (test), and fit at 360 px and 2x text without overflow.
- [ ] (eye) On the emulator, walk the 15 steps and compare with `17-onboarding-step.png`: the backdrop reads as a map of NT, the region pictures are recognisable, and the question text stays the strongest element.

## Out of scope

- The Next button's position, the off-road question, slider semantics and the heat readout (Task-61).
- Changing question order or content other than the region examples.
