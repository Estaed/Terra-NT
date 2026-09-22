# Otopilot plan — 2026-09-23 goal run (Terra NT)

| | |
|---|---|
| SOURCE | `goal` |
| GOAL | The app is better by morning: defects found by audit, device tour and eye are fixed; gaps the operator would notice are closed; every change is one revertible commit |
| GOAL GATE | `PYTHONUTF8=1 python tools/goal_gate.py` (prints open-item count; 5 at plan time) **plus rubric**: the findings ledger `reports/otopilot-2026-09-23-findings.md` (open `- [ ]` lines). The gate file is frozen for the run and `MUST NOT TOUCH` for every lane |
| UNTIL | `2026-09-23T07:00` (local, AUSCST), resolved at 01:03 |
| MAX WAVES | 6 |
| FENCE | `terra_nt/lib/`, `terra_nt/test/`, `terra_nt/assets/`, `terra_nt/android/app/src/main/res/` (launcher icon), the `flutter: assets:` block of `terra_nt/pubspec.yaml` only (no dependency edits), `docs/PRD.md` §6–§8 rows written by the orchestrator only, `tasks/`, `docs/TASKS_INDEX.md`. Out: `CLAUDE.md`, `tools/goal_gate.py`, dependencies, `android/` Gradle files, Firebase config |
| Direction | Claude main loop orchestrates (`fable`, this session), **Claude bees** for code (`sonnet` default, `opus` for tangled lanes). **Codex only for image generation** (`gpt-image-2` via `codex-swarm`), run by the orchestrator at a wave boundary after Codex's 5-hour reset at 02:01 — not a code lane, no mixed wave |
| Operator authority (2026-09-23 ~01:00, recorded as `docs/PRD.md` D15) | Visual: prototype differences are bugs, fixed freely; improvements beyond the prototype are allowed, each recorded as a V-row in §7 with before/after emulator captures in `reports/shots/`, one commit each. Features: free; each one leaves §8 as a dated decision row. Images: `gpt-image-2` once Codex resets. Anything else: "treat as if I chose the recommended option" |
| Quota ceiling (operator: "limitine dikkat et") | Claude weekly must stay ≤ 70% (55% at plan time, resets 27 Sep); 5-hour walls per the skill (wait for reset 06:20 if hit before then). Codex: image jobs only while its 5-hour < 80% after reset |
| Timebox | 40 min per bee, 25 min second attempt; `--wave-minutes 45` |
| BASE_SHA | HEAD after this plan's commit |

## Wave 1 (written at plan time)

| Task | Tier | OWNS (short) | GATE |
|---|---|---|---|
| 34 Loading keeps 7000 ms on success; retry tested | sonnet | `features/loading/`, its tests, `test/integration/auth_onboarding_test.dart` | loading + that integration file |
| 35 Account catch narrowed; tests override the seam | sonnet | `account_screen.dart`, `test/app/tab_shell_test.dart`, `test/integration/itinerary_profile_test.dart`, account tests | app + that integration file + profile tests |
| Audit (read-only bee, no task id) | sonnet | writes only `reports/otopilot-2026-09-23-audit.md` | none — its output is input to the ledger, judged by the orchestrator |

In parallel the orchestrator boots the `terra_nt` emulator, installs a debug build with
the stub (`PLAN_API_URL=http://10.0.2.2:8787`) and walks every screen, saving captures to
`reports/shots/` and findings to the ledger. Waves 2–6 are written from the ledger with
`generate-tasks` rules (Lane block, OWNS inside FENCE, ids from Task-36).

## Stop conditions

`UNTIL`; weekly Claude > 70%; `MAX WAVES`; goal number and ledger both unmoved across two
waves; nothing left inside the fence. The report's last line is `Run closed: <reason>`.
