# Otopilot report — 2026-09-22 night (Terra NT)

Plan: `reports/otopilot-2026-09-22-plan.md`. Direction: Claude main loop (`fable`), Claude bees.
SOURCE tasks (26…33), UNTIL 2026-09-23T07:00. BASE_SHA `60b97ec`. Baseline gate green: analyze clean, 365 tests.

## Checkpoints

### Wave 1 — started 00:01 (Task-26, opus, 45 min timebox)

| Task | Result | Attempts | Elapsed | Gate | Commit |
|---|---|---|---|---|---|
| 26 | green | 1 | 00:01→00:07 bee, 00:11 integrated | worktree: analyze clean, 378 tests; main: same | `e8012a7` |

Notes: the bee touched two test files outside OWNS (`test/core/util/util_test.dart`,
`test/features/auth/create_account_screen_test.dart`) because `SavedRoute.stops` is
required and the seam grew; mechanical, accepted at integration and recorded here.
Quota after wave 1 (00:12): Claude 5-hour 60% (52% before → 8 points, resets 01:20), weekly 52%.
Measured wave time: 10 min (estimate was 60).

### Wave 2 — started 00:12 (Task-27 opus, 28/29/30/31 sonnet; base `e8012a7`, 45 min timebox → 00:58)
