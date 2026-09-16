# Task-20 — Mobile readiness integration

Status: DONE

> **Execution:** agent main loop · effort `medium`
> *Why:* The feature shape is fixed; this is a bounded final verification and defect-fix pass on a real Flutter build.

**Lane**
- OWNS: `terra_nt/` integration checks only — this task fixes defects wherever it finds them, under main-loop judgement
- MUST NOT TOUCH: nothing categorically; it is the final pass and owns the whole tree by exception
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: every other task

## Objective

Verify the completed phase-1 app as one phone experience after Tasks 00–19. Fix only
failures exposed by these checks. Do not redesign a screen, add backend or AI work, add an
offline-map feature, or weaken prototype fidelity.

## Execution Guide

Run from `terra_nt/`. Automated checks stay in the existing owning feature test folders;
cross-feature journey coverage may live under `test/integration/`. Do not create a third
repository seam or add a package solely for this task.

The app's data, mocked auth and seeded generation work without a network. CARTO tiles do
not: they are the one remote resource. Tile failure may leave the existing surface1 background visible,
but must not crash, hide local markers/controls/attribution, or block non-map flows. This
task does not promise downloaded or cached maps.

**The tile endpoint now takes a free API key** (`CLAUDE.md` → Part 2). The key lives in the
gitignored `terra_nt/.env`; copy `.env.example`, fill it in, and add
`--dart-define-from-file=.env` to the device build and run. With no key CARTO still serves
the tile, stamped "API KEY REQUIRED" — that watermark is a provider notice, not a defect
this task fixes. No key enters the repo, and `.env` is not an asset.

Visual review is separate: inspect the **running Flutter app** beside the reference captures
through `review-visual`. That report is advisory and cannot pass or fail this task; no
prototype screenshot, golden image or "looks right" assertion enters the DoD.

## Carried findings

Two device defects were observed during Task-16's advisory Android review on 2026-09-09 and
were deliberately left for this task. They are defects, not advisory notes, and the DoD below
covers both:

1. Explore's search pill overlaps the Android status-bar region.
2. The shared zoom controls are obscured by the search overlay in Explore's default view.
   **Closed 2026-09-10 by removing the zoom controls**, on the operator's decision, rather
   than by repositioning them: two 26px buttons stacked 26px apart cannot both carry a
   non-overlapping 48x48 target without leaving the map's top edge. Recorded as deviation
   V10 in `docs/PRD.md` section 7. Pinch and double-tap zoom are untouched. Every criterion
   below that names a zoom button is void with it.

A third observation is **not** a defect: Android search focus could not be driven through the
review tooling, so Explore's search, no-result and clear interaction remains unexercised on a
real device despite passing widget tests. The device journey below is what closes it.

## Acceptance Criteria (DoD)

- [x] `cd terra_nt && flutter analyze && flutter test && flutter build apk --debug` all exit 0.
- [x] Widget tests at 360×640 with representative top/bottom safe-area insets cover Login, Onboarding, Result, Explore, Stop detail, Saved Routes and Profile: no essential action is behind system UI, every screen remains scrollable where needed, and no `FlutterError` is recorded.
- [x] Under that top inset, Explore's search pill clears the status-bar region and the shared zoom controls remain hit-testable rather than sitting under the search overlay.
- [x] With the Result viewport's usable height below 700px, its sheet uses the clamped top anchor from Task-13 and its content remains reachable.
- [x] Keyboard tests for Login and Explore search apply a representative bottom `viewInsets`; the focused field and submit/clear action remain reachable with no overflow, and system Back dismisses the keyboard before leaving the screen.
- [x] Text-scale tests at 1.0 and 1.5 keep primary actions and exact copy reachable without clipped text or overflow on the same representative screens. This is a layout accommodation, not permission to change copy or visual tokens.
- [x] Semantics/hit-test assertions give every interactive control a minimum 48×48 logical-pixel target. Smaller painted controls from the prototype, including Explore's 26px close circle and the map's 26px zoom buttons, retain their visual size inside a larger transparent hit target.
- [x] Navigation tests exercise system Back from Stop detail, Account, Language and onboarding step 0, preserving the parent tab stacks and the Task-10 Welcome deviation; Back at a root tab does not pop another tab's stack.
- [x] Lifecycle test: background/resume during a pending onboarding auto-advance and during Loading causes no duplicate timer, navigation or saved-route write; the resumed app has one coherent route and session state.
- [x] Offline/device test: with tile requests unavailable, Explore and Result retain their local markers, controls and attribution over the existing surface1 background without an uncaught exception; Login, onboarding, seeded generation, edit/restore and Saved Routes remain usable. No automatic retry, offline-download or cache claim is made.
- [x] Markers, polylines, zoom controls and attribution stay legible over an unkeyed watermarked tile. The task report records whether `.env` supplied `CARTO_API_KEY` for the device run; the watermark itself is not a failure.
- [x] `git status` after a keyed device build shows no `.env` and no key in any tracked file.
- [x] On an Android emulator or phone, complete one functional journey in the Flutter build: invalid Login submit and correction → Welcome → onboarding → Loading → Result → reorder/remove/revert/restore → Stop detail skip/unskip → Explore search/select/clear → Saved Routes → Profile → Account/Language Back. Record device/OS, viewport and pass/fail notes in the task verification report.
- [x] Any Flutter screenshots captured during the device run are labelled advisory visual evidence; Task completion rests on the functional assertions above and `verify-task`, not screenshot similarity.


