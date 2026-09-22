# Task-34 — Loading keeps V1's 7000 ms on success; retry is tested end to end

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* Two fixed behaviours in one screen, both judged by widget tests. Written by the
> goal run from a defect the orchestrator found while preparing it.

**Lane**
- OWNS: `terra_nt/lib/features/loading/`, `terra_nt/test/features/loading/`, `terra_nt/test/integration/auth_onboarding_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/core/theme/` (the constant already exists; use it), `terra_nt/lib/data/`, `terra_nt/lib/features/profile/` (Task-35), `terra_nt/test/app/`, `terra_nt/test/integration/itinerary_profile_test.dart` (Task-35), `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/loading/ test/integration/auth_onboarding_test.dart`
- DEPENDS ON: Task-33

## Objective

Task-33 removed Loading's completion timer so it navigates on the response. With the
seeded repository — every checkout without `PLAN_API_URL`, which is the demo build — the
response is immediate, so Loading now flashes and the five messages never show.
`docs/PRD.md` §3.4 says the seeded path behaves "as in phase 1": the V1 transition of
7000 ms. The integration test that asserted it was changed at integration to match the
defect; it goes back.

Also closes the gap Task-33's integration left: "Try again" calls
`RemoteItineraryRepository.retry()` with the same `requestId`, and nothing tests it.

## The contracts — fixed, not guidance

1. **Minimum display time.** A successful response is acted on no earlier than
   `AppMotion.loadingCompletionDelay` (7000 ms) after the attempt started. Implement it
   as `Future.wait([request, Future.delayed(loadingCompletionDelay)])` or an equivalent
   that is cancelled/ignored on Cancel, dispose and a newer attempt — the existing
   `_isCurrent(attempt)` guard covers ignoring. A **failure** is shown as soon as it
   arrives (no minimum), and "Try again" starts a new 7000 ms minimum.
2. **Integration test restored.** `test/integration/auth_onboarding_test.dart` — "background
   and resume during loading write the route once" — asserts `expect(completions, 0)`
   after the 3000 ms pump again, and `1` after the further 4000 ms.
3. **Retry test.** A new test in `test/features/loading/` overrides
   `itineraryRepositoryProvider` with a real `RemoteItineraryRepository` over
   `package:http/testing.dart`'s `MockClient`: first response 500, second response the
   body of `test/fixtures/plan/ok.json`; `idToken: () async => 'test-token'`. Pump Loading,
   see the failure, tap `loading-failure-primary`, pump past 7000 ms, assert both recorded
   request bodies carry the same `requestId` and the screen completed.
4. Existing Loading tests that assert timing are updated to the minimum; no other
   behaviour changes.

## Acceptance Criteria (DoD)

- [ ] With the seeded/fake immediate repository, nothing navigates or saves before 7000 ms and it does at 7000 ms (widget test).
- [ ] A failure from an immediate fake repository renders at once (widget test, no 7000 ms pump before the assertion).
- [ ] The retry test in contract 3 passes and asserts one `requestId` across both requests.
- [ ] `grep -n "expect(completions, 0)" test/integration/auth_onboarding_test.dart` matches after the 3000 ms pump.
- [ ] Timer leak test still passes: disposing during the minimum wait leaves no pending timers.
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
