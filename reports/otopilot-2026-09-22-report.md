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

| Task | Result | Attempts | Elapsed | Gate | Commit |
|---|---|---|---|---|---|
| 32 | green | 1 | 00:34→00:42 bee, integrated 00:44 | worktree: 10 tests; main: 443; stub answered 422 to an independent curl | `d4e32f7` |
| 33 | green (bee reported BLOCKED) | 1 | 00:34→00:43 bee, integrated 00:46 | lane gate: 61 tests; main: 462 after two integration edits | `7f590d8` |

Integration edits on Task-33 (main loop, recorded because the bee could not make them):
`test/integration/auth_onboarding_test.dart:718` `expect(completions, 0)` → `1` — the test
asserted the removed 7000 ms timer; the route is still written exactly once. And
`loading_screen.dart`: "Try again" now calls `RemoteItineraryRepository.retry()` (same
`requestId`, contract §1) when that repository is in use — Task-32 landed in parallel, so
the bee could not wire it. **No test covers that wiring yet** (the fake-repository path is
tested); a morning bee should add a Loading test with `MockClient` asserting both requests
carry one `requestId`.

## Phase 4 — closeout

| Task | Outcome | Attempts | Main commit |
|---|---|---|---|
| 26 | green | 1 | `e8012a7` |
| 27 | green — console steps done (API enabled by operator, DB `(default)` created, rules deployed 00:36); emulator tour pending | 1 | `8fbfd59` |
| 28 | green | 1 | `a5a6d30` (+ tick `97a3fa9`) |
| 29 | green; manual crash-to-console check pending | 1 | `3c27d7d` (+ tick `89ba74c`) |
| 30 | green | 1 | `d4dbb33` |
| 31 | green | 1 | `13b7e61` |
| 32 | green; emulator stub tour pending | 1 | `d4e32f7` |
| 33 | green; device tour (Back behaviour) pending | 1 | `7f590d8` |

Baseline 365 tests → 462 on main. Eight bees, eight green first attempts, zero BACKLOG lines.
Total wall clock 00:01 → 00:46. `git push` not done (never asked).

**Awaiting eye check / device:** Task-27 (Firestore doc appears under the uid; second-device
pull; delete-account clears the collection), Task-32 (stub tour: `.env` `PLAN_API_URL=http://10.0.2.2:8787`,
`python tools/plan_stub/server.py --mode ok|cannot_plan|error|slow|rate_limited|invalid|refuse`),
Task-33 (Cancel/Back/Change answers on the emulator, gesture Back during loading), Task-28
(Login link and Account row by eye), Task-29 (Profile row; force a test crash and see it in the console).

**Needs the operator:**
- Task-28's catch-all around the verification-status read: tests reaching Account should
  override `authRepositoryProvider`; then narrow the catch (Task-24's lesson).
- `AppMotion.loadingCompletionDelay` and V1's 7000 ms are now unused — cleanup task (Later list).
- The retry-wiring test above.
- Leftover lane directories `.lanes/task-27`, `-29`, `-32` (locked build files at removal time);
  worktree metadata is pruned. Delete the folders when no Dart process holds them.

Quota at close (00:47): see the last `limit.py` line in the session; the run used one Claude
5-hour window (52% → the reset at 01:20 never became binding).

Run closed: tasks consumed (00:46, before UNTIL 07:00 — SOURCE was `tasks`, nothing beyond Task-33 was approved).
