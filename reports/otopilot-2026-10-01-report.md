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

## Wave B — Task-67, Task-66

| Task | Outcome | Attempts | Lane gate | Main gate | Main SHA |
|---|---|---:|---|---|---|
| 67 | **green, eye check pending: 1** | 1 | exit 0 (881 tests) | exit 0, analyzer clean, 919 tests | `7356bcf` |
| 66 | **green, eye check pending: 1** | 1 | exit 0 (919 tests) | exit 0, analyzer clean, 936 tests | `498320d` |

- **Task-67 screen check** (`reports/screens/2026-10-01-waveB/t67-steps.png`): focus, vehicle and
  stay options carry quiet Lucide icons, and the text-only questions stay text-only. With
  Campervan chosen the step count reads 14 (Task-61's skip still works). The failure-state icons
  and Loading's single progress cue are covered by widget tests; they were not seen on the device.
- **Task-66** reported `BLOCKED` for one item outside its OWNS: the Saved screen's delete had no
  screen-reader name. Its own work was complete and gated green. The orchestrator closed that
  item in the main loop (`8248060`): Delete in the route menu (a path with no swipe) and a named
  delete button, with two widget tests. Gate exit 0, 938 tests.
- **Task-66 drive figures** now match Tourism NT (updated 2025-01-08): Kakadu–Katherine 305 km,
  Katherine–Alice Springs 1,191 km (about 12h), Alice–Kings Canyon 473 km, Kings Canyon–Uluru 302 km.
  The Nitmiluk note now warns about the 12-hour drive.
- **Task-66 device tour:** see the note under its device-tour criterion. TalkBack itself was not
  run, and the labels were read from the accessibility tree.

## Needs the operator

- **Saved copies keep old facts.** A route saved before Task-66 carries its own stops (D13), so
  the emulator's and the phone's "Full NT" still say 670 km / 300 km. The choices: migrate the two
  seeded routes' drive strings on load, or leave saved data untouched. This is a data decision.
- **Eye notes:**
  - 64: the offline-area note hides pins 1 and 3 at the top of the map.
  - 66: at 2x text, Stop detail's time column wraps ("11:0 / 0am").
- **Known limit:** delete-account with no signal waits for the network, as it did before this wave.
- **Emulator state:** the demo route "7 Days in the Red Centre" was deleted during the Task-65 tour.

## Closeout

All four approved tasks are green on main and each waits for one eye check. Captures are in
`reports/screens/2026-10-01-wave{A,B}/`.

Run closed: tasks consumed