## Verification report — 2026-09-10

`verify-task` from the main loop. `cd terra_nt` for every command.

| Command | Result |
|---|---|
| `flutter analyze` | zero errors, zero warnings |
| `flutter test` | 293 passed |
| `flutter build apk --debug` | exit 0 |
| `flutter build apk --debug --dart-define-from-file=.env` | exit 0 |

Failure trajectory: `iter 1: 0 fail`. Everything the loop would have chased was fixed and
re-gated before this run; nothing went red inside it.

**Mutation checks.** Each fix landed here was removed and the suite re-run, then restored:

| Mutation | Result |
|---|---|
| drop the reorder list's auto-scroll suppression | 12 framework errors, peek-anchor test fails |
| make `onReorderItem` a no-op | order unchanged, same test fails on the order assertion |
| stop forwarding system Back into the launch navigator | both `app_launch_test` Back tests fail |
| drop `StackFit.expand` from the Login stack | full-bleed backdrop test fails |
| all restored | 293 passed, analyze clean |

**Device journey.** Google `sdk_gphone64_x86_64`, Android 16 / SDK 36, `emulator-5554`,
1080x2400 physical at 420dpi, so a 411x914 logical viewport. Keyed debug build installed
with `adb install -r`, `adb shell pm clear au.edu.cdu.terra_nt` before the run, launched
with `am start`. `.env` supplied `CARTO_API_KEY`: tiles render unwatermarked.

Order and result: cold start lands on onboarding, which is the launch rule `docs/PRD.md`
section 9 Q2 fixed, not Login. System Back at step 0 goes to Welcome (V7). Welcome, Skip
for Now, Explore, Profile, Log Out reaches Login. Invalid submit shows both field errors;
system Back dismisses the keyboard and stays on Login; corrected credentials go to Welcome.
Create My Route, all fifteen onboarding steps, Generate My Route, Loading, Result. Reorder
by drag at the middle anchor and again at the peek anchor, where a stop card is taller than
the list viewport: the order really changed both times and logcat stayed clean. Remove,
per-row revert, "Restore 1 removed stop". Stop detail skip, unskip, system Back to the tab
root. Explore search, POI select, no-result state, Clear search. Saved Routes lists the
generated route beside the two seeded ones. Profile, Account and Back, Language and Back,
each returning to the Profile tab root with the other tab stacks untouched. Logcat carried
no Flutter error, no exception and no overflow across the whole journey; the only
`AndroidRuntime` lines belong to the `uiautomator` shell command used to read the semantics
tree.

`git status` after the keyed build shows no `.env`; the key's value appears in no tracked
file. Screenshots from the run are advisory visual evidence only and live outside the repo.

**Two criteria are satisfied in part, by the operator's decision of 2026-09-10.** The map's
zoom buttons were removed rather than repositioned, recorded as deviation V10 in
`docs/PRD.md` section 7 and under *Carried findings* above. The clauses about zoom controls
staying hit-testable, keeping a 48x48 target and staying legible over a tile are void with
them; the search-pill, close-circle, marker and attribution clauses in the same criteria all
hold and were verified.


**Post-review round.** `/code-review high` ran afterwards as an advisory pass and found a
second instance of the same Back defect: `AppShell` popped the active tab's Navigator with
`pop`, walking past any route-level `PopScope`, and claimed `canPop` at a tab root, so
Explore's keyboard-dismissing guard never fired inside the shell. The one test covering it
pumped Explore outside the shell, so it passed for the wrong reason. The shell now forwards
Back with `maybePop` and hands the unhandled case to `SystemNavigator.pop`; a new
`tab_shell_test` case drives it inside the shell, and the tab-stack test now asserts that
Android was asked to close the app rather than asserting the dispatcher's return value.
Both mutations of the new path fail the test. Re-verified on the device: Account Back
returns to the Profile tab root, and Back with the Explore keyboard up closes the keyboard
and keeps the app, with clean logcat.
