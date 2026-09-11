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

**22b** (2026-09-12):

- **`minZoom` is 5, not 4.** `CameraConstraint.contain` only holds a camera whose
  whole visible region fits inside the box, and the box shrinks against the
  viewport as you zoom out. At zoom 4 an Australia-sized box is smaller than a
  phone viewport, so `constrain` returns null and `FlutterMap`'s options-setter
  assert throws. `AppMapVisuals.australiaCameraBounds` is also widened past
  Australia proper (lat 5..-50, lng 105..160) for the same reason. Two
  consequences worth a decision: the user can no longer zoom out to see the whole
  continent, and on a window wider than ~1250px (desktop, not a phase-1 target)
  `contain` would reject gestures. `CameraConstraint.containCenter` has neither
  problem and would still keep the map over Australia — raising it rather than
  swapping it, since 22b names `contain`.
- **The tile prefetch cannot warm `flutter_map`'s own cache.** 22b asks for
  `precacheImage` "so flutter_map's built-in cache is warm". It will not be:
  flutter_map 8.3.1 loads tiles through its own unexported
  `NetworkTileImageProvider` plus a built-in disk cache, which share no cache key
  with `NetworkImage`. The loop is implemented as specified and does warm
  Flutter's in-memory image cache and the DNS/TLS path, but the stated effect
  does not hold. Making the keys match needs a custom `TileProvider` returning
  `NetworkImage`, which would give up the persistent disk cache an offline-first
  app wants — so it was not done unilaterally.
- **`RouteDotMarker` was never on the Result map.** 22b item 4 assumes it is; the
  Result map uses `NumberedPinMarker`, and the dot only appears on the ambient
  backdrop. Took the "still wanted" branch: the widget stays (so its tests stay)
  and is repainted as a plain `AppColors.ink` dot at the existing
  `mapRouteDotSize`. Its spread `BoxShadow` ring is gone, which also settles a
  standing conflict with Part 2's "the only shadow is `--shadow-overlay`".
- **`AppMetrics.mapRouteDotRingWidth` → `mapCarWheelHubDivisor`.**
  `car_glyph.dart` was borrowing the route dot's ring width as the divisor for
  its wheel hub radius. Once the ring went the old name described nothing.
- **`WelcomeScreen` is now a `ConsumerStatefulWidget`.** The prefetch has to fire
  once after the first frame; a `ConsumerWidget` would re-fire it on every
  rebuild, and the alternative was a mutable global flag inside the prefetcher.
- **`TerraMap.resultFitPadding` → `resultFitPaddingFor(viewportHeight)`**, plus a
  new `AppMetrics.mapResultMinimumStrip`. A fixed reservation is wrong in both
  directions: too small and stop 7 hides under the sheet (seen on device), too
  large and the fit bottoms out at `minZoom` and pushes the northern pins off the
  top (seen in the 600px-tall harness).
- **`TerraMap` gained an `animatedMarkers` record parameter** so the backdrop can
  rebuild only the marker layer, and `AppMetrics.mapMaxZoom` replaces the inline
  `maxZoom: 19`.
- **Touched 22c's file.** `test/features/itinerary/result_screen_test.dart`
  pinned the map at 340px, which B2 invalidates. Changed that one assertion to
  compare against the Scaffold body and added the full-bleed test there, because
  the harness it needs lives in that file. Expect a conflict with 22c.

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
- 22c: the **edit-mode row dropped the "Skipped" pill and the subtitle**. The compact row
  the spec lists is badge, name, revert, remove, drag handle and nothing else; at 320px
  three 48px targets leave under 90px for the name. Skipped state still reads in edit mode
  through the 0.5 opacity, and the pill is unchanged in view mode where the tests assert
  it. Skipping is a Stop detail action, so edit mode never raises it.
- 22c: the **drag handle moved from leading to trailing**. Both this task file and the
  brief list it last; the old full-height card had it first. Flagging because it is a
  visible change nothing asked for in those words.
- 22c: `ResultStopList` became a `ConsumerWidget`. Deleting `_ReorderDragFlag` emptied its
  `State` of all state; keeping a `StatefulWidget` that holds nothing would have been dead
  weight from my own removal.
- 22c: `_EditAction` was renamed **`ResultIconAction`** and made public so the header's
  "Plan again" button reuses it instead of restating the 26px-circle-in-a-48px-target
  geometry. Same widget, same tokens, one more call site.
