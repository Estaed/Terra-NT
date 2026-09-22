# Task-33 — Loading: cancel, failure and retry; the empty detailed-plan line

> **Execution:** agent `claude` bee · effort `high`
> *Why:* Copy, buttons and transitions are fixed in `docs/PRD.md` §3.4 (D14, V18); the
> criterion is widget tests with a fake repository that throws each `PlanFailure`. No
> new visual language — existing tokens, `AppButton` variants and the Loading layout.
> The device tour (a drag-free screen, but Back behaviour changes) is the main loop's.

**Lane**
- OWNS: `terra_nt/lib/features/loading/`, `terra_nt/lib/features/itinerary/widgets/result_stop_list.dart`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart`, `terra_nt/lib/core/util/plan_failure_copy.dart` (new), `terra_nt/test/features/loading/`, `terra_nt/test/features/itinerary/`, `terra_nt/test/core/util/plan_failure_copy_test.dart` (new)
- MUST NOT TOUCH: `terra_nt/lib/data/` (Task-26, 27, 31, 32), `terra_nt/lib/app/`, `terra_nt/lib/features/onboarding/` (Task-30), `terra_nt/lib/shared/`, `terra_nt/lib/core/theme/`, `terra_nt/pubspec.yaml`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/loading/ test/features/itinerary/ test/core/util/plan_failure_copy_test.dart`
- DEPENDS ON: Task-31 (needs `PlanException`; runs beside Task-32, not after it)

## Objective

Loading stops being a timer and becomes a request with a way out (`docs/PRD.md` §3.4,
phase 3 block; deviation V18). Cancel while in flight, a failure state with the fixed
copy and buttons, retry with the same request, and no saved route left behind by a
failure. And the one Result fallback P5 named: an empty `detailedPlan` shows a line
instead of a blank panel.

## The contracts — fixed, not guidance

### 1. `plan_failure_copy.dart` — tier 1, `lib/core/util/`

```dart
enum PlanFailureAction { tryAgain, changeAnswers, signIn }

class PlanFailureCopy {
  final String title; final String body;
  final PlanFailureAction primary; final bool showBack;
}

PlanFailureCopy copyForFailure(PlanFailure failure);
```

The table is `docs/PRD.md` §3.4 exactly: the five try-again failures →
`Couldn't reach the planner.` / `Check your signal and try again.` / `tryAgain` /
`showBack: true`; `cannotPlan` → `We couldn't plan this trip.` / `Try a different
region, vehicle or trip length.` / `changeAnswers` / no back; `unauthorised` → `Your
session has expired.` / `Sign in again to plan a trip.` / `signIn` / no back;
`cancelled` never reaches the screen (assert it maps to the try-again row anyway). No
`package:flutter` import.

### 2. Loading — in flight

- `_complete` runs at `initState` (no completion timer any more — declared dead,
  deleted with `AppMotion.loadingCompletionDelay`'s use; the constant itself stays in
  `core/theme/` untouched because Task-33 must not touch that folder; report it as
  unused for a later cleanup). The message timer keeps rotating and stops on the last
  message; it is cancelled on completion, failure and dispose.
- The repository call is awaited with a local `_attempt` counter; a result that arrives
  after cancel (`_cancelled == true`) or after a newer attempt is ignored.
- A `Cancel` text button under the progress pill, `key: ValueKey('loading-cancel')`,
  existing text-button style. Tap → `_cancelled = true`, timers cancelled, `Navigator.pop`
  back to onboarding (the caller's `onComplete` contract is unchanged; when Loading was
  pushed as a replacement the route below is onboarding at step 14 — verify with the
  existing navigation tests rather than assuming, and if it is not, push onboarding at
  step 14 explicitly). Nothing is saved.
- Success order is unchanged from Task-26: set itinerary → onboarding flag → upsert →
  navigate.

### 3. Loading — failure

On `PlanException` (and only that type; anything else propagates as today): message
timer cancelled, pulse controller stopped, and the column below the disc shows, from
`copyForFailure`: title (`AppType.titleApp`, `key: ValueKey('loading-failure-title')`),
body (`AppType.body` or the existing status style in `inkSubtle`,
`key: ValueKey('loading-failure-body')`), then the buttons: primary `AppButton` with
the action's label (`Try again` / `Change answers` / `Sign in`, `key:
ValueKey('loading-failure-primary')`) and, when `showBack`, a secondary `Back`
(`key: ValueKey('loading-failure-back')`). The Cancel button is hidden in this state.

- `tryAgain` → back to the in-flight state (pulse resumes, messages restart from the
  first) and `repository.retry()` when the repository is a `RemoteItineraryRepository`,
  else `itineraryFor(answers)` again. Same `requestId` is Task-32's promise; here the
  test asserts the fake's call count.
- `changeAnswers` and `Back` → the Cancel path.
- `signIn` → `ref.read(sessionNotifierProvider.notifier).signOut()` then the app's Login
  route, replacing the stack (reuse the route Profile's Log Out already uses).

### 4. Result — empty detailed plan

In the Detailed segment, a stop whose `detailedPlan` is empty renders one line
`No detailed plan for this stop.` in `AppColors.inkTertiary`, `AppType.caption` or the
list's existing secondary style, `key: ValueKey('detailed-plan-empty-<index>')`, where
the entries would be. Stop detail's schedule section does the same (one key,
`detailed-plan-empty`).

## Execution Guide

Write `plan_failure_copy.dart` and its table test first. Then Loading with a fake
`ItineraryRepository` whose `itineraryFor` returns a `Completer`'s future — that gives
the tests cancel-before-result and result-after-cancel without timers. Then the failure
render per action. Then the two Result changes. `loading_screen_test.dart` currently
pumps 7000 ms and asserts navigation; those assertions move to "navigates when the
future completes".

## Acceptance Criteria (DoD)

- [ ] `plan_failure_copy_test.dart` covers all eight `PlanFailure` values against the
      table in contract 1.
- [ ] Loading widget tests (fake repository, in-memory auth, `ProviderContainer`
      overrides): completes and navigates when the future resolves, with no fixed delay;
      Cancel before the future resolves → no upsert, no onboarding flag, the route
      below is shown, and resolving the future afterwards changes nothing; `network` →
      title/body/`Try again`/`Back` rendered and Cancel absent; `cannotPlan` →
      `Change answers`, no `Back`; `unauthorised` → `Sign in`, tapping it signs the
      in-memory session out; `Try again` calls the repository a second time and the
      in-flight state returns; a failure leaves the saved routes list without
      `generated-trip`.
- [ ] Timer/controller leak test: pumping Loading, failing it, then disposing records
      no pending timers (`tester.binding` has none) and the pulse controller is
      disposed.
- [ ] `result_screen_test.dart`: a stop with an empty `detailedPlan` shows
      `No detailed plan for this stop.` in Detailed and not in Highlights; stop detail
      shows the same line for that stop.
- [ ] No file under `lib/core/theme/` changed; `AppMotion.loadingCompletionDelay` is
      reported unused in the task report.
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
