# Otopilot report — 2026-09-29, demo readiness (D17)

Plan: `reports/otopilot-2026-09-29-plan.md`. BASE_SHA `80f5e4b`. One wave, ultracode engine,
Workflow `wf_94d42a95-554` (7 agents, 0 errors, 23.7 min, ~647k subagent tokens).

| Task | Outcome | Attempts | Gate (lane → main) | Main SHA |
|---|---|---|---|---|
| 45 Planning server | green | 1 | `unittest` 23 OK (exit 0) → 23 OK (exit 0) | `3feb61b` |
| 46 Seven places, tag pictures | green, eye check pending: 1 | 1 | `flutter analyze && flutter test` exit 0 → analyze clean, 541 passed | `0727d05` |
| 47 iOS config, dark launch | green (main loop, before BASE_SHA) | 1 | baseline gate 526 passed | `18cd9e1` |

## Evidence beyond the gates

- Task-45 live, `--backend codex --no-auth`, curl with the §2 example (Top End, Darwin →
  Katherine): `HTTP 200 in 38.1 s`, 6 stops kept, 0 dropped.
- End-to-end on the emulator (`reports/screens/2026-09-29-tour/`), server with auth on,
  `PLAN_API_URL=http://10.0.2.2:8787`: all 15 onboarding steps → Loading → Result
  "Red Centre in 7 days: Alice Springs to Uluru", 5 stops; server log
  `status=200 seconds=34.1 stops kept=5 dropped=0`; 45 s from tap to Result. Stop detail for
  Ormiston Gorge shows the new illustration and the model's plan.
- Task-47: the first three frames after a cold start sample `#010102` (was white).

## Review panel

No finding reached 80, so no fix round ran. Recorded, not fixed (scores in brackets):

- (68, code, 45) A Nominatim outage makes stops unresolved → `422 cannot_plan` instead of a
  retryable 5xx. With only 2 place documents most names go to Nominatim; the disk cache
  softens it. The teammates' RAG documents remove most of the dependency.
- (55, screen, 46) At the fit zoom the new pins overlap existing ones (Wildlife Park over
  Mindil and Darwin Waterfront, Edith Falls over Nitmiluk, Standley Chasm over Desert Park,
  Kata Tjuta over Uluru); every card is still reachable, zooming separates them. Draw
  order or fit changes are the operator's call.
- (55, code, 46) The three call sites that pass `tags:` have no widget test.
- (55, code, 45) A rejected token is logged without the reason.
- (45, spec/code, 45) Worst case, 50 s model + uncached geocoding can pass the app's 60 s
  timeout; the retry reuses the same `requestId` and gets the cached answer.
- (30, spec, 45) `docs/PHASE-3-CONTRACT.md` line 11 still said the server is a teammate's;
  fixed by the orchestrator at closeout.

## Awaiting eye check

- Task-46: Stop detail for a stop whose name is not a known place shows its tag's picture.
  Reach it by generating a route whose stops include an unlisted town (e.g. Glen Helen).

Run closed: tasks consumed