- 22c: `docs/PRD.md` §3.6 got **two edits beyond item 2**, both because the build would
  otherwise contradict the spec: item 1 now describes the "Plan again" action and its
  confirmation, and item 6 now describes the edit-mode snap and the compact row. Neither
  is a §7 deviation entry — I6 and B3 are operator decisions recorded in this file, and
  whether they also want a V-number is the main loop's call.
- 22c: **the brief says §3.5; the Result screen is §3.6.** I edited §3.6. §3.5 is Explore
  and says nothing about Highlights/Detailed.
- 22c: **`_hasUnsavedEdits` has no test.** It is the predicate deciding whether "Plan
  again" confirms or acts, and it lives in `result_screen.dart` because my lane may only
  add `reset()` to `notifiers.dart` and does not own `core/util/`. The brief assigns the
  Plan-again acceptance tests to the main loop, so I left it uncovered rather than write
  my own acceptance test. If it should be tier 1 instead, the home is
  `core/util/itinerary_ops.dart` as `hasEdits(order, totalStops, skipped)`.

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

**22h** (2026-09-12):

- **The Result map painted no tiles on first show, and the fix is a pre-fitted
  camera.** `TerraMap` built `FlutterMap` at `initialCenter (-18, 132)` / zoom 5 and
  then let `initialCameraFit` move it after the first layout. The tiles the throwaway
  z5 camera had already asked for were still in flight when the camera jumped to the
  fitted position (z5.13, centre -26.96); the ones the fitted camera still needed were
  never re-requested, so the map sat on `surface1` until the user zoomed. Explore
  escaped it only because its fit lands on z6, a different tile set. `TerraMap` now
  computes the fit *before* the first frame — a `LayoutBuilder` builds a `MapCamera`
  for the constraints' size and `CameraFit.bounds(...).fit(camera)` returns the fitted
  one, whose centre and zoom become `initialCenter`/`initialZoom`; `initialCameraFit`
  is gone, `CameraConstraint.contain` stays. Only one camera ever requests tiles. A
  later size change (rotation) leaves the camera where the user left it, which is what
  `initialCameraFit` did too. Measured on `emulator-5554` over the map crop
  (0,150)-(1080,1000) after a `pm clear` and a full onboarding run: **before** 0 px of
  CARTO ocean, 0 px of land, 899,987 px (98.0%) of bare `surface1`; **after** 780,824 px
  ocean, 87,458 px land, 0 px `surface1`. New widget test: a `TerraMap` given bounds
  reports a zoom inside `mapMinZoom..mapMaxZoom` and a centre inside those bounds after
  a single `pump`, with `options.initialCameraFit` null.
- **The progress track never painted a pixel — on any screen.** Found while checking
  the loading polish: both bars were childless `ColoredBox`es inside a `Stack`, which
  lays its children out loosely, so each took the smallest size allowed and collapsed
  to zero height. The car has been driving along an invisible track since 22e. Both
  bars now carry `AppMetrics.onboardingProgressHeight` explicitly, and a test asserts
  the track and the fill are that tall. This is why the loading track "had no
  contrast": there was nothing to contrast with.
- **Loading screen: the drive now sits in the onboarding progress pill.** The looping
  `ProgressDrive` moved below the status message into a `loading-progress-shell`
  container carrying the onboarding chrome's padding, radius, hairline and fill, inset
  by the existing `loadingStatusSidePadding`. The fill is `AppColors.onboardingChrome`
  (`surface2` at 70%) rather than `surface1`, so the shell is literally the same pill
  the onboarding chrome uses. Onboarding's counter text is what makes that pill tall
  enough for the car, so the shell reserves `onboardingProgressCarHeight` itself.
- **The progress car is 27x24, not 14x12.** At 2.6x density the old size read as a
  smudge. 27x24 is the map marker glyph's own 36:32 aspect, so the `FittedBox`
  letterboxes nothing. The pill still contains it without clipping: the counter text
  makes the row 15.4px tall, which with the 9px vertical padding leaves 4.7px of
  clearance at each end — confirmed on device.
- Report figures: `docs/report-figures/` is untracked, so the two captures stayed out
  of the repo, in the machine's temp directory as `onboarding-step-2.png` and
  `loading.png`.

## Frame times (22b)

Measured 2026-09-12 on `emulator-5554` (sdk gphone64 x86-64, Android 16 / API 36,
1080x2400), `flutter build apk --profile`, no `.env` so tiles are the watermarked
unkeyed ones. Explore panned by 24 scripted `input swipe` gestures per sample;
frame intervals are the deltas between `actualPresentTime` values from
`dumpsys SurfaceFlinger --latency` on the app's BLAST layer. `dumpsys gfxinfo` is
useless here — Flutter renders to its own surface and reports 1 frame.

