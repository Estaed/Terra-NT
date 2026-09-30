# otopilot report — 2026-10-01, audit wave

Plan: `reports/otopilot-2026-10-01-plan.md`. BASE_SHA `69bc519`. Codex `gpt-6.1-sol`/`high`
bees. Wake lock PID 14992. Every bee again reported `COMMIT: NONE` (sandbox cannot write the
worktree `index.lock`); the orchestrator committed each lane after checking the diff stayed
inside OWNS.

## Wave A — Task-64, Task-65 (parallel)

| Task | Outcome | Attempts | Lane gate | Main gate | Main SHA |
|---|---|---:|---|---|---|
| 64 | **green, eye check pending: 1** | 1 | exit 0 (882 tests) | exit 0, analyzer clean, 882 tests | `2ebf862` |
| 65 | **green, eye check pending: 1** | 1 | exit 0 (884 tests) | exit 0, analyzer clean, 902 tests | `b4a9758` |

- **Task-64 review of the save path** (the data-loss path, read by the orchestrator):
  - Saving returns after the local write, and the Firestore push runs in the background. The
    push reads the cache before writing, then reconciles against the server.
  - `clearRemote` waits for pending pushes, so delete-account still knows the remote was cleared.
  - Delete-account with no signal still waits for the network, as it did before this task. This
    is not a regression; it is recorded here as a known limit.
- **Task-64 device check** (`reports/screens/2026-10-01-waveA/`, signed in, airplane mode):
  - Onboarding, Darwin → Katherine, "Use an offline route": Result was on screen 0.66 s after
    the tap (`t64-offline-route-frames.png`), and the route is in Saved.
  - The offline-area note shows over uncached tiles (`t64-offline-area-note.png`).
  - Cloud catch-up is **not verified** (no Firestore console access).
  - *Eye note:* the note box sits over the top of the map and hides route pins 1 and 3.
  - Logcat: only `I flutter` tile lookup failures (expected offline; they print the CARTO key in
    the URL), no exception.
- **Task-65 device tour:**
  - Swipe-to-delete shows "Route deleted / Undo", and Undo put the offline route back at its
    position (`t65-undo-pair.png`).
  - Move up moved Full NT to the top.
  - Rename changed the title and kept the cover (`t65-renamed.png`); the name was then restored.
  - A first Undo attempt came after the message had gone (the UI dump is slow), so the demo
    route "7 Days in the Red Centre" is now deleted on the emulator.
