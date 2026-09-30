# otopilot report — 2026-09-30, motion, illustration and truth

Plan: `reports/otopilot-2026-09-30-plan.md`. BASE_SHA `296db54`. Orchestrator: this
Claude Code session (`claude-opus-5-5`). Code bees: Codex `gpt-6.1-sol`/`high`. Wake lock
PID 14132.

## Preflight

- Second preflight on the clean tree: `OVERALL OK` (`owns_disjoint` OK, quota `GO`, Codex 5-hour window at 81%).
- Baseline gate at `296db54` (`tools/flutter_gate.ps1`): exit 0 in 212 s. Analyzer found no issues, 582 tests passed, release APK built.
- Codex auth: logged in with ChatGPT; the `gpt-6.1-sol` probe returned OK (codex-cli 0.159.2).
- **Image bees:** the Claude Code auto-mode classifier refused a `danger-full-access` image bee even with the operator's OK. They run in the **read-only** sandbox instead; the orchestrator copies each result out of `~/.codex/generated_images`.

## Wave 1 — Task-53, Task-54

Started 14:44 ACST. Both bees ran about 22 minutes and wrote their features, then exited.

**Launcher defect.** Under PowerShell 5.1, `ErrorActionPreference=Stop` turned Codex's first
stderr line into a terminating `NativeCommandError`. The wrapper exited 1 and the bees'
final reports were lost. The working trees held the full change with no commit, which is
most likely a sandbox refusal of `git commit`. The orchestrator committed each lane's
change as one commit:

- `9a5d6b9` Task-53: 9 files.
- `a2be758` Task-54: 7 files, including one old-look assertion outside OWNS in `test/app/tab_shell_test.dart`, where the card's resting inset now accounts for the entrance slide.

The launcher now runs Codex through `cmd.exe`, and the brief says what to do when a
commit is refused.

**Environment defect.** Lanes were created under `%TEMP%` on C:. Analyze and test passed
there (Task-53: 597 tests; Task-54: 594), but the release build failed because Kotlin
reported "this and base files have different roots": the pub cache is on D:. Lanes were
recreated on `D:\terra-lanes`, and the gate was re-run there.

**Quota.** At about 15:20 the Codex 5-hour window hit its wall ("try again at 5:01 PM"),
even though the last `--quota-only` reading showed 85%. Four image bees
(`top_end`, `red_centre`, `full_nt`, `no_signal`) were refused before generating; they
re-run after the reset. `start_trip` was generated before the wall (candidate A kept).

| Task | Outcome | Attempts | Lane gate (D:) | Main gate | Main SHA |
|---|---|---:|---|---|---|
| 53 | **green, eye check pending: 1** | 1 | exit 0, 137 s (597 tests) | exit 0, 94 s | `97e790b` |
| 54 | **green, eye check pending: 1** | 1 | exit 0, 129 s (594 tests) | exit 0, 91 s (609 tests) | `56e91dc` |

Screen check (main loop, `emulator-5554`, captures in `reports/screens/2026-09-30-wave1/`):

- **Task-54:** markers show tag icons, and selecting Karlu Karlu eases the camera in, fills and
  grows the marker, and slides the card up with a Navigate action
  (`task54-select-frames.png`, `task54-card.png`).
  - *Eye notes:* the camera zooms in quite far; the card keeps an empty band under Navigate.
- **Task-53:** opening Full NT from Saved draws the route from Darwin south with pins
  appearing in order (`task53-reveal-frames.png`).
  - *Eye note:* at the top sheet anchor, the refit zooms out to the whole continent to keep
    all 7 pins in a ~230 px strip, so pins stack (only 4 and 7 readable). The criterion
    "all pins visible" is met, but it may read worse than before. For the operator to judge.
- Logcat: no Flutter exception during the tour.

Codex cost of wave 1: two `gpt-6.1-sol`/`high` feature bees of about 22 min each took the
5-hour window from 81% to the wall (about 7–10 points per bee on this plan, plus one image).

## Wait and scene artwork

- Waited for the Codex reset until 17:03 (5-hour window back to 0%, weekly 56%).
- The four remaining scenes were generated in the read-only sandbox and chosen by eye:
  `top_end_b`, `red_centre_a`, `full_nt_a`, `no_signal_a` (candidates in
  `%TEMP%\terra-lanes\scenes\cand`).
- All five were exported as 1536 × 1024 JPEGs (231–443 KB) to `assets/images/scenes/`, and
  `pubspec.yaml` declares the folder (`d781259`).

## Wave 2 — Task-55, Task-56

Started 17:04 with the `cmd.exe` launcher; logs now stream. Both bees reported `COMPLETE`
with `COMMIT: NONE`: the sandbox denies `.git/worktrees/<lane>/index.lock` even with
`--add-dir` on `.git`. The orchestrator committed each lane.

| Task | Outcome | Attempts | Lane gate | Main gate | Main SHA |
|---|---|---:|---|---|---|
| 55 | **green** | 1 | exit 0, 77 s | exit 0, 99 s (617 tests) | `b785351` |
| 56 | integrated, **screen defect found → fix round** | 1 + fix | exit 0, 73 s | exit 0, 102 s (638 tests) | `5a8ffdd` |

- **Task-55 device tour:** Saved → open route → Back lands on Saved Routes. Profile → Back →
  Saved → Back → Explore → Back leaves the app. Logcat has no Flutter exception.
- **Task-56 real-data check** (the data-loss path): the new APK was installed over the old
  stored routes. All three saved routes load intact; the legacy "Generated just now" now
  reads "Your latest plan". Full NT shows 8 days on both Saved and Result. Red Centre's
  stop 1 is fully visible.
- **Task-56 defect** (`task56-pins-displaced.png`): the new `fanOutPins` chain-pushes Full
  NT's pins up to ~230 px off their stops (Litchfield in the sea). Sent back to a Codex fix
  bee (`t56b`, cut from `7b907a8`) with the finding in `D:\terra-lanes\t56-finding.md`.
  Task-56 stays not-DONE until the fix is integrated and seen.
- Wave 3's Task-58 (onboarding, no dependency on 56) started alongside the fix. Task-57
  waits for 56.