| Build | p50 | p90 | p95 | max | intervals > 25 ms |
|---|---|---|---|---|---|
| Baseline (Task-21 HEAD), warm | 21.71 / 22.30 | 33.19 / 32.59 | 41.70 / 34.97 | 47.88 / 52.44 | 42.9% / 42.9% |
| 22b, retina off + buffers cut, cold cache | 29.42 | 33.35 | 39.76 | 64.27 | 61.3% |
| 22b, retina off + buffers cut, warm | 16.62 / 21.31 / 19.29 | 18.63 / 32.59 / 35.36 | 19.31 / 47.91 / 46.67 | 20.38 / 59.66 / 50.77 | 0% / 42.9% / 35.5% |
| 22b as shipped (retina on, default buffers), warm | 16.66 / 16.77 | 18.28 / 18.32 | 18.84 / 18.82 | 20.84 / 21.64 | 0% / 0% |

**The comparison is inconclusive and no perf claim is made from it.** The spread
within one binary (0%–42.9% janky intervals on the *same* APK) is wider than the
spread between binaries, so this emulator cannot attribute a difference to the
code. It is a software-rendered VM sharing a host CPU; a real device is needed
before any of these levers is judged.

Acting on that, the two levers with a cost were **not** kept:

- **`retinaMode` left on.** Turning it off bought nothing outside the noise and
  visibly softened the basemap on a 2.6x-density screen — an unproven gain does
  not justify a fidelity regression.
- **`keepBuffer`/`panBuffer` left at their defaults.** The one clear signal in
  the whole run is that cutting them made the *cold-cache* pan markedly worse
  (61.3% janky), which is what `panBuffer` exists to prevent. 22b said to apply
  these "as the profile supports"; it does not.

Kept on structural grounds rather than measurement: the car marker now rebuilds
through a `ListenableBuilder` instead of `setState`, which stops the backdrop
handing `FlutterMap` a fresh `MapOptions` and `TileLayer` 60 times a second. The
Explore pan measured above never exercises it, so no number here speaks to it.
The polyline cap was not needed — the route is 7 points.

Device checks (same emulator, final build): Explore pans and stays over
Australia under the new camera constraint, with no rejected gestures and no
blank first frame; the Result map is full-bleed and all 7 pins sit above the
sheet at its middle anchor.

**22g** (2026-09-12):

- **The tile prefetch is replaced, not repaired.** 22b's own note is right that
  `precacheImage` cannot warm `flutter_map`'s cache. The warm-up now mounts a
  real `TerraMap` on Welcome under an `Offstage`, so the tiles are fetched by
  the actual `TileLayer` through `NetworkTileProvider` into its default
  `BuiltInMapCachingProvider` disk cache — the same cache, under the same keys,
  Explore reads. Verified against the flutter_map 8.3.1 source in the pub
  cache: `FlutterMap` derives `MapCamera` from a `LayoutBuilder`, `TileLayer`
  reads that camera in `didChangeDependencies` and `build` and calls
  `TileImage.load()`, and `RenderOffstage.performLayout` lays its child out
  with the incoming constraints while skipping only paint, hit testing and
  semantics. So `Offstage` is sufficient and neither `Opacity(opacity: 0)` nor
  hiding it behind the backdrop was needed. `lib/shared/map/tile_prefetcher.dart`,
  `lib/core/util/tile_math.dart` and `test/core/util/tile_math_test.dart` are
  deleted; nothing else used them.
- **The warm-up fits the POI bounds, not "the NT bounds in `map_visuals.dart`".**
  The brief names bounds that do not exist there: `map_visuals.dart` declares
  only `australiaCameraBounds`, the deliberately widened *constraint* box, and
  the NT box the brief means lived in the deleted `tile_math.dart`. Fitting
  either would warm a different tile set than the one Explore asks for, which
  defeats the purpose. It fits what Explore fits — every seeded POI, with
  `TerraMap.exploreFitPadding`.
- **`poiBounds(pois)` added to `terra_map.dart`,** and Explore now calls it
  instead of inlining `LatLngBounds.fromPoints`. The warm-up is only correct
  while it fits exactly what Explore fits; two copies of that line would have
  been free to drift apart silently. It sits at the `flutter_map` boundary,
  which is where Part 2 puts `LatLng` construction.
- **The warm-up box is the screen size, not a fixed phone size.** Explore's map
  is full-bleed, so `MediaQuery.sizeOf` is the closest match available on
  Welcome. It is not exact — Explore sits above the tab shell's bottom nav, so
  its viewport is shorter by that bar — but the fit is bounds-driven and the
  resulting tile ranges overlap; reserving the nav height here would mean a new
  metric for a warm-up nobody sees.
