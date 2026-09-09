# Task-20 — Mobile readiness integration

> **Execution:** agent main loop · effort `medium` · plan mode no
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

A third observation is **not** a defect: Android search focus could not be driven through the
review tooling, so Explore's search, no-result and clear interaction remains unexercised on a
real device despite passing widget tests. The device journey below is what closes it.

## Acceptance Criteria (DoD)

- [ ] `cd terra_nt && flutter analyze && flutter test && flutter build apk --debug` all exit 0.
- [ ] Widget tests at 360×640 with representative top/bottom safe-area insets cover Login, Onboarding, Result, Explore, Stop detail, Saved Routes and Profile: no essential action is behind system UI, every screen remains scrollable where needed, and no `FlutterError` is recorded.
- [ ] Under that top inset, Explore's search pill clears the status-bar region and the shared zoom controls remain hit-testable rather than sitting under the search overlay.
- [ ] With the Result viewport's usable height below 700px, its sheet uses the clamped top anchor from Task-13 and its content remains reachable.
- [ ] Keyboard tests for Login and Explore search apply a representative bottom `viewInsets`; the focused field and submit/clear action remain reachable with no overflow, and system Back dismisses the keyboard before leaving the screen.
- [ ] Text-scale tests at 1.0 and 1.5 keep primary actions and exact copy reachable without clipped text or overflow on the same representative screens. This is a layout accommodation, not permission to change copy or visual tokens.
- [ ] Semantics/hit-test assertions give every interactive control a minimum 48×48 logical-pixel target. Smaller painted controls from the prototype, including Explore's 26px close circle and the map's 26px zoom buttons, retain their visual size inside a larger transparent hit target.
- [ ] Navigation tests exercise system Back from Stop detail, Account, Language and onboarding step 0, preserving the parent tab stacks and the Task-10 Welcome deviation; Back at a root tab does not pop another tab's stack.
- [ ] Lifecycle test: background/resume during a pending onboarding auto-advance and during Loading causes no duplicate timer, navigation or saved-route write; the resumed app has one coherent route and session state.
- [ ] Offline/device test: with tile requests unavailable, Explore and Result retain their local markers, controls and attribution over the existing surface1 background without an uncaught exception; Login, onboarding, seeded generation, edit/restore and Saved Routes remain usable. No automatic retry, offline-download or cache claim is made.
- [ ] Markers, polylines, zoom controls and attribution stay legible over an unkeyed watermarked tile. The task report records whether `.env` supplied `CARTO_API_KEY` for the device run; the watermark itself is not a failure.
- [ ] `git status` after a keyed device build shows no `.env` and no key in any tracked file.
- [ ] On an Android emulator or phone, complete one functional journey in the Flutter build: invalid Login submit and correction → Welcome → onboarding → Loading → Result → reorder/remove/revert/restore → Stop detail skip/unskip → Explore search/select/clear → Saved Routes → Profile → Account/Language Back. Record device/OS, viewport and pass/fail notes in the task verification report.
- [ ] Any Flutter screenshots captured during the device run are labelled advisory visual evidence; Task completion rests on the functional assertions above and `verify-task`, not screenshot similarity.
