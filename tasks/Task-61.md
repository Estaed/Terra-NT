# Task-61: Onboarding flows without friction
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator routed the 2026-09-30 run to Codex; the step logic and the planner request are pure and fully testable.

**Lane**
- OWNS: `terra_nt/lib/features/onboarding/onboarding_screen.dart`, `terra_nt/lib/features/onboarding/steps/onboarding_steps.dart`, `terra_nt/lib/features/onboarding/widgets/progress_drive.dart`, `terra_nt/lib/core/util/onboarding_rules.dart`, `terra_nt/lib/core/util/plan_request.dart`, `terra_nt/lib/core/util/trip_summary.dart`, `terra_nt/lib/data/models/onboarding_answers.dart`, `terra_nt/lib/data/seed/onboarding_options.dart`, `terra_nt/test/features/onboarding/onboarding_screen_test.dart`, `terra_nt/test/features/onboarding/steps/onboarding_steps_test.dart`, `terra_nt/test/features/onboarding/widgets/progress_drive_test.dart`, `terra_nt/test/core/util/plan_request_test.dart`, `terra_nt/test/core/util/trip_summary_test.dart`, `terra_nt/test/core/util/util_test.dart`, `terra_nt/test/integration/auth_onboarding_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/profile/` (Task-62), `terra_nt/lib/features/saved/` (Task-62), `terra_nt/lib/app/` (Task-62), `terra_nt/lib/data/repositories/` (Task-62), `tools/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: Task-56, Task-58

## Goal

**The questions stop getting in the user's way.**

- **Fixed Next button.** The step's primary button (Next, and Generate My Route on the
  last step) stays in one place from step to step. Today the card is centred and its
  height changes, so the button jumps under the thumb every question.
- **No 4x4 question without a 4x4.** "How confident are you driving a 4x4 off-road?" is
  asked only when the user is travelling in a 4x4. Otherwise the step is skipped, and
  the progress label and the Back path skip it too.
  - The planner request stays complete: a skipped answer sends a value the planning
    server accepts. Read `tools/plan_server/` to see what it validates; do not edit it.
- **Heat readout.** The heat answer ("It's fine either way") uses a smaller text role
  than the big "7 days" number, so the question stays the strongest element.
- **Slider speech.** Both sliders speak their readout to screen readers ("7 days", the
  heat label) instead of a percentage. Today TalkBack reads "46%".
- **Secondary text.** The slider end labels and "Select all that apply" use the brighter
  existing ink token.

## Why

`reports/reviews/2026-09-30/report.md` rows B7, B8, B10, Q5 and Q6. A tap that misses
because the button moved, and a question that contradicts the previous answer, both
make 15 steps feel longer.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Unit tests: step sequencing with and without a 4x4, in both directions; the planner request for a non-4x4 trip contains every key the server requires.
- [ ] Widget tests: the primary button's position is identical across all 15 steps at phone size; the slider semantics value equals the readout text; the heat readout style differs from the days readout.
- [ ] At 360 px and 2x text, no overflow on any step (test).
- [ ] Device tour (Blueprint Verification 6: layout and Back): the main loop walks all steps with a standard car and with a 4x4 on `emulator-5554`, using Back across the skipped step.
- [ ] (eye) Compare step cards with `reports/reviews/2026-09-30/04-heat-question.png` and `18-question-transition-frames.png`: the button stays put and the heat answer no longer shouts.

## Out of scope

- Region pictures and the backdrop (Task-58, on main).
- Auto-advance on single-choice answers. It was built and removed on 2026-09-11 because the screen moved under a user still reading.