- **`WelcomeScreen` is a `ConsumerWidget` again.** 22b made it stateful purely
  to fire the prefetch once after the first frame; with the prefetch gone that
  reason is gone, and the warm-up is a plain child widget.
- **`RouteCarBackdrop.progress` deleted** (22e flagged it). With it went
  `RouteCarBackdropMode`, the `fraction` field and `didUpdateWidget`, which
  only ever handled mode/fraction changes. `.ambient()` is untouched, so Login
  and Welcome are unchanged. Two of its tests were progress-only: the waypoint
  sweep is deleted (it needed `.progress` to drive arbitrary fractions, and
  `pointAtFraction` is covered tier 1 in `test/core/util/util_test.dart`), and
  the off-chord test is kept, rewritten to run on the ambient drive so the live
  path keeps that coverage.
- **`mapFraction` deleted** from `core/util/onboarding_rules.dart` with its unit
  test, per 22e's flag; no production caller remained after the onboarding map
  backdrop was removed.
- **Welcome is not on the cold-launch path, so the warm-up only runs if the
  user reaches Welcome.** `app_launch.dart` sends a fresh session straight to
  `AppRoute.onboarding`; Welcome is reached from Login's `onAuthenticated` or
  from exiting onboarding. 22b's prefetch had exactly the same reach, so this is
  not a regression, but "warm the tiles before Explore" only holds for users who
  pass through Welcome. Raising it rather than moving the warm-up: which screen
  should own it is a routing decision, not this sweep's call.
- **Device evidence (emulator-5554, debug build, `pm clear` first).** Counting
  entries in flutter_map's own disk cache, `cache/fm_cache`, via `run-as`:
  0 after clear, 0 on onboarding (no map on screen), **25 on Welcome before
  Explore is ever opened**, and still **25 two seconds into Explore** — Explore
  fetched no new tiles, because the warm-up had already cached the set it asks
  for. Its first frame draws tiles, labels and all 8 pins. Caveat: Welcome also
  shows the ambient backdrop, whose map fetches an overlapping tile set, so the
  count alone does not separate the two; what the warm-up adds specifically is
  Explore's exact bounds and padding, which the widget test pins.
- **`AppColors.onboardingScrim` is left in place** and is still dead. Tokens go
  only by a deliberate decision (Part 2), so this stays a flag for the user, not
  an edit. It raises no analyzer warning.


## Device tour

Run by the main loop on 2026-09-12, `emulator-5554` (Android 16, 1080x2400, 2.625x),
debug build with the CARTO key, app data cleared first. Driven with `adb input`,
read from `screencap` captures.

| Item | What was exercised | Result |
|---|---|---|
| I1 / I7 | All 15 steps with Next; picks do not advance; the last step takes two text inputs and gates "Generate My Route" on both | Pass |
| I2 | Slider thumb held for 1.5 s | No value bubble; only the Material overlay halo |
| I3 | Flat canvas behind the questions, car on the progress pill from 1/15 to 15/15 | Works, but at 14x12 the car reads as a smudge; resized by 22h |
| I4 | Loading after Generate | Canvas background; the looping track is invisible and the car floats beside the disc; recomposed by 22h |
| B2 | Result sheet dragged handle-first to the peek anchor; map is full-bleed | No `surface1` void beneath the sheet. **But the map painted no tiles at all** (pixel crop uniform `(15,16,17)`); see below |
| B3 | Edit Route: sheet snapped to 700, 7 compact rows; row 1 dragged to the bottom with a 1.5 s swipe | Order changed (Darwin last), revert icons appeared, no Flutter exception in logcat |
| I6 | Plan again with unsaved edits | Inline "Discard edits and plan again?" panel; Cancel keeps the route; Plan again lands on 1/15 with answers cleared |
| B1 / B4 | Explore after tiles cached; panning stays over Australia | Tiles drawn, constraint holds, no visible jank on this emulator |

**Result-map tiles (found by the tour, fixed by 22h).** A probe build logged the
`TileLayer`: the first frame runs at `initialCenter (-18,132)` / zoom 5 and requests the
z5 tiles; `initialCameraFit` then moves the camera to zoom 5.13 / centre -26.96. The z5
tiles cancelled by that move and still needed afterwards (row y=16, column x=26) never
loaded again, so Result stayed black until a zoom fetched fresh tiles. Explore escaped
only because its fit lands on z6. The fix computes the fitted camera before the first
frame so no throwaway camera ever requests tiles.
