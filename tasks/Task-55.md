# Task-55: Back goes where the user came from
> **Execution:** agent `codex` · effort `high`
> *Why:* Navigation state is subtle but fully testable; the operator routed this run to Codex.

**Lane**
- OWNS: `terra_nt/lib/app/tab_shell.dart`, `terra_nt/lib/app/routes.dart`, `terra_nt/lib/app/screen_routes.dart`, `terra_nt/test/app/tab_shell_test.dart`, `terra_nt/test/app/app_launch_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/`, `terra_nt/lib/data/` (Task-56), `terra_nt/lib/shared/`, `terra_nt/lib/core/`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

The system Back gesture never throws the user out of the app from the middle of a
journey:

- **Back from a route opened on Saved Routes** returns to Saved Routes. Today it exits
  to the Android launcher; this was seen twice on the emulator on 2026-09-30.
- **Back at the root of a tab other than Explore** returns to the tab the user came from,
  and in the end to Explore.
- **Back at Explore's root** leaves the app, as today.
- **Back inside a tab's own stack** (Stop detail, Account, Language) still pops that stack
  first.
- **Explore's keyboard-closing Back** keeps working.

## Why

`reports/reviews/2026-09-30/report.md` row B1. Leaving the app when the user meant "go
back one screen" is the worst navigation failure a phone app can have.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Widget tests on the shell: Saved → open route → Back lands on Saved Routes; Profile → Back lands on the previous tab; Explore root → Back calls the system pop; Stop detail → Back returns to Result; Explore with the search keyboard open → Back closes the keyboard only.
- [ ] The retained tab stacks and scroll positions are unchanged (existing tests stay green).
- [ ] Device tour (Blueprint Verification 6): the main loop repeats the journeys above on `emulator-5554`; no Flutter exception in logcat.

## Out of scope

- Saved Routes' own screen, Result's content, the onboarding and auth flows (they keep their Back rules).
