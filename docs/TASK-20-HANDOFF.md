# Task-20 handoff — 2026-09-10

Written when the Claude main loop's 5-hour window reached 88% with the device journey
still ahead. Task-20 is **not** DONE and no checkbox has been ticked. This file is the
state of the run, not a second source of truth: `tasks/Task-20.md` is the spec and
`docs/TASKS_INDEX.md` is the tracker.

Read `tasks/Task-20.md` first. Everything below assumes it.

## Where the tree is

`8776760` on `main`, working tree clean.

| Check | Result |
|---|---|
| `cd terra_nt && flutter analyze` | zero errors, zero warnings |
| `cd terra_nt && flutter test` | 283 passed |
| `cd terra_nt && flutter build apk --debug --dart-define-from-file=.env` | exit 0 |

The suite was 223 tests before this run. The 60 new ones are three integration files plus
additions to the map tests.

## What changed before Task-20 started

Tasks 14 and 16 had been implemented but never committed. They are now in `52fd901` and
`15655e0`, with the token-extraction pass in `682a169`.

**The tile source changed and it is recorded in `CLAUDE.md` Part 2.** CARTO began
watermarking unauthenticated raster tiles in late August 2026 and the endpoint this app
uses returned a tile stamped "API KEY REQUIRED". The project stays on CARTO with a free
key rather than moving to Stadia Maps, because the prototype's cartography is the design
source of truth and because CARTO still serves a usable tile without a key while Stadia
returns 401. The key lives in the gitignored `terra_nt/.env`, reaches the build through
`--dart-define-from-file=.env`, and is verified working on device. `.env.example` is the
committed template. No package was added.

## Task-20 work that is complete

Three lanes ran as parallel subagents in git worktrees and were integrated one at a time,
each gated on the full suite before its commit.

| Commit | Lane | Covers |
|---|---|---|
| `9d17477` | Result, Stop detail, Saved Routes, Profile, Account, Language, tab shell | Safe area, sheet clamp below 700px (V8), text scale 1.0 and 1.5, system Back per tab stack, 48px targets, Result with tiles unavailable |
| `4f1bec8` | Login, Welcome, Onboarding, Loading | Safe area, text scale, Login keyboard and Back-dismisses-keyboard, Back from onboarding step 0 to Welcome (V7), background/resume during auto-advance and Loading, 48px targets |
| `0b08989` | Explore, shared map | Both carried device defects, safe area, search keyboard, 48px targets, text scale, offline resilience |
| `8776760` | main loop | Zoom control painted size and edge inset regression |

**Both device defects carried from Task-16 are fixed and verified on the emulator.** The
search pill now clears the status bar. The zoom controls are no longer occluded: the map
widget gained a top-overlay slot so the controls stack beneath whatever the screen puts
above them, at any text scale.

**Real defects found and fixed along the way**, none of them test artifacts:

- Onboarding chrome sat under the status bar at absolute `top: 20`.
- Button labels overflowed by 39px at text scale 1.5, on four call sites.
- Explore's info-card rating and tag row overflowed by 56px at text scale 1.5.
- The map zoom control's hairline divider had no width, so it stretched the painted
  control from 26px to the full 48px target column, and the control sat flush against the
  map edge where the screen clipped it. Caught by the device run, not by any widget test.

## What is left

1. **A fourth subagent was still running when this was written.** It owns
   `terra_nt/lib/shared/widgets/app_button.dart` and `app_text_input.dart` and was based
   on `4f1bec8`. Its worktree is under `.claude/worktrees/`. Check whether it committed;
   if it did, rebase or re-apply its diff onto `8776760`, run the full suite, and commit.
   If it did not, the two defects below are still open and are yours.
2. **`AppButton` has no 48px target.** It paints at `AppMetrics.buttonHeightLg` (40) and
   offers nothing larger, so every button in the app has a 40px-tall target. Width is fine.
3. **`AppTextInput`'s tap target is 24px tall.** The `TextField` box measures 278x24 inside
   a 42px decorated container whose 8px padding does not focus the field when tapped.
4. **The device journey has not been run.** This is the one Task-20 criterion no test can
   replace, and it is the largest remaining item. See the procedure below.
5. **`verify-task` has not been run.** It is the gate and it runs from the main loop, never
   from a lane. Nothing else marks Task-20 DONE.
6. **`/code-review` over the accumulated diff and `review-visual` are still deferred.**
   Both are advisory and neither gates the task. The accumulated diff is large: it spans
   Task-14, Task-16 and all of Task-20.

## The open decision — do not decide this alone

Two 26px zoom buttons stacked 26px apart cannot both carry non-overlapping 48x48 targets
while the painted control stays 8px from the map's top edge: the target column has to
extend 21.5px above the painted box, which would push it off the map. The painted control
therefore now sits 21.5px from the top instead of 8px. Size and horizontal inset are
correct; only the vertical position moved, by 13.5px, and it is visible on Explore and
Result.

Part 2 says an unrecorded visual difference is a defect, so this needs one of two answers,
and the answer is the operator's:

- Record it as a new deviation in `docs/PRD.md` section 7 and keep the 48px targets, or
- Give up the 48x48 target for the two zoom buttons and restore the prototype's exact
  position.

They cannot both hold. Nothing else in the tree depends on which way this goes.

## Also open, and also not ours to decide

`CLAUDE.md` Part 2 states the Flutter SDK is at `C:\Flutter\bin`. It is actually at
`D:\Dev\Flutter\bin`. The version claim is correct: 3.47.1 with Dart 3.13.1, verified. Only
the path is wrong. Part 2 is the operator's to change.

## Device journey procedure

The emulator `terra_nt` is defined and boots to `emulator-5554`, Android 16. It was
running when this was written; if it is not, `flutter emulators --launch terra_nt` and
wait for `adb shell getprop sys.boot_completed` to return 1. The launch command returns
before the device is usable, and it failed to boot once on the first attempt.

```
cd terra_nt
flutter build apk --debug --dart-define-from-file=.env
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell pm clear au.edu.cdu.terra_nt
adb shell am start -n au.edu.cdu.terra_nt/.MainActivity
```

**Clear app data before the journey.** Without it the app launches straight to Explore
because a completed session is left over from an earlier install, and the first half of the
journey is silently skipped.

The journey Task-20 asks for, in order: invalid Login submit and correction, Welcome,
onboarding, Loading, Result, reorder and remove and revert and restore, Stop detail skip
and unskip, Explore search and select and clear, Saved Routes, Profile, Account and
Language Back. Record device, OS, viewport and pass or fail notes in the task verification
report. Screenshots from the run are advisory visual evidence and never an acceptance
criterion.

## Notes for whoever picks this up

- Every `flutter` and `dart` command runs from `terra_nt/`. From the repo root they prove
  nothing, because the root has no `pubspec.yaml`.
- **Subagent worktrees in this repo were twice created from a stale commit**, once from a
  base where `explore_screen.dart` did not exist yet. Two lanes of work had to be thrown
  away. Any delegated lane must verify `git log --oneline -1` against the expected commit
  before its first edit and reset to it if wrong.
- Files under `.claude/worktrees/` are gitignored and hold the subagent lanes.
- Commit messages here are a single line with no body and no attribution trailer.
- The 5-hour Claude window was at 88% and the weekly at 47% when this was written. The
  Codex reading was 95% on a window already expired and flagged stale, which usually means
  it has since refilled; measure it rather than trusting that number.
