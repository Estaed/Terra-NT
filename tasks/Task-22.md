# Task-22 — Bug fixes and improvements batch (2026-09-11)

Status: IN PROGRESS

> **Execution:** agent `main-loop` as chef, sub-tasks on `claude` bees · effort `medium` · plan mode no
> *Why:* Operator decision 2026-09-11: eight improvements and four bugs from a device
> session, all decided in conversation. No open architecture choice remains; Plan mode
> would restate this file. The main loop writes the specs, integrates the worktrees and
> runs `verify-task`; bees never write their own acceptance tests.

**Lane**
- OWNS: see the per-sub-task lanes below
- MUST NOT TOUCH: `CLAUDE.md` Part 2, `terra_nt/pubspec.yaml`
- GATE: `cd terra_nt && flutter analyze && flutter test`, then the device tour in
  `docs/DEVICE-TOUR.md` for B2, B3, I3, I4 and Explore panning
- DEPENDS ON: Task-21

## Operator decisions this batch carries

- Pixel fidelity to `docs/screenshots/` is not required for this batch; token, font,
  spacing and motion consistency is. A bee may change something not listed if needed
  and records it under *Unrequested changes* below.
- I5 is option (b): Stop detail shows the detailed plan under its header.
- Onboarding advances on Next only; auto-advance on tap is removed (V12).
- Q9 "How detailed" is removed; the last question becomes start/end location (V11).
- Onboarding loses the map backdrop; a car drives along the top progress bar (V13).

## Sub-tasks

| Id | Scope | Agent | Wave | Status |
|---|---|---|---|---|
| 22a | Onboarding questions, Next-only, slider bubble | `claude` opus | 1 | pending |
| 22b | Map plumbing: full-screen Result map, prefetch, constraint, perf, dots | `claude` opus | 1 | pending |
| 22d | Stop detail shows `detailedPlan` | `claude` sonnet | 1 | pending |
| 22c | Result: reorder scroll fix, local Highlights/Detailed, Plan again | `claude` opus | 2 | pending |
| 22e | Onboarding flat backdrop, car on progress bar | `claude` opus | 2 | pending |
| 22f | Loading screen themed surface | `claude` sonnet | 3 | pending |

### 22a — Onboarding: questions, Next-only, slider bubble

OWNS: `lib/data/models/onboarding_answers.dart`, `lib/core/util/onboarding_rules.dart`,
`lib/features/onboarding/**`, `lib/data/repositories/notifiers.dart` (onboarding notifier
only), `docs/PRD.md` §3.3 table and §7.

1. Remove Q9. Append a new last question (index 14): "Where does your trip start and
   end?" with two `AppTextInput` fields labelled "Start" and "End", placeholders
   "e.g. Darwin" / "e.g. Alice Springs". `OnboardingAnswers` gains `startLocation` and
   `endLocation` (`String?`); `detailed` is removed. `canNext(14)` requires both
   non-empty after trim. Steps 9–13 shift up by one; the "NT-specific" pill now sits on
   steps 9–13; the last step's button still reads "Generate My Route"; the new step 14
   has no pill. The `focus` multi-select stays at 3. Step count stays 15, so
   `progressPercent` and `mapFraction` keep their formulas.
2. Next-only advance: delete the auto-advance timer, `selectAndAdvance` and
   `_autoAdvances`; a tap only records the answer. `OnboardingMotion.autoAdvance` and
   `AppMotion.onboardingAutoAdvance` go if nothing else uses them. Keep the 320 ms
   step-card motion.
3. `SliderStep`: remove `Slider.label` (the value bubble).
4. PRD: rewrite the §3.3 table row 9 → shifted rows, new row 14; add V11 and V12 to §7.
5. `result_screen.dart` and its test read `answers.detailed`: change only that read to a
   local `bool _detailed = false` field and its setter so the tree compiles. 22c owns the
   rest of that file.

Acceptance (written by the main loop, not the bee): `canNext(14)` for empty / one /
both; `progressPercent(0|8|14)`; the Task-10 auto-advance tests are rewritten to assert
that tapping an option does not advance and Next does; no `Timer` pending after any
onboarding test.

### 22b — Map plumbing

