# Task-36 — Phase-2 launch routing: nobody signed in lands on Login

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* One routing rule in one widget, judged by `app_launch_test.dart`. Found on the
> emulator tour (`reports/shots/tour-01-launch.png`); authorised under `docs/PRD.md` D15.

**Lane**
- OWNS: `terra_nt/lib/app/app_launch.dart`, `terra_nt/test/app/app_launch_test.dart`, `terra_nt/test/app/boot_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/data/`, `terra_nt/lib/features/` (Task-34 owns `features/loading/`), `terra_nt/lib/shared/` (Task-37), `terra_nt/lib/core/theme/`, `terra_nt/test/app/tab_shell_test.dart`, `terra_nt/test/integration/`, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/app/`
- DEPENDS ON: Task-35

## Objective

`docs/PRD.md` Q2 (2026-09-05) routes cold start on `onboardingDone` alone: false →
onboarding, true → Explore. That was right while auth was a mock. With real accounts a
fresh install now skips Login, plans with no `uid`, never syncs to Firestore, and Profile
shows the placeholder email with a "Log Out" row for nobody. The rule gains the auth
seam's answer, which is offline-safe (`currentEmail()` never touches the network).

## The contract — fixed

| `session.email` after `load()` | `onboardingDone` | Cold start lands on |
|---|---|---|
| null | any | **Login** — the same `LoginScreen` route and stack Profile's Log Out already lands on (reuse it; do not build a new stack) |
| non-null | false | onboarding (unchanged) |
| non-null | true | the tab shell, Explore (unchanged) |

`docs/PRD.md` Q2 gets a dated line from the orchestrator at integration, not from the bee.

## Acceptance Criteria (DoD)

- [ ] `app_launch_test.dart`: the three rows above, each seeded through
      `InMemoryAuthRepository` + the onboarding flag, each asserting the landing screen by
      a key or type that already exists.
- [ ] System Back on Login at cold start does not pop to a blank screen (existing
      `PopScope`/navigator behaviour; assert the app stays on Login).
- [ ] `boot_test.dart` still passes (it overrides the seam).
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
