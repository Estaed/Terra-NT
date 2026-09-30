# Task-69: The offline note leaves the route visible, and times stay whole at large text
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator asked on 2026-10-01 to fix the two eye notes and named Codex; both are layout fixes with widget tests, judged by eye.

**Lane**
- OWNS: `terra_nt/lib/shared/map/terra_map.dart`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart`, `terra_nt/test/shared/map/terra_map_test.dart`, `terra_nt/test/features/itinerary/stop_detail/stop_detail_screen_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/core/util/saved_routes_ops.dart` (Task-68), `terra_nt/lib/data/` (Task-68), `terra_nt/lib/shared/map/tile_cache.dart`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**Two eye notes from the 2026-10-01 wave are gone.**

- **The offline-area note hides the route.** On Result with no signal, Task-64's note ("This map
  area is unavailable…") is a wide three-line box across the top of the map and covers route pins
  1 and 3 (`reports/screens/2026-10-01-waveA/t64-offline-area-note.png`).
  - It stays honest and present, but it no longer covers the route's pins or line at the default
    and top sheet heights, for example as a compact one-line note the user can expand or dismiss.
  - Explore, which has no route, may keep a fuller version.
- **Times break at large text.** In Stop detail's schedule at 2x system text, the time column is
  too narrow and times break mid-token ("11:0 / 0am"; `reports/screens/2026-10-01-waveB/t66-2x-pair.png`).
  - A time never breaks inside itself. At large text the column grows or the row stacks time
    above activity.
  - The Hours and entry-fee rows keep their current layout.

## Why

Both were found on the emulator during the audit wave and listed for the operator. A note that
hides the route defeats the screen it explains, and a split time is unreadable.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Widget test: with failing tiles and a route, no pin's hit area intersects the note at the default sheet height on a 360 × 780 and a 412 × 915 viewport; the note is still shown and its full text is reachable.
- [ ] Widget test: at text scale 2.0 on a 360 px viewport, each schedule time renders on one line (no line break inside "11:00am"), and nothing overflows.
- [ ] Device check (main loop, `emulator-5554`): Result in airplane mode over an uncached area shows every pin. Stop detail at `font_scale 2.0` shows whole times. Logcat has no Flutter exception.
- [ ] (eye) Compare against the two captures named above: the note reads as quiet information and the schedule reads cleanly at 2x.

## Out of scope

- Other offline behaviour (Task-64 done). Other large-text screens.