OWNS: `lib/shared/map/**`, `lib/core/theme/map_visuals.dart`, `metrics.dart`
(map values only), `lib/features/itinerary/result_screen.dart` (the `result-map`
`Positioned` only), `lib/features/auth/welcome_screen.dart` (prefetch call only),
`test/shared/map/**`.

1. B2: the Result map fills the screen. Delete `AppMetrics.resultMapHeight`; the
   `result-map` `Positioned` becomes `Positioned.fill`. Fit padding accounts for the
   sheet at its middle anchor (bottom padding = `resultSheetMidHeight` + margin) so the
   pins sit above the sheet.
2. B1: a named `LatLngBounds` for Australia in `map_visuals.dart`;
   `CameraConstraint.contain` and `minZoom` on every `TerraMap`. Prefetch the CARTO
   tiles covering the NT bounds at zoom 4–6 while Welcome is showing, through
   `precacheImage` on the tile URLs (with the key) so flutter_map's built-in cache is
   warm before Explore mounts. No new package.
3. B4: profile first on the Android emulator (`flutter run --profile`), record frame
   times in this file. Then, as the profile supports: `retinaMode` off or
   `maxNativeZoom`; `panBuffer`/`keepBuffer` reduced; the car animation in
   `route_car_backdrop.dart` rebuilds only the marker layer via a `ListenableBuilder`,
   not the whole `FlutterMap`; polyline sample count capped if it is large. Record the
   after numbers.
4. I8: `RouteDotMarker` leaves the Result map. On the backdrop, if a stop marker is
   still wanted, use a small `AppColors.ink` dot sized from an existing metric;
   otherwise delete `RouteDotMarker` and its tests.

Acceptance: existing map tests green; a widget test asserts the `result-map` render
box equals the Scaffold body; the emulator run shows no blank first frame.

### 22c — Result: reorder, local Highlights/Detailed, Plan again

OWNS: `lib/features/itinerary/result_screen.dart` (except the map `Positioned`),
`lib/features/itinerary/widgets/result_stop_list.dart`, `lib/app/screen_routes.dart`,
`lib/data/repositories/notifiers.dart` (reset only), `test/features/itinerary/**`.

1. B3 root cause: `_ReorderDragScrollPhysics` refuses scroll during a drag because a
   stop card is taller than the 160 px viewport at the peek anchor. Fix: entering edit
   mode snaps the sheet to the 700 anchor; edit rows are compact (number, name, revert,
   remove, drag handle; ~56 px); then delete the physics and the flag box. Keep
   `notifier.reorder`, revert, restore and their tests.
2. Highlights/Detailed is Result-local state defaulting to Highlights.
3. I6: a "Plan again" action on the Result header. Resets the onboarding answers and the
   itinerary session state, then navigates to onboarding step 0 through
   `screen_routes.dart`. With unsaved edits, the inline-confirm pattern from Profile
   delete-account: "Discard edits and plan again?" with "Plan again" / "Cancel".

Acceptance: widget test drags stop 1 to the last position through a scroll in edit
mode and the order changes; Plan again with and without edits; device tour drag.

### 22d — Stop detail shows the detailed plan

OWNS: `lib/features/itinerary/stop_detail/**`, `test/features/itinerary/stop_detail/**`.

Under the header (name, subtitle) render `stop.detailedPlan` as the first content block:
time in the mono type role, activity in the body role, same row style as the Result
list's Detailed mode. Empty `detailedPlan` shows the `aiNote` line instead (P5
fallback). Hours, fee, duration, tags, Skip and Navigate stay below.

Acceptance: renders all entries for a stop that has them; renders `aiNote` for one that
does not.

### 22e — Onboarding flat backdrop, car on progress bar

OWNS: `lib/features/onboarding/onboarding_screen.dart` (backdrop and progress chrome),
new `lib/features/onboarding/widgets/progress_drive.dart`, `lib/core/theme/motion.dart`
and `metrics.dart` (new named values only), `test/features/onboarding/**`.

Remove `RouteCarBackdrop.progress` and the scrim from onboarding; flat
`AppColors.canvas` background. The top progress track keeps its tokens; the fill grows
per step; `CarGlyph` rides the fill's leading edge and eases to its new position with
the existing onboarding curve over the step-card duration. One `AnimationController`,
created in `initState`, disposed in `dispose`. Delete `RouteCarBackdrop.progress` if
nothing else uses it. Record V13.

