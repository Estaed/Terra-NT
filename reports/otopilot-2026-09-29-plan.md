# Otopilot plan — 2026-09-29, demo readiness (D17)

Approved by the operator in chat, 2026-09-29 ("YÜRÜ YOK ET ONLARI"), after the wave list was
laid out; images by Codex `gpt-image-2` (operator: "görselleri codexle üret").

| | |
|---|---|
| Direction | Claude main loop → ultracode engine (Workflow agents, Claude). No fallback row. |
| Seats | Plan and orchestration: this session (`opus`, operator present) |
| SOURCE / UNTIL | `tasks` (45, 46) / `done` |
| BASE_SHA | `80f5e4b0799b515fc5cad731a64282ea3bbcac00` |
| Preflight | `onkontrol.py --tasks 45,46 --orchestrator claude --delegate claude` → OVERALL OK |
| Quota at plan | Claude 5-hour 2 %, 7-day 28 %; Codex 7-day 38 % (images + probes on Codex) |
| Baseline gate | `cd terra_nt && flutter analyze && flutter test` at BASE_SHA — result appended below |
| Wake lock | not taken: operator present, interactive session |

## Wave 1

| Task | Engine | Builder | Reviewers | OWNS (summary) | GATE |
|---|---|---|---|---|---|
| 45 Planning server | ultracode | `opus`/`xhigh` | spec, code (`opus`/`high`) | `tools/plan_server/`, contract §3.2/§7, `.gitignore` | `python -m unittest discover -s tools/plan_server -p "test_*.py" -v` |
| 46 Seven places, tag pictures | ultracode | `opus`/`xhigh` | screen (emulator), spec, code (`opus`/`high`) | seed POIs, `place_images.dart`, three call sites, its test | `cd terra_nt && flutter analyze && flutter test` |

Worktrees: `D:/Dev/wt/terra-45`, `D:/Dev/wt/terra-46` (detached at BASE_SHA). Fix loop: at most
3 rounds per feature, findings kept at score ≥ 80. Integration: cherry-pick, same GATE on main.
Estimated attempts: 1 each. Excluded: none.

Main loop, outside the wave: Task-47 (done before BASE_SHA), the teammates' RAG brief
(`docs/RAG-DATA-BRIEF.md`), the live `codex` generation check for Task-45, the closing
emulator tour against the real server.

## Baseline gate at BASE_SHA

`flutter analyze`: No issues found. `flutter test`: 526 passed, 0 failed (exit 0).
