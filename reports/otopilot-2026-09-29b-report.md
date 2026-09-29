# Otopilot report — 2026-09-29 (b), polish pass (D18)

Plan: `reports/otopilot-2026-09-29b-plan.md`. BASE_SHA `b797afe`. One wave, ultracode engine,
Workflow `wf_f4450ebb-f41` (15 agents, 0 errors, 103.5 min, ~2.08M subagent tokens).

| Task | Outcome | Attempts | Gate on main | Main SHA |
|---|---|---|---|---|
| 48 Road progress, car sprite | green (finished by the orchestrator) | 1 | analyze clean, 573 passed | `4d081ac` |
| 49 Loading on the live map | green, 1 fix round | 1 | analyze clean, 573 passed | `2ea3ceb` |
| 50 Entrances, press, transitions | green | 1 | analyze clean, 573 passed | `40cb37d` |
| 51 Auth first impression | green | 1 | analyze clean, 573 passed | `46ff592` |
| Integration | sizes into `metrics.dart` (`loadingBrandBadgeSize`, `authBrandMarkSize`), 13 unused tokens deleted, one stale `15/15` assertion | — | analyze clean, 573 passed | `aa03997` |
| V27 (main loop) | onboarding answers as plain label rows | — | analyze clean, 573 passed | `72154ed` |

## What went wrong in the run

- **Task-48 ran twice at once.** The builder asked (via message) for a one-line edit outside its
  OWNS; the orchestrator's reply resumed the agent as a second copy while the original kept
  going, and the two saw each other's writes in the same worktree. The orchestrator told the
  copy to stop, both stopped, and the orchestrator finished the lane from the files on disk
  (header, tests, dead metrics). Lesson: answer a running workflow agent's question at
  integration, not by messaging it — a reply resumes a copy.
- Builders also used the emulator (allowed in their brief) while screen lenses held the lock,
  so one lens saw another lane's build for a moment (Task-51 screen lens, score 72).

## Review panel

- Task-49: screen lens 85 — the route's northern end sat under the status bar; fixed (the map
  keeps the top inset), new widget test, second round clean.
- Left under 80: Stop detail push shows a tab-chrome jump (50, 65); the Login footer links sit
  on the busiest part of the backdrop (51, 60); the brand mark's pin carries a soft halo from
  the icon artwork, arguably a glow (51, 62).

## Evidence

`reports/screens/2026-09-29-final/`: Plan AI empty, onboarding step 1 and 5 with the road and
`Step N of 15`, Loading at 1 s and 5 s on the live map with the badge and the sprite, Result
of a live Full NT generation (server 40.3 s, 7 stops kept), Saved Routes, Explore card. Lane
screen reviews: `reports/screens/2026-09-29-polish/`.

Run closed: tasks consumed