Acceptance: the car's x offset differs between step 0 and step 1 and settles after the
duration; no pending timers or tickers after dispose.

### 22f — Loading screen themed surface

OWNS: `lib/features/loading/**`, `test/features/loading/**`.

Replace the black background with `AppColors.canvas` and continue the 22e progress
drive in an indeterminate mode across the loading messages. Keep the message and
completion timers and their disposal tests.

Acceptance: Scaffold background is the token; no timer leaks on early pop.

## Deviations added

- V11, V12: 22a. V13: 22e.

## Unrequested changes

(filled by bees and the main loop)

- 22e: `RouteCarBackdrop.progress` is now unused by onboarding; delete after 22b lands.
  Its tests are untouched, and `lib/shared/map/**` was not edited — 22b owns it.
- 22e: `AppColors.onboardingScrim` and `mapFraction` (in `onboarding_rules.dart`) lost
  their only production caller. The token stays, per the rule that tokens only go by a
  deliberate decision; `mapFraction` stays because 22a's spec says it keeps its formula
  and it still has unit tests. Neither raises an analyzer warning. Flagging both as dead
  code for the main loop to sweep.
- 22e: `CarGlyph` was reused as-is, with no new parameter. It needed neither: its
  `longitudeDelta` sign already sets the facing, so travel direction maps onto the
  existing API, and a `FittedBox` scales the 36x32 glyph into the new car metrics without
  touching a file 22b holds.
- 22e: skipped the optional road-dash flourish. On a 4px track a dashed centre line is
  sub-pixel mush, and it would have cost two more metrics for something invisible.
- 22e: `test/features/onboarding/onboarding_screen_test.dart` — the endpoints test now
  pumps the step-card duration before comparing fill width to track width. The assertion
  is unchanged; the fill is animated now, and `moveTo` pumps one frame per step, so it
  was being read mid-drive. No other assertion touched.
- 22e: relocated the sampler paragraph (cumulative-distance table, `700 + span × 3500` ms,
  `1 - (1-t)³`) from PRD §3.3 to §3.1. It was only written down under onboarding, which
  no longer has a backdrop, but it still governs the Login/Welcome ambient car and
  `CLAUDE.md` Part 2 cites it. Also narrowed the §4 "genuinely fixed" row from
  "The Login / onboarding backdrop route" to "The Login backdrop route".
- 22f: `loading_screen.dart` had no `RouteCarBackdrop` usage to remove — nothing there
  imported `shared/map/**`. Set `Scaffold.backgroundColor` explicitly to `AppColors.canvas`
  (the theme's `scaffoldBackgroundColor` already resolves to the same token, but the
  acceptance criterion reads the Scaffold directly). Added `ProgressDrive.looping()` in a
  `Padding` using the existing `AppMetrics.loadingStatusSidePadding`/`loadingContentGap`
  tokens rather than a new width metric, since `metrics.dart` was out of this sub-task's
  file list. `ProgressDrive`'s car glyph is now rebuilt on every animation tick (was
  previously passed as `AnimatedBuilder.child`, built once) so a looping drive's direction
  flip at each end of the track is actually painted; the non-looping onboarding path is
  unaffected since its direction only ever changes once per step, at a point where the
  whole widget already rebuilds.
- 22d: kept the existing bottom `_AiNote` box in `stop_detail_screen.dart` unconditional
  (always rendering `stop.aiNote`), instead of making it exclusively the empty-`detailedPlan`
  fallback. The literal spec reads as either/or in the new top slot, but the pre-existing
  test `renders seeded copy and omits a missing fee` asserts `aiNote` renders for
  `seedStops[0]`, which has a populated `detailedPlan`. Removing the bottom box to make the
  top slot strictly either/or would have broken that test. Net effect: the new top slot
  shows `detailedPlan` rows when present (nothing there when empty), and the bottom `_AiNote`
  box still always renders `aiNote` — so the acceptance criteria (entries render when
  present; `aiNote` renders when empty) both hold, at the cost of `aiNote` not being
  positionally "first" for the empty case. Flagging for the main loop to confirm this
  reading or say the old test should be updated instead.

## Frame times (22b)

(before / after, emulator, profile mode)

## Device tour

(filled by the main loop)
