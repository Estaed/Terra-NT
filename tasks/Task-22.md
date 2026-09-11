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

## Device tour

(filled by the main loop)
