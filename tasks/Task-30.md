# Task-30 — Stable answer keys and the `PlanRequest` builder

**Status: DONE** — verified 2026-09-23 00:36 (otopilot: worktree gate green, integrated gate green on main, 426 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; tonight's bees are Claude by operator decision, 2026-09-22)
> *Why:* Tier 1 pure Dart plus a mechanical label→key move in the onboarding steps; the
> criterion is `flutter analyze` + tests. The key table is fixed in
> `docs/PHASE-3-CONTRACT.md` §2 and is not the bee's to choose.

**Lane**
- OWNS: `terra_nt/lib/data/models/onboarding_answers.dart`, `terra_nt/lib/data/seed/onboarding_options.dart` (new), `terra_nt/lib/core/util/plan_request.dart` (new), `terra_nt/lib/features/onboarding/`, `terra_nt/test/core/util/plan_request_test.dart` (new), `terra_nt/test/features/onboarding/`, `terra_nt/test/data/models_seed_test.dart` (append-only — Task-26 adds a seed assertion to it too; add, never edit)
- MUST NOT TOUCH: `terra_nt/lib/data/seed/seed_data.dart` (Task-26), `terra_nt/lib/data/repositories/`, `terra_nt/lib/features/loading/` (Task-26, Task-33), `terra_nt/lib/shared/`, `terra_nt/lib/core/theme/`, `terra_nt/pubspec.yaml`
- GATE: `cd terra_nt && flutter analyze && flutter test test/core/util/ test/features/onboarding/`
- DEPENDS ON: Task-26

## Objective

The fifteen answers become a wire format. Today `OnboardingAnswers` holds the labels the
screen shows (`'Couple'`, `'4x4'`); rewording a label would change what the server
receives, and English UI copy would ship into the model's context. After this task every
single-select answer is a stable machine key, the labels live beside the keys in one
tier-1 table, and `buildPlanRequest` produces exactly the JSON in
`docs/PHASE-3-CONTRACT.md` §2. `docs/PRD.md` D14 is the decision.

## The contracts — fixed, not guidance

### 1. `onboarding_options.dart` — tier 1, `lib/data/seed/`

```dart
class AnswerOption {
  final String key;
  final String label;
  const AnswerOption(this.key, this.label);
}

const ageRangeOptions = [AnswerOption('18_25', '18–25'), AnswerOption('26_35', '26–35'),
    AnswerOption('36_50', '36–50'), AnswerOption('50_plus', '50+')];
const companionsOptions = [solo/Solo, couple/Couple, family/Family, friends/Friends];
const focusOptions = [nature/Nature, aboriginal_culture/Aboriginal Culture,
    adventure/Adventure, relaxation/Relaxation];
const vehicleOptions = [four_wd/4x4, campervan/Campervan, standard_car/Standard Car,
    guided_tour/Guided Tour];
const budgetOptions = [budget/Budget, mid_range/Mid-range, luxury/Luxury];
const accommodationOptions = [camping/Camping, motel_cabin/Motel/Cabin, hotel/Hotel];
const activityLevelOptions = [low/Low, medium/Medium, high/High];
const regionOptions = [top_end/Top End, red_centre/Red Centre, full_nt/Full NT];
const offRoadConfidenceOptions = [low/Low, medium/Medium, high/High];
const campingPreferenceOptions = [camping/Camping all the way, mixed/Bit of both,
    resort/Resort comfort];
const wildlifeInterestOptions = [not_fussed/Not fussed, interested/Interested,
    big_draw/Big draw];
```

Labels are **character for character** the strings in `onboarding_steps.dart` today
(the prototype's copy); the shorthand above is `key/label`. Helper
`String labelFor(List<AnswerOption> options, String key)` returns the label or the key
itself when unknown.

### 2. `OnboardingAnswers` stores keys

Field names and types are unchanged; the `String?` fields and `focus` now hold keys.
The two text answers, `days`, `heat` and `offGridComfortable` are unchanged. Anything
that rendered an answer back (a summary, a selected-state check) goes through
`labelFor`. The `key` a step writes is `option.key`; the label it draws is
`option.label`.

### 3. `buildPlanRequest` — tier 1, `lib/core/util/plan_request.dart`

```dart
/// Throws StateError when any gated answer is null or focus is empty — a
/// request must never leave with a hole in it.
Map<String, Object?> buildPlanRequest(OnboardingAnswers answers, {required String requestId});

/// 32 lowercase hex chars from Random.secure(). Pure Dart, no package.
String newRequestId();
```

Output is exactly `docs/PHASE-3-CONTRACT.md` §2: `schemaVersion: 1`, `requestId`, and
`answers` with the sixteen fields in that order, `startLocation`/`endLocation` trimmed.
`jsonEncode` of the result is the body Task-32 sends. No `package:flutter` import.

## Execution Guide

(1) The options file and its uniqueness test; (2) `OnboardingAnswers` + the steps,
fixing `onboarding_steps_test.dart` and `onboarding_screen_test.dart` — they select by
label text on screen, which does not change, and assert answers by value, which does;
(3) the builder and its test with a fully answered fixture and a fixture with `focus`
empty.

`util_test.dart` mentions option labels; if an assertion there reads an answer value,
it moves to keys — otherwise leave that file alone.

## Acceptance Criteria (DoD)

- [x] `onboarding_options.dart` and `plan_request.dart` import no `package:flutter`.
- [x] A test asserts every options list has unique keys, unique labels, and that the
      labels equal the prototype strings listed in contract 1.
- [x] `plan_request_test.dart`: a fully answered `OnboardingAnswers` builds the exact map
      in `docs/PHASE-3-CONTRACT.md` §2 (deep-equal against a literal), no label string
      from contract 1 appears anywhere in `jsonEncode(result)`, `focus` empty throws
      `StateError`, `newRequestId()` matches `^[0-9a-f]{32}$` and two calls differ.
- [x] Onboarding widget tests: picking `Couple` stores `couple`; picking `Nature` and
      `Adventure` stores `['nature', 'adventure']`; going back and forward re-shows the
      picked labels as selected.
- [x] `grep -rn "'Couple'\|'Campervan'\|'Mid-range'" lib --include=*.dart` matches only
      `onboarding_options.dart`.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
