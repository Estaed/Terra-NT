# Task-35 — Account reads verification through the seam; tests override the seam instead of the screen swallowing errors

**Status: DONE** — verified 2026-09-23 01:14 (otopilot goal run: lane gate 63 tests, integrated gate green on main, 462 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* Mechanical test-harness fix plus narrowing one catch; judged by the suite.
> Same lesson as Task-24's `load()` try/catch, reverted for the same reason.

**Lane**
- OWNS: `terra_nt/lib/features/profile/account/account_screen.dart`, `terra_nt/test/app/tab_shell_test.dart`, `terra_nt/test/integration/itinerary_profile_test.dart`, `terra_nt/test/features/profile/account/`
- MUST NOT TOUCH: `terra_nt/lib/data/` (the seam is fixed), `terra_nt/lib/features/loading/` and `terra_nt/test/integration/auth_onboarding_test.dart` (Task-34), `terra_nt/lib/core/theme/`, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/app/ test/integration/itinerary_profile_test.dart test/features/profile/`
- DEPENDS ON: Task-28

## Objective

Task-28 wrapped Account's `isEmailVerified()` read in `catch (_) { return; }` because two
tests reach Account without overriding `authRepositoryProvider`, so the real provider
constructs `FirebaseAuth.instance` and throws `[core/no-app]`. Swallowing every exception
there would also hide a misconfigured production build. The seam's own contract already
says `isEmailVerified` never throws for a network miss, so the screen needs no catch-all.

## The contracts — fixed, not guidance

1. `tab_shell_test.dart` and `itinerary_profile_test.dart` override
   `authRepositoryProvider` with `InMemoryAuthRepository` (the same pattern
   `boot_test.dart` uses since Task-24) wherever the app or Account is pumped.
2. `account_screen.dart`: the `try`/`catch (_)` around the `isEmailVerified()` read is
   removed; if a catch is kept at all it is `on AuthException`, leaving the value line
   empty. The resend path's `on AuthException` handling is unchanged.
3. A test asserts Account shows `Not verified` from an in-memory seam with
   `emailVerified = false`, and `Verified` with `true` (existing tests may already cover
   this — keep them green, do not duplicate).

## Acceptance Criteria (DoD)

- [x] `grep -n "catch (_)" lib/features/profile/account/account_screen.dart` returns nothing.
- [x] `grep -n "authRepositoryProvider.overrideWith" test/app/tab_shell_test.dart test/integration/itinerary_profile_test.dart` matches in both files.
- [x] Removing the override in either file makes that file fail (checked once by the bee, reported in NOTES).
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
