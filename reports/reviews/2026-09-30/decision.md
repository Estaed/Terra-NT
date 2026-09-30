# Terra NT review decisions — 30 September 2026

One page that says which recommendations from `review.md` and
`illustration-review.md` get built, which wait, and which are dropped, plus what a
second emulator tour found. Written by the main loop. Nothing here changes the PRD,
Blueprint or task files. Those stay the operator's call.

Evidence: release APK built 30 Sep 12:34 on `emulator-5554`. Claims were checked
in code, and contrast ratios were computed from the token hex values.

## Decision table

| # | Recommendation (source) | Decision | Where |
|---|---|---|---|
| 1 | Brighter enabled tab labels and saved dates. Checked: `inkTertiary` on `surface1` is 3.30:1 and `inkSubtle` is 5.86:1 (review) | **Do** | Task-54 |
| 2 | Heat answer in a smaller role, days keep the big readout (review) | **Do** | Task-54 |
| 3 | Readable schedule time column (review) | **Do** | Task-54 |
| 4 | Welcome and empty Plan AI get an image, message and action composition from existing art. Confirmed: empty Plan AI is a small icon in a black screen (illustration) | **Do** | Task-53 |
| 5 | Remove the "Offline Maps — Download maps…" promise. Confirmed: `profile_screen.dart:149-151`, and PRD §3.9 says the toggle downloads nothing and resets on launch (review) | **Do**, by deleting the row | Task-55 (new) |
| 6 | Region options get examples: "Top End — Darwin, Kakadu…" (review) | **Do, later.** It is UI only, because the request carries keys and not labels. It pairs with the region artwork | Wave 3 |
| 7 | Skip the 4x4 off-road question when the vehicle is not a 4x4 (review) | **Later.** It changes `canNext` and request completeness, so the backend owner has to agree first | After v1 |
| 8 | Merge the two accommodation questions (review) | **Later**, same reason as #7 | After v1 |
| 9 | Regroup the 15 questions and move endpoints first (review) | **No for now.** Task-52 has just settled the endpoints, and "Back returns to step 14" is written into the PRD | After v1 |
| 10 | Explore: labels, marker clustering, a different tile style (review) | **Later.** Tiles are a CARTO decision, and clustering is new code for 15 pins | After v1 |
| 11 | More useful route panel at the middle height (review) | **Later.** The 190 / 430 / 700 anchors are spec | After v1 |
| 12 | Bigger Saved thumbnails or regional covers (both) | **Later**, with the artwork | Wave 3 |
| 13 | Motion linking pin → card → detail (review) | **No.** D18 and Task-52 already added motion, and `notes.md` warns against solving this with more motion | — |
| 14 | Four-scene illustration family (illustration) | **Later.** Only after the Task-53 composition review shows where the scenes go | Wave 3 |
| 15 | A scene for each onboarding section, and Profile artwork (illustration) | **No.** It is decoration and does not help the user decide anything | — |

## New findings from the second tour

**A. Result shows the wrong day count for a saved route (bug, P1).**
Saved Routes lists "Full NT: Darwin to Uluru — 8 days · 7 stops". Opening that
route shows "7 days · 7 stops" (`09-saved-meta.png`, `10-result-meta.png`).
Cause: `result_screen.dart:237` builds the header from `answers.days`, which is the
onboarding answer (default 7), not the opened route. PRD §3.6 / V2 promises this
meta "always agrees with the Saved Routes entry", so the build breaks its own
contract. The code implies a worse case that was not toured: plan a 3-day trip and
then open "7 Days in the Red Centre", and the header reads "3 days · 4 stops".
Fixing it needs the day count to travel with the route. Saved routes only store
`meta` as a display string, so this is a data-contract decision. One way that
keeps old data valid: make `days` an optional field on the saved route. An entry
without it shows its stored `meta` word for word and never falls back to the seed.

**B. "Generated just now" stays forever (P2).** `loading_screen.dart:186` saves that
label, and a week later it still says "just now". The Blueprint forbids clock-derived
dates, so the fix is copy rather than a timestamp. The generated route always upserts
under `generated-trip`, so it is always the latest plan, and a label such as
"Your latest plan" stays true. That label needs a V-row.

**C. Secondary text is also dim inside onboarding (P2).** The slider end labels
and "Select all that apply" use `inkTertiary` on `surface2`, which is 3.17:1. Both
sit in `onboarding_steps.dart`, which Task-54 already owns. Add them to Task-54's
goal.

**D. The Explore place card is a dead end (after v1).** Tapping the card does nothing
(`12-explore-card.png`). That matches the spec, since Explore is read-only per §3.5.
A "Navigate" action would reuse Stop detail's D7 URL and would not add a POI to the
route, so it stays outside §8. It is a cheap candidate.

**E. Search does not act on a single match (after v1).** Typing "uluru" leaves one
unselected ring at the bottom edge of the map, right above the nav bar
(`13-explore-search.png`). That matches Q6. Selecting a single match automatically
would be the next step.

## Recommended order

1. **Task-53 and Task-54 as written.** Add finding C to Task-54's goal. Stop for the
   operator's emulator review, as D20 already says.
2. **Task-55, correctness and honesty:** finding A (the operator first decides how
   `days` travels with a route), finding B, and removing the Offline Maps row
   (#5), including its notifier state and tests. Its test file overlaps Task-54
   (`result_screen_test.dart`), so it runs after Task-54, never alongside it.
3. **Wave 3, after the composition review:** the four scenes (#14), region
   examples and covers (#6, #12).
4. Everything marked "After v1" goes to `notes.md` → *After v1*, ordered: A-style
   bugs first, then #7/#8 with the backend owner, then Explore (#10, D, E).

Only finding A needs an operator decision before any code: how a saved route
carries its day count.
