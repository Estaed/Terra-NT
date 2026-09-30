# otopilot plan — 2026-10-01, audit wave

Approved by the operator in chat on 2026-10-01 at about 00:30 ACST: "basla, ne yapilmasi
gerekiyorsa" (start, do whatever is needed). It covers the four features proposed from
`reports/research/2026-10-01-qol-audit.md` and `…-visual-audit.md`.

| | |
|---|---|
| Direction | Claude main loop → Codex bees (`--orchestrator claude --delegate codex`); no fallback |
| Orchestrator seat | This interactive Claude Code session (`claude-opus-5-5`) |
| Bees | `gpt-6.1-sol` / `high`, `--sandbox workspace-write`, one worktree each under `D:\terra-lanes` (launcher `%TEMP%\terra-lanes\run_bee.ps1`) |
| SOURCE / UNTIL | `tasks` Task-64…67 / `done` |
| BASE_SHA | `69bc519` |
| Baseline gate | Not re-run: the code at `69bc519` is identical to `db2ae28`, whose main gate passed on 2026-09-30 (exit 0, 864 tests). Only docs, research and task files changed since |
| Timebox | 120 min per bee |
| Eye | Main loop on `emulator-5554`, holding the device lock |

| Task | Wave | OWNS (summary) | Depends on |
|---|---:|---|---|
| 64 Nothing waits for the network | A | preferences store, Firestore push, terra_map, result/stop detail/list, placeholder, maps_url | — |
| 65 Saved routes undo, rename, order | A | saved screen, notifiers, saved_routes_ops | — |
| 66 Road facts and accessibility | B | seed, itinerary_ops, result/stop detail/list, explore, markers, bottom nav | 64 |
| 67 Icons and Loading failures | B | onboarding steps/options, loading, plan_failure_copy | — |

Two bees run in parallel per wave (free RAM 9.5 GB with the emulator up). The orchestrator stops
Gradle daemons with `gradlew --stop` after gates. Preflight: `OVERALL OK`, quota `GO`
(Codex weekly 74%).
