# Terra NT app review — motion, illustration, logic, quality of life

30 September 2026. This one report merges Codex's two reviews (`review.md`,
`illustration-review.md`) with a second emulator tour and a code read. **The running
app is the reference.** The PRD is historical (operator, 30 Sep), so nothing here is
judged against it. Order is the operator's: motion and illustration first, logic bugs
and quality of life second.

Evidence: release APK built 30 Sep 12:34, `emulator-5554` (1080 × 2400). Every row is
marked **seen** (on the emulator, with a capture), **code** (read in source, not
toured), or **Codex** (Codex's tour, not re-checked). The planner server was down, so
generation was only seen up to its failure state.

## Diagnosis in one line

The app animates things **appearing** and almost nothing **changing**, and it has almost
no artwork beyond destination pictures. Entrances exist (screens, cards, answer rows,
onboarding car, Loading car, press scale). Explore has no motion at all. No map camera
ever moves. Removing, skipping, restoring or reordering a stop happens instantly. No
image travels from list to detail. The only scene-type art is the dark onboarding
backdrop.

## Priority 1a — Motion

| # | Gap | Evidence | Direction |
|---|---|---|---|
| M1 | **Route does not draw itself.** Result opens with the whole polyline and every pin already there, and Loading cuts straight to it. This is the product's "your trip is ready" moment | seen `10-result-meta.png`; code: no reveal in `result_screen.dart` | On arrival from Loading or Saved, draw the polyline along the route and drop the pins in order, then settle the sheet. Skip it when reduced motion is on |
| M2 | **Map camera never moves.** Selecting a place on Explore does not pan to it. Result does not refit when the sheet rises: at the top anchor, pins 5–7 are hidden under the sheet | seen `12-explore-card.png`; Result at the top anchor (capture not kept); code: no animated `move`/`fitCamera` | Animated camera moves: to the selected place on Explore, and refit to the visible strip when the Result sheet snaps. Custom tween on `MapController`, no new package |
| M3 | **Stop list changes are instant.** Remove, skip, restore and reorder snap with no transition, so the user cannot see what changed | code: `result_stop_list.dart` has only an arrival entrance | Animate the list: collapse on remove, fade to skipped, expand on restore, and move matching pins on the map at the same time |
| M4 | **No shared element.** A stop's picture on Result and the hero on Stop detail are separate. Opening a stop is a generic fade | code: no `Hero` anywhere | Picture flies from the card into the detail hero, and back on return |
| M5 | **Explore has no feedback.** A selected marker only swaps to a filled dot, and the place card appears and disappears with no motion | seen `12-explore-card.png`; code: no animation in `explore/` | Marker scale/pulse on select; card slides up and swaps content with a short crossfade |
| M6 | **Onboarding backdrop does not follow progress.** The car moves along the top bar, but the dotted route on the map behind never changes | seen `17-onboarding-step.png`, `18-question-transition-frames.png` | Reveal the backdrop route in step with progress, so the car's journey reads across the whole screen |
| M7 | **Loading shows the wrong trip.** The user picked Darwin → Katherine (Top End), but the car drives the fixed Darwin → Uluru route | seen `15-loading-seed-route.png` | Draw the chosen region and endpoints. Logic and motion in one (also B4) |
| M8 | **No haptics.** Nothing buzzes on answer select, swipe-delete, sheet snap or skip | code: no `HapticFeedback` | Light haptic on those four moments |

Kept from Codex: motion should connect related elements, stay short, and never block
the primary action. Dropped: extra entrance choreography. The app already has enough
entrances, and D18/Task-52 showed that more entrances do not fix the look.

## Priority 1b — Illustration

| # | Gap | Evidence | Direction |
|---|---|---|---|
| I1 | **Empty Plan AI is an icon in a black void** | seen `05-plan-empty.png` | "Start a trip" scene above the message (Task-53 composition, then final art) |
| I2 | **Welcome is a small card over a near-invisible map** | Codex `08-welcome-illustration.png` | One strong road-trip scene with the title, and the card no longer floating in the dark |
| I3 | **Onboarding backdrop is so dark it reads as texture.** 15 steps pass with no visible place | seen `17-onboarding-step.png` | Brighter, recognisable NT scene behind the card, or a scene per section (trip facts / style / comfort). Not one per question |
| I4 | **Region choice has no picture** | Codex | Top End and Red Centre scenes on the region question. The same art becomes route covers (I5) |
| I5 | **Saved covers repeat.** "Top End" and "Full NT" both show the Darwin sunset | seen `09-saved-meta.png` | Regional cover per route, wider crop |
| I6 | **Failure state has no identity.** "Couldn't reach the planner" uses the small route glyph | seen `15-loading-seed-route.png` | "No signal" scene: this is the app's premise, and the screen a user in the outback will actually see |
| I7 | **Explore markers are anonymous coloured rings** | seen `01-explore.png` | Category icon (existing Lucide set) inside each marker. Icon work, no new art |
| I8 | **Three unrelated styles.** Detailed car sprite, glowing brand mark, painted destinations | Codex, and asset read | New scenes follow the **painted destination style**, which is already the strongest art in the app. Four base scenes: start a trip, Top End, Red Centre, prepare the route (from Codex) |

Asset route: Codex `gpt-image-2` image bees. They need `danger-full-access`, which the
operator approves once before the first image. The existing destination pictures are
the style reference.

## Priority 2a — Logic bugs

| # | Bug | Evidence | Fix direction |
|---|---|---|---|
| B1 | **Back on Result leaves the app.** Opening a route from Saved Routes and pressing Back exits to the Android launcher, twice. Result after a successful generation was not reached | seen: `dumpsys` shows the launcher on top after Back | Back returns to where the user came from (Saved Routes). Check the generated path too once the planner runs |
| B2 | **Wrong day count.** Saved lists "Full NT — 8 days", Result shows "7 days". The header takes days from the last onboarding answer, not from the route | seen `09-saved-meta.png`, `10-result-meta.png`; code `result_screen.dart:237` | The route carries its own day count; its absence in old data falls back to the stored meta line |
| B3 | **Map fit crops pins.** On Red Centre, stop 1 hides under stop 2 at the right edge and stop 4 touches the left edge | seen `14-red-centre-fit.png` | Fit with marker-radius padding, and fan out pins that overlap |
| B4 | **Loading draws the wrong route** (as M7) | seen `15-loading-seed-route.png` | — |
| B5 | **Offline Maps does nothing.** "Download maps for areas with no signal" is a switch that only flips a flag, and the flag resets on launch | seen `11-profile-offline.png`; code `profile_screen.dart:149` | Remove the row (and its state), or make it true later as its own feature |
| B6 | **"Generated just now" is permanent** | code `loading_screen.dart:186` | Label that stays true, e.g. "Your latest plan" |
| B7 | **"Next" jumps between steps.** The card is centred and its height changes, so the button moves under the thumb every question (a scripted tap missed because of it) | seen, `18-question-transition-frames.png` | Pin the step's primary button in a fixed footer position |
| B8 | **Off-road 4x4 question after "Standard Car"** | code `onboarding_steps.dart:98`; Codex | Skip or reword it when the vehicle is not a 4x4. The planner request keeps a sensible default |
| B9 | **Stop detail hours wrap badly.** The right-aligned value breaks into four ragged lines | seen `16-stop-hours.png` | Left-aligned label/value block |
| B10 | **Slider speaks "46%".** TalkBack reads the trip-length slider as a percentage, not "7 days" | seen: `uiautomator` dump | Semantic value = the readout text |

## Priority 2b — Quality of life

| # | Improvement | Evidence | Direction |
|---|---|---|---|
| Q1 | **Planner down means a dead end**, in an app whose premise is no signal | seen `15-loading-seed-route.png` | Offer the closest built-in route for the chosen region ("Use an offline route"), since the data is already on the device |
| Q2 | **Explore place card goes nowhere.** Tapping it does nothing | seen `12-explore-card.png` | "Navigate" (Google Maps, the same as Stop detail), later "Add to my trip" |
| Q3 | **Search with one match does nothing more.** "uluru" leaves one unselected ring at the bottom edge | seen `13-explore-search.png` | A single match auto-selects and the camera flies to it (M2) |
| Q4 | **Empty Plan AI ignores saved routes** even when some exist | seen | Secondary "Open a saved route" when the list is not empty |
| Q5 | **Dim secondary text**: tab labels, saved dates, slider end labels, "Select all that apply" at 3.2–3.3:1 | computed from tokens | Brighter existing ink token (Task-54) |
| Q6 | **Heat answer as big as the question** | Codex `04-heat-question.png` | Smaller role for sentence answers (Task-54) |
| Q7 | **Region labels need examples**: "Top End — Darwin, Kakadu…" | Codex | With I4 |
| Q8 | **Two accommodation questions** (7 and 12) overlap | Codex | Merge after checking the planner prompt uses both |

**Not recommended:** auto-advance on single-choice answers. It was built and removed
on 11 Sep, because the screen moved under a user still reading the options.

## Where the existing tasks stand

- **Task-53** (Welcome and empty Plan AI composition) covers I1 and I2. Keep it.
- **Task-54** (readable text and heat readout) covers Q5 and Q6. Keep it and add the slider
  end labels and the multi-select subtitle.
- Both are written for the `ultracode` engine. The next run uses Codex, so their
  `Execution` lines change at plan time.

## Suggested waves (for `plan-wave`, two tasks each, disjoint files)

1. **Motion core:** M1 (route draws itself) + M2/M5 (camera and Explore feedback).
2. **Logic:** B1 (Back) + B2/B3 (day count, map fit).
3. **Art wave 1:** Task-53 composition with generated scenes (I1, I2, I8) + I4/Q7 (region scenes and examples).
4. **List motion and detail:** M3 + M4 (+ M8 haptics).
5. **Honesty and flow:** B5, B6, B7, B8 + Q1.
6. **Readability:** Task-54, then B9, B10, Q2, Q3.

The eye check after each wave is the operator's. Visual items stay judged by eye, never
as machine gates or golden tests.
