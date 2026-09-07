# Otopilot wave plan — 2026-09-07

**Status: awaiting operator approval.** No bee is spawned until this file is approved.
After approval the run is unattended and cannot expand its own selection or ownership.

## Direction

| | |
|---|---|
| Orchestrator | **Claude** (this session) — holds the wake lock, runs `GATE`, cherry-picks, writes the report |
| Bees | **`codex exec`**, one at a time |
| Preflight flag | `--delegate codex` |
| `BASE_SHA` | `0706260e78059d613a7817184920bc3c960b77db` |
| Baseline gate | `cd terra_nt && flutter analyze && flutter test` → **clean, 66 tests pass** |
| Stop markers | zero in both selected tasks |
| `BACKLOG.md` | no entries — neither task is a repeat |

The direction does not flip mid-run. If Codex quota runs out, in-flight bees finish, get
gated and integrated, and the report recommends the next run's direction.

## Quota snapshot — taken 2026-09-07

| Pool | 5-hour | 7-day | Verdict |
|---|---|---|---|
| Codex (plan: plus) | 18% | **94%** — resets in ~4d 14h | **NARROW** |
| Claude | 17% | 13% | healthy |

**NARROW is why this plan has no parallelism.** Two sequential waves, one bee each. The
tasks are serial anyway — Task-05 depends on Task-04 — so nothing is lost.

**Model tier: `gpt-5.6-luna`**, operator-chosen 2026-09-07 to stretch the 6% of weekly
headroom across both tasks. Not `gpt-5.6-terra`, and `gpt-6-astra` never runs unattended.
Reasoning effort stays `high`, as both `Execution` blocks specify.

**The Phase 2 quota gate runs before each wave**, not just the first. At >97% on Codex's
fullest window the run spawns nothing further, integrates what exists, and reports
`quota-stopped`. Task-05 is the likely casualty; that is an accepted outcome, not a failure.

## Waves

| Task | Wave | Agent | Model / effort | OWNS | GATE | Timebox | Attempts |
|---|---:|---|---|---|---|---|---:|
| Task-04 — Pure logic utilities | 1 | `codex` | `gpt-5.6-luna` / `high` | `terra_nt/lib/core/util/`, `terra_nt/test/core/util/` | `cd terra_nt && flutter analyze && flutter test test/core/util/` | 45 min | 1–2 |
| Task-05 — Repositories and the two seams | 2 | `codex` | `gpt-5.6-luna` / `high` | `terra_nt/lib/data/repositories/`, `terra_nt/test/data/repositories/` | `cd terra_nt && flutter analyze && flutter test test/data/` | 45 min | 1–2 |

`OWNS` sets are pairwise disjoint. Wave 2 does not start until Wave 1 is integrated green
on `main`, because Task-05 `DEPENDS ON` Task-04.

**Neither task requires `review-visual`.** Both are Part 2 tier 1 / tier 2 — no screen.

### Risk notes carried into the bee briefs

- **Task-04** is the largest pure-logic surface in the project: seven files, and its DoD
  names exact edge values (`nearestSnap` ties at 310 and 565 resolving *down*;
  `isOpenAfterRelease(-38) == false` but `(-39) == true`; `progressPercent(0) == 7`; the
  two different denominators, 15 and 14). The arc-length sampler is the one place a cheap
  tier is most likely to cut a chord instead of walking the polyline — its DoD has a
  specific test for exactly that, so the gate should catch it.
- **Task-04** carries deviations V2, V3, V4, V8 and V9. The brief includes the V-table rows
  verbatim so the bee does not "fix" them back to the prototype's behaviour.
- **`tag_colors.dart` is the single file in `core/util/` permitted to import
  `core/theme/`.** Everything else there importing Flutter is a gate failure.
- **Task-05** fixes the `shared_preferences` key names and encoding, which Part 2 records
  as *not yet decided*. Part 2 says the task that writes them records them there. A bee
  cannot amend Part 2 — so the bee writes the keys, and **the orchestrator transcribes
  them into Part 2 at integration** and flags it for the operator.

## Excluded tasks and why

| Task | Reason |
|---|---|
| Task-00, 01, 02, 03 | DONE |
| Task-06, 10, 13, 14, 16 | routed to the main loop **with Plan mode** — out of reach by construction |
| Task-07, 08, 09, 15, 20 | routed to the main loop |
| Task-11, 12, 17, 18, 19 | routed to `codex`, but every one `DEPENDS ON` Task-06, which is main-loop + Plan mode and not done |

Task-11 additionally requires `review-visual` in the main loop after its gate; when it
eventually runs it reports as *green, review-visual pending*, never plain green.

## What the run does when it finishes

Writes `reports/otopilot-2026-09-07-report.md` with per-task outcome, attempt count,
elapsed time, failure trajectory for anything that went red, and the final main-branch SHA
for anything green. Removes every worktree it created. Appends the outcome to the vault's
`Last-Session.md` and corrects `Threads.md`. Releases the wake lock.
