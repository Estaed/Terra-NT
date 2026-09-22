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

| Task | Result | Attempts | Elapsed | Gate | Commit |
|---|---|---|---|---|---|
| 31 | green | 1 | 00:12→00:22 bee, integrated 00:27 | worktree: 25 tests; main: 403 | `13b7e61` |
| 27 | green | 1 | 00:12→00:24 bee, integrated 00:33 | worktree: 52 tests; main: 415; rules deployed 00:36 | `8fbfd59` |
| 30 | green | 1 | 00:12→00:24 bee, integrated 00:36 | worktree: 62 tests; main: 426 | `d4dbb33` |
| 29 | green | 1 | 00:12→00:27 bee, integrated 00:32 | worktree: 40 tests + debug APK built; main (with 28): 433 | `3c27d7d` + tick `89ba74c` |
| 28 | green | 1 | 00:12→00:30 bee, integrated 00:32 | worktree: 56 tests; main: 433 | `a5a6d30` + tick |

Notes: 27 constructs `FirebaseFirestore.instance` lazily inside the closures (eager form
broke 19 tests outside its lane) — same behaviour once Firebase is up. 28 wrapped the
verification-status read in a catch-all so tests reaching Account without a seam override
do not crash; follow-up for the morning: those tests should override `authRepositoryProvider`
and the catch should narrow (same lesson as Task-24). 29 chose `shield_check` as the row
icon and put the disclosure in the row's subtitle slot. 29 and 28 were gated together on
main (one full run, green) and ticked in two follow-up commits rather than amended.
Worktree dirs `task-27`, `task-29` could not be deleted (locked build files); metadata
pruned, directories removed at closeout.
Measured wave time: 20 min (bees), 40 min to full integration. Quota at 00:32: weekly 50%.

### Wave 3 — started 00:35 (Task-32 sonnet, Task-33 opus; 45 min timebox)
