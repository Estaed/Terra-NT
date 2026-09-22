# Task-38 — Audit bugs: the auth wrapper's null user, empty stop names; notifier coverage
**Status: DONE** — verified 2026-09-23 01:55 (otopilot goal run: lane gate 99 tests, integrated gate green on main, 482 tests; lib/data coverage 98.1%)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* Two one-line fixes with fixture tests, plus tests for notifier branches the
> goal gate's `lib/data` floor (97%) still misses. Source: `reports/otopilot-2026-09-23-audit.md`.

**Lane**
- OWNS: `terra_nt/lib/data/repositories/firebase_auth_repository.dart`, `terra_nt/lib/core/util/plan_response.dart`, `terra_nt/test/core/util/plan_response_test.dart`, `terra_nt/test/fixtures/plan/` (one new file), `terra_nt/test/data/repositories/`
- MUST NOT TOUCH: `terra_nt/lib/core/util/stop_json.dart` (storage shares it; the empty-name rule is the wire parser's), `terra_nt/lib/core/util/itinerary_ops.dart` (Task-39), `terra_nt/lib/data/repositories/notifiers.dart` (read it, test it, do not change it), `terra_nt/lib/features/`, `terra_nt/lib/shared/`, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/core/util/plan_response_test.dart test/data/`
- DEPENDS ON: Task-36

## The contracts — fixed

1. **Null current user.** In `FirebaseAuthRepository`, every `_auth.currentUser!` becomes
   a local null check that throws `const AuthException(AuthFailure.unknown)` when the user
   is null (`deleteAccount`, `sendEmailVerification`, and any other `!` on `currentUser`
   in the file). The seam's doc says nothing but `AuthException` escapes it. Untested by
   unit (Blueprint, Stack note); the grep criterion below is the check.
2. **Empty stop name.** `parsePlanResponse` drops a stop whose `name` is empty or only
   whitespace (`docs/PHASE-3-CONTRACT.md` §3.3: "missing or empty → stop dropped"). New
   fixture `stop_empty_name.json`: four good stops and one with `"name": "  "`; parses to 4.
3. **Notifier coverage.** Add tests in `test/data/repositories/` for the uncovered
   branches of `notifiers.dart` (run `flutter test --coverage` and read `coverage/lcov.info`
   for `lib/data/repositories/notifiers.dart` to find them) until
   `lib/data/` excluding `firebase_auth_repository.dart` and `firestore_saved_routes.dart`
   is ≥ 97% line coverage. Tests assert behaviour, not just execution: each new test has
   at least one `expect` on state.

## Acceptance Criteria (DoD)

- [x] `grep -n "currentUser!" lib/data/repositories/firebase_auth_repository.dart` returns nothing.
- [x] `plan_response_test.dart` has a test for `stop_empty_name.json` asserting 4 stops.
- [x] `lib/data` coverage (Firebase wrappers excluded) ≥ 97%, figure reported in NOTES from `lcov.info`.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
