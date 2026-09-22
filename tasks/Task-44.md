# Task-44 — Account's verification row says "Checking…" while it loads
**Status: DONE** — verified 2026-09-23 02:21 (otopilot goal run: lane gate 28 tests, integrated gate green on main, 511 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* One placeholder string in one row, judged by a widget test. Audit improvement
> under `docs/PRD.md` D15.

**Lane**
- OWNS: `terra_nt/lib/features/profile/account/account_screen.dart`, `terra_nt/test/features/profile/account/`
- MUST NOT TOUCH: `terra_nt/lib/data/`, `terra_nt/lib/features/loading/` (Task-43), every file Task-42 owns, `terra_nt/lib/core/theme/`, `terra_nt/pubspec.yaml`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/profile/`
- DEPENDS ON: Task-35

## Objective

`docs/PRD.md` §3.10 (phase 2) leaves the value line empty until `isEmailVerified()`
resolves, which a user cannot tell apart from "nothing came back". A muted placeholder
removes the ambiguity; no spinner (none is designed).

## The contract — fixed

- While the read is pending the value line reads `Checking…` (with the single ellipsis
  character U+2026) in the same style the row uses for its value, `AppColors.inkTertiary`
  if the row has a muted variant, otherwise the value's own colour.
- It becomes `Verified` / `Not verified` when the read returns. If the read throws
  `AuthException`, the line becomes empty (today's behaviour) — not `Checking…` forever.
- `docs/PRD.md` §3.10 gets a dated line from the orchestrator at integration.

## Acceptance Criteria (DoD)

- [x] Widget test with a seam whose `isEmailVerified()` returns a `Completer` future: `Checking…` shows before completion, `Not verified` after `complete(false)`.
- [x] With a seam that throws `AuthException(network)`, the line is empty after the throw.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
