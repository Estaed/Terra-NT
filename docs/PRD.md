# PRD — Terra NT Route Planner

**Status:** written 2026-08-25 from the prototype in `design/`. Answers *what* and *why*.
The *how* — stack, folder layout, packages, state management — belongs in
`CLAUDE.md` → Blueprint, which is written from this document and is still a placeholder.

---

## 1. Purpose & target user

A phone app for planning a multi-stop road trip through Australia's Northern Territory.

The user answers a short series of questions about how they travel, receives a
day-by-day itinerary plotted on a map, then adjusts it — reorder stops, drop the ones
they don't want, skip ones they'll pass through — and exports the result to Google Maps
to actually drive it.

**Target user:** a traveller planning an NT road trip who does not know the Territory
well enough to sequence it themselves. The NT's specific problems are the reason the app
exists: distances are enormous (one leg in the seeded route is 670 km / 7 hours), heat
and seasonal closures gate what's open, some routes need a 4x4, and long stretches have
no phone signal. Five of the fifteen onboarding questions are NT-specific for exactly
this reason (`Terra NT.dc.html` lines 277–377).

**Why it's worth building:** general trip planners return a list of places. The value
here is *ordering and pacing* — putting Litchfield before Kakadu because it's the easier
first stop, keeping Nitmiluk light because a 7-hour drive follows it. That reasoning is
visible in the seeded `aiNote` on every stop and is the product's actual output.

---

## 2. Design sources of truth

Every screen below names the file and line range that specifies it. **Where this document
and a design file disagree, the design file wins** — except for the deviations recorded in
§7, which are deliberate and reasoned.

| File | What it settles |
|---|---|
| [design/design-reference/Terra NT.dc.html](../design/design-reference/Terra%20NT.dc.html) | All 9 screens, all copy, all layout, all state transitions. Markup lines 34–690; logic lines 691–1310. |
| [design/design-reference/terra-nt-bg-map.html](../design/design-reference/terra-nt-bg-map.html) | Login ambient map + onboarding progress map, and the arc-length car animation (lines 89–165). |
| [design/design-reference/terra-nt-explore-map.html](../design/design-reference/terra-nt-explore-map.html) | Explore map, the 8 POI marker coordinates, marker selection. |
| [design/design-reference/terra-nt-map.html](../design/design-reference/terra-nt-map.html) | Result-screen numbered pins, dashed route line, camera fit. |
| [design/design-system/tokens/](../design/design-system/tokens/) | Every colour, type role, space, radius, elevation and duration, by token name. |
| [design/design-system/README.md](../design/design-system/README.md) | **Read before using the tokens.** Only `tokens/` transfers to this app; the upstream component inventory and desktop breakpoints describe a different product. |

### Fidelity

High. The tokens are real values, not placeholders. Reference them **by token name** —
`--color-surface-1`, `--radius-card`, `--duration-base` — never by hex or pixel literal.
A visual difference from the prototype is a bug, not a variation.

### Three gaps in the design sources — read before starting

These are real and unresolved; they are not oversights in this document.

1. **No rendered design source — partially eased 2026-08-26.** `design/screenshots/` was
   deleted from the working tree and stays deleted (§9 Q1). The prototype's own markup
   remains the only *authoritative* reference for every screen. Ten advisory captures now
   sit in `docs/screenshots/` for eyeballing a build against; they cover the main screens
   in their default states only, they carry the prototype's own defects, and no acceptance
   criterion may cite one. See `docs/screenshots/README.md`.
2. **The prototype does not render.** `Terra NT.dc.html` loads `./support.js` and
   `_ds/…/_ds_bundle.js`; neither is in the repo. The file can be *read*, not *run*.
3. **Component styling is not recoverable.** `Button`, `TextInput` and `Icon` come from
   that missing bundle (14, 2 and 41 usages). Their variants — `primary`/`secondary`,
   `size="lg"` — resolve to nothing on disk. Rebuild them from the raw tokens: button
   padding 8×14px, input padding 8×12px, `--radius-md` 8px, primary fill
   `--action-primary-bg`, secondary `--action-secondary-bg` over `--border-card`.

Together these mean **visual fidelity cannot be verified mechanically** in this repo. It
can now be *reviewed* by eye against `docs/screenshots/`, which is a weaker thing: a human
judgement, on partial coverage, against a source with known defects. See §9, open
question 1.

---

## 3. Screens

Nine screens plus a persistent bottom nav. All nine are v1.

### 3.1 Login — `Terra NT.dc.html` L46–69

Full-bleed dark map backdrop with an ambient looping car animation, bottom-to-top gradient
scrim, 44px "Terra NT" headline, "Discover the Northern Territory." subhead, email and
password fields, primary "Start Exploring", "or" divider, secondary "Continue with Google".

The backdrop is **decorative**: `terra-nt-bg-map.html?auto=1` with dragging, zoom, keyboard
and tap all disabled (L40–41 of that file). The car drives the full route, pauses 1.4 s,
and reverses, forever (L155–165).

The car **travels along the polyline through every intermediate stop** — never a straight
chord between endpoints. The sampler walks a cumulative-distance table
(`terra-nt-bg-map.html` L89–110); animation duration is `700 + span × 3500` ms, eased
`1 - (1-t)³`. This is the only screen the backdrop is on: onboarding lost it to V13, and
Welcome and Create account repeat this one.

- Email and password are **validated** — format check, primary CTA disabled until valid,
  inline error copy. *(Decision D4; the prototype validates nothing.)*
- "Continue with Google" is a **mock in v1** — it behaves identically to "Start
  Exploring", exactly as the prototype has it. Real Google Sign-In lands in phase 2.
  *(Decision D5, revised 2026-08-25.)*
- Both paths land on Welcome.
- The email in the session is what Profile displays, falling back to `explorer@example.com`.
- No bottom nav here.
- **Password reset — phase 2 (D13, 2026-09-22), no design source.** A second text link
  in the same style as the sign-up link, directly under it: leading "Forgot your
  password? ", trailing "Reset it". Tapping it with an empty or malformed email shows
  `Enter your email to reset your password.` in the email field's error slot and sends
  nothing. Otherwise it sends the reset email through the auth seam and replaces the
  link with one muted caption line, `Check your email for a reset link.` — the same line
  whether or not an account exists for that email, so the screen never says which emails
  are registered. A `network` failure shows Task-24's network copy in the password slot;
  anything else shows Task-24's unknown copy. The link is disabled while the call is in
  flight.

### 3.1a Create account — no design source

Added **2026-09-10** by operator decision (D11); §8 previously excluded sign-up because the
prototype has none. The screen repeats Login's backdrop, scrim, padding and vertical
distribution exactly, so it inherits Login's design source; only its content is new.

- Header "Create account" over "Start exploring the Northern Territory."
- Email, Password and Confirm password fields; primary "Create Account"; a centred
  "Already have an account? Sign in" link back to Login.
- Login carries the matching "Don't have an account? Sign up" link below "Continue with
  Google".
- Validation follows Q5's rules — submit-time only, focus the first failing field — with two
  new strings: `Enter a password.` and `Passwords do not match.`, plus `Confirm your
  password.` for an empty confirmation. **No length or strength rule**, for Q5's own reason:
  auth is mocked, so the rule would describe a check that does not run.
- Success lands on Welcome, like both Login paths. The typed email becomes the session email.
- **No account is stored.** Phase 1 has no backend and exactly three persistence keys (D3), so
  `AuthRepository.createAccount` sets the session and nothing else. Real accounts are phase 2.
- No "Continue with Google" here, and no bottom nav.

### 3.2 Welcome — `Terra NT.dc.html` L70–86

Same backdrop, flat `rgba(1,1,2,0.42)` scrim. One card: "Welcome to Terra NT" over
"Answer a few quick questions and we'll build a route across the Territory for you — or
skip straight to exploring on your own." Two full-width buttons.

- "Create My Route" → Onboarding step 1 of 15.
- "Skip for Now" → marks onboarding done, lands on Explore. No route is generated and
  none is saved.
- No bottom nav.

### 3.3 Onboarding — `Terra NT.dc.html` L87–377, logic L918–948

Fifteen steps, strictly linear, on a flat `--canvas` background. Top bar: back button,
pill progress bar, "n/15" counter. The step card slides in from `translateX(18px)` over
320 ms.

There is no map behind the questions *(deviation V13)*. The car drives the progress bar
instead: the bar is the road, the fill grows to the step's percentage, and the car rides
the fill's leading edge, facing the direction of travel — so going back drives it in
reverse. The fill and the car ease together with the step card's curve over its 320 ms,
which is the only timing onboarding now has.

| # | Question | Type | Gate |
|---|---|---|---|
| 0 | Which age range are you in? | single-select | required |
| 1 | How many days is your trip? | slider 1–14, default 7 | none |
| 2 | Who are you traveling with? | single-select | required |
| 3 | What's the main focus of this trip? | **multi-select**, manual Next | ≥1 |
| 4 | What are you traveling in? | single-select | required |
| 5 | What's your budget? | single-select | required |
| 6 | Where do you want to stay? | single-select | required |
| 7 | What's your physical activity level? | single-select | required |
| 8 | Which region do you want to focus on? | single-select | required |
| 9 | How confident are you driving a 4x4 off-road? | single-select | required |
| 10 | How well do you handle extreme heat? | slider 1–5, default 3 | none |
| 11 | Camping under the stars, or resort comfort? | single-select | required |
| 12 | How interested are you in spotting wildlife? | single-select | required |
| 13 | Comfortable in remote areas with no phone signal? | yes/no, manual | required |
| 14 | Where does your trip start and end? | two endpoint menus, manual Next (D19) | both required |

Option labels are in the render block, L1226–1249. Behaviour:

- **Every step advances on Next only.** A pick records the answer and nothing else; no
  step schedules its own advance *(deviation V12)*.
- Progress bar fills to `round(((step + 1) / 15) × 100)`%; counter shows `step + 1`.
- An **"NT-specific"** pill sits above the question on **steps 9–13** — the five
  NT-specific questions; the start/end step that follows them carries no pill.
- The step-10 slider shows a text label per notch, from the 5 seeded strings (L799).
- Step 14's button reads "Generate My Route" instead of "Next".
- D19 (2026-09-30): Start and End each offer Darwin, Jabiru, Katherine, Alice Springs
  and Uluru, names already represented in the seed itinerary. Neither has a default;
  equal endpoints allow a round trip. Existing answers survive Back, including an
  earlier free-text answer. The request still sends the same two location strings.
- Back from step 0 leaves onboarding for Login, skipping Welcome (L938). See §9, Q4.
- Answers survive back-navigation — going back and forward again preserves what was picked.
- Completing step 14 → Loading.
- No bottom nav.

### 3.4 Loading — `Terra NT.dc.html` L378–384, logic L860–875

A 64px `--color-primary` circle pulsing scale 1→1.4 / opacity 0.9→0.3 on a 1.6 s loop,
under a status line rotating every 1400 ms through five seeded messages (L798).

- Runs **7000 ms** so all five messages get one full turn. *(Deviation V1 — the prototype
  navigates at 5600 ms and never shows "Routing...".)*
- On completion: flags onboarding done, upserts the generated route into Saved Routes
  under the stable id `generated-trip`, and lands on Result. Re-running onboarding
  updates that one entry rather than adding a second (L1022–1030).
- Non-interruptible: no back, no cancel, no bottom nav. Leaving early must cancel the
  pending navigation and the save. **Phase 1 only** — superseded below.

**Phase 3 (D14, 2026-09-22; deviation V18).** Generation is a network round trip
(`docs/PHASE-3-CONTRACT.md`), so Loading gains what a fixed delay never needed. No
design file has this state; it is built from the existing tokens, the Loading layout and
the button styles already on screen. P6 answered.

- **In flight:** the disc, the rotating messages and the progress pill are unchanged.
  The messages keep rotating past 7000 ms — the last message stays until the response
  arrives; the screen does not stall or navigate on a timer. A **Cancel** text button
  sits under the progress pill; tapping it discards whatever comes back, saves nothing,
  and returns to onboarding at step 14 with the answers intact. *Amended 2026-09-23
  (operator decision after the device tour):* the system Back gesture is Cancel, in
  flight and on the failure state alike; before this it left the app while the request
  kept running, and the late response saved a route.
- **Success:** as phase 1 — flag onboarding done, upsert `generated-trip`, land on
  Result — with the returned itinerary set as the current one. The upsert happens only
  after a successful response; **a failed generation leaves no saved route behind.**
- **Failure:** the status line and the progress pill are replaced by a title line
  (`AppType.titleApp`), a body line (`inkSubtle`) and one or two buttons (primary +
  secondary, existing `AppButton` variants). The disc stops pulsing. Copy is binding,
  sentence case, character for character:

  | `PlanFailure` | Title | Body | Buttons |
  |---|---|---|---|
  | `network`, `timeout`, `serverError`, `rateLimited`, `invalidResponse` | `Couldn't reach the planner.` | `Check your signal and try again.` | primary `Try again` · secondary `Back` |
  | `cannotPlan` | `We couldn't plan this trip.` | `Try a different region, vehicle or trip length.` | primary `Change answers` |
  | `unauthorised` | `Your session has expired.` | `Sign in again to plan a trip.` | primary `Sign in` |

  `Try again` re-sends the same request (same `requestId`) and returns to the in-flight
  state. `Back` and `Change answers` return to onboarding step 14. `Sign in` signs out
  through the session notifier and lands on Login.
- **Cold start never blocks on this:** Loading is reached only from onboarding.
- When `PLAN_API_URL` is not configured the seeded repository answers as in phase 1 and
  none of the failure states can occur; Cancel still works.

### 3.5 Explore — `Terra NT.dc.html` L385–418, map in `terra-nt-explore-map.html`

Full-bleed **interactive** map (pan and zoom enabled, unlike the Login backdrop) with the
8 seeded POI markers, OpenStreetMap/CARTO attribution visible.

- Floating search pill, 20px from top/left/right, is a **working search** filtering the 8
  seeded POIs. *(Decision D6; the prototype's is a static `<span>`.)* Placeholder copy
  stays "Search the Territory".
- Tapping a marker opens the bottom info card; tapping another swaps its content; the X
  closes it and clears the selection.
- The card shows a 76px placeholder tile, name, star rating, a category tag with a
  coloured dot, and the description.
- Tag → dot colour: Nature → `--tag-green`, Culture → `--tag-purple`, Adventure →
  `--tag-orange`, Wildlife → `--tag-blue`, Relaxation → `--tag-yellow`; anything
  unrecognised falls back to `--color-ink-tertiary` (L797).
- Explore is **read-only browsing** — no way to add a POI to the route.
- Bottom nav visible, Explore active.

### 3.6 Plan AI result — `Terra NT.dc.html` L419–523, map in `terra-nt-map.html`

Route map on top, draggable sheet below.

**Map:** numbered pins in current order joined by a dashed `--color-primary` polyline,
pan and zoom enabled. Pins **track the live list** — reordering renumbers them, removing
a stop removes its pin. *(Deviation V5.)*

**Sheet:** the nominal anchors remain 190 / 430 / 700px, with ties resolving to the lower
value (L974–984). On a phone whose usable height after system insets is below 700px, the
top anchor and drag ceiling clamp to that usable height; lower anchors that still fit do
not move.

Contents, in order:

1. Trip title and meta. Meta is **derived** — current stop count and the `days` answer —
   so it always agrees with the Saved Routes entry. *(Deviation V2.)* A **"Plan again"**
   action sits on the title row: it clears the onboarding answers and the session-only
   itinerary edits, then returns to onboarding step 0. When there are unsaved edits — the
   order differs from the AI's, or something has been removed or skipped — it first raises
   the inline confirmation "Discard edits and plan again?" with "Plan again" / "Cancel",
   in the shape Profile's delete-account confirmation uses. Never a dialog.
2. Segmented control, Highlights / Detailed. Highlights shows one AI-note line per stop;
   Detailed shows that stop's hour-by-hour schedule — or, when a stop's plan is empty
   (phase 3, D14), one `inkTertiary` line `No detailed plan for this stop.` in the
   schedule's place. The value is **Result-local and defaults to Highlights**: onboarding no longer asks how detailed the plan should be
   (V11), and the choice is a way of reading this screen rather than a property of the
   trip, so it is session-only and nothing persists it.
3. "Edit Route" toggle — flips to "Done", icon `Pencil` → `Check`.
4. Primary "Export to Google Maps".
5. "Restore N removed stop(s)" — shown only when something has been removed, singular at N=1.
6. Scrollable stop list. **View mode:** chevron, tap opens Stop detail. **Edit mode:**
   entering it snaps the sheet to the 700px anchor and the rows go compact — badge, name,
   revert when that stop has moved, remove, drag handle, on one 56px line; tapping the row
   does not navigate. Both are load-bearing, not cosmetic: a reorder drag can only
   auto-scroll while the dragged row is shorter than the list viewport
   (`docs/DEVICE-TOUR.md`).

**The two restore controls are scoped, not identical** *(Deviation V3 — in the prototype
both call the same full reset)*:

- The **per-row revert icon** moves that one stop to its original index, clamped to the
  current list length. Other present stops may shift by one as a consequence, but their
  relative order is preserved; removed stops stay removed. It appears only when that stop
  has moved.
- **"Restore N removed stops"** re-inserts every removed stop at its original index while
  preserving manual reordering of stops that were never removed.

Drive-time copy is truthful about phase 1's fixed data. A stop shows its seeded
`driveNext` only while its original successor in the **currently opened itinerary** is
still immediately next. A reordered or removal-created leg shows `Drive time unavailable`
instead of a stale estimate; the current last stop shows no next-leg line. The baseline is
the opened itinerary, so the four-stop Red Centre route uses its own recomputed legs.

**Export** builds
`https://www.google.com/maps/dir/?api=1&origin=<lat,lng>&destination=<lat,lng>&travelmode=driving`,
appending `&waypoints=` joined by `|` for intermediate stops, URL-encoded, in current
order; it no-ops below 2 stops (L1005–1015). **Skipped stops are excluded from the
export** *(Deviation V4)*.

**Skipping ≠ removing.** A skipped stop stays in the list at 0.5 opacity with a "Skipped"
marker; a removed stop leaves the list. The two states are independent.

Bottom nav visible, Plan AI active.

### 3.7 Stop detail — `Terra NT.dc.html` L524–572

260px full-bleed placeholder hero with the back button overlaid. Name, subtitle, tag
chips, an info card with hours and — only when the stop has one — a park fee row, then a
`Zap`-icon AI-note callout. Footer: secondary "Skip"/"Unskip" and primary "Navigate".

- Skip/Unskip toggles the flag and returns immediately to Result, where the stop is now
  at 0.5 opacity. The state survives leaving and re-entering.
- **"Navigate" launches a single-destination Google Maps URL** for that stop.
  *(Decision D7; the prototype's button has no handler.)*
- Pushed on top of the Plan AI tab's stack — no bottom nav.

### 3.8 Saved Routes — `Terra NT.dc.html` L573–612, logic L1032–1064

List of route cards: placeholder thumbnail, title, meta, relative date, chevron.

**Swipe-to-delete:** horizontal drag clamped to −76…0px, revealing a red delete button
pinned behind the row. On release it snaps open past −38px and closed at or before it.
Only one row is open at a time. Tapping an open row closes it instead of navigating; a
tap following a drag of more than 4px doesn't navigate either. Tapping the red button
deletes immediately — no confirmation, no undo.

- A closed row opens that route on the Result screen.
- **"7 Days in the Red Centre" opens its own 4-stop itinerary**, matching its meta line.
  *(Decision D8; the prototype opens the same 7 stops for both rows.)* See §9, Q3.
- Empty state: `Bookmark` icon, "No saved routes yet", "Generate an itinerary with Plan AI
  and it'll show up here.", and a "Plan Your First Route" button switching to Plan AI.
- Bottom nav visible, Saved Routes active.

### 3.9 Profile — `Terra NT.dc.html` L613–675

Account row (avatar, "NT Explorer", session email, chevron) → **Account screen**. Offline
Maps toggle row with "Download maps for areas with no signal". Language row showing
"English" → **Language screen**. "Log Out" row in `--tag-red`. Then a flexible spacer and
a small, muted, centred "Delete account" caption link — deliberately low-prominence, no
card, no icon.

- Tapping "Delete account" swaps that link **in place** for an inline confirm card reading
  "Delete your account and all saved routes? This can't be undone." with Cancel and
  Delete account. It must not navigate away or open a dialog or sheet.
- Cancel returns to the idle link. Confirm returns to Login and clears email, password,
  the onboarding-done flag, **and saved routes to a genuinely empty list**.
  *(Deviation V6 — the prototype resets saved routes to `null`, which falls back to the
  seed and resurrects the two demo routes.)*
- Log Out returns to Login and clears email and password only. Saved routes and the
  onboarding-done flag survive.
- The Offline Maps toggle is session state and downloads nothing.
- Bottom nav visible, Profile active.
- **Crash reports — phase 2 (D13, 2026-09-22).** A read-only row after Language, in the
  same row pattern, label `Crash reports`, value line `Sent anonymously to fix bugs.`
  No toggle: the app has no settings surface for one (§8), and the row is the privacy
  disclosure Crashlytics needs. No chevron.
- **Delete account, phase 2 order:** the saved routes are removed from the account's
  cloud copy first (while still signed in — the security rules refuse afterwards), then
  the account is deleted, then the local copy is cleared. A failure at the first step
  shows the existing network or unknown copy and changes nothing.

### 3.10 Account and Language — no design source

Both are **new**, added because their rows now honour their chevrons *(Decision D9)*.
Build them from existing row patterns and tokens; invent no new visual language.

- **Account:** read-only rows — avatar, display name, email — plus a back button. No editing.
  **Phase 2 (D13, 2026-09-22):** one more row, label `Email verification`, value
  `Verified` or `Not verified`, and when not verified a text button `Resend email` in
  the existing text-button style beneath the value. `Resend email` sends the verification
  mail through the auth seam and swaps itself for the muted caption `Verification email
  sent.`; a failure shows Task-24's network or unknown copy in that caption's place.
  **2026-09-23 (D15, Task-44):** while the read is pending the value line reads
  `Checking…`; it empties if the read throws. An
  unverified account **may plan and save routes** — the app's premise is no signal, and
  gating on a verification round trip would block the product on the network. Create
  account sends the verification email once, best-effort, and ignores its failure.
- **Language:** single-select list with English as the only entry, checked. No i18n
  machinery, no second language.

### 3.11 Bottom nav — `Terra NT.dc.html` L676–690

Four tabs: Explore/`Compass`, Plan AI/`Sparkles`, Saved Routes/`Bookmark`, Profile/`User`.
64px tall, `--color-surface-1`, 1px hairline top border, equal widths, 20px icon over an
11px caption. Active tab in full ink, the rest `--color-ink-tertiary`.

- Present on Explore, Result, Saved Routes and Profile. Absent on Login, Welcome,
  Onboarding, Loading, Stop detail, Account and Language.
- Stop detail keeps Plan AI conceptually active while hiding the bar.
- The Plan AI tab opens Result when onboarding is done, Login when it is not (L887).
- Each tab keeps its own navigation stack across switches.

---

## 4. What the user's data looks like

Plain terms — field names and types are Blueprint's business.

**A stop** has a name, a one-line subtitle, a map position, opening hours, an optional
park fee, a duration ("1 day", "2 days"), an optional drive label to the next stop (absent
on the last), one AI note explaining why it's placed there, one or more category tags, and
an hour-by-hour plan of times and activities. Seven are seeded — Darwin → Litchfield →
Kakadu → Nitmiluk → Alice Springs → Kings Canyon → Uluru-Kata Tjuta — with full copy at
`Terra NT.dc.html` L693–784, to be carried over verbatim.

**A POI** has a name, a category tag, a rating and a description. Eight are seeded. Note
their descriptive content is in `Terra NT.dc.html` L786–796 but their **map coordinates
are in `terra-nt-explore-map.html` L22–31, and deliberately differ** from the stop
coordinates — Ubirr sits at −12.4260, 132.9760 while the Kakadu stop is at −12.6692,
132.8352. The model is split across two files.

**A saved route** has a stable id, a title, a meta line and a relative date label.
Two are seeded (L803–806); the generated one upserts under `generated-trip`.

**Onboarding answers** are the fifteen values in the table above.

**Session** is the signed-in email and whether onboarding has been completed.

### What survives closing the app

Saved routes, the session, and the onboarding-done flag all persist across launches
*(Decision D3)*. Everything else — the current itinerary's ordering, skipped stops, edit
mode, sheet height, POI selection, the Offline Maps toggle — is session-only and resets.

A returning user therefore does **not** land on Login. That launch-routing behaviour has
no design in the prototype; see §9, Q2.

**Phase 2 (D13, 2026-09-22): a saved route carries its stops.** Phase 1 could look a
saved route's itinerary up by id because every itinerary was seeded; a generated one has
nowhere else to live. `SavedRoute` gains `stops`, the two seeded routes carry their
seeded stops, and `terra_nt.saved_routes` stores them. The signed-in account's routes
are also written to Firestore under the account and pulled onto a device that has no
local copy yet; the local copy stays the source of truth for rendering, offline or not.

---

## 5. Itinerary generation

v1 returns the **seeded 7 stops**, always, regardless of all fifteen answers. Loading is a
timed transition, not a request. There is no API call, no key, no network failure state.

**But generation must sit behind a replaceable boundary** *(Decision D2)*: the screens ask
for an itinerary and receive one; they must not reach into seed data directly. Swapping in
real generation later must not touch any screen.

This is the one place this PRD accepts an abstraction over a single implementation, against
`CLAUDE.md` rule 2, and the reason is explicit: the app's premise is AI-generated routing,
so that boundary is the seam the product is expected to grow along.

**Consequence to be honest about:** until that swap happens the fifteen questions are
collected, stored and displayed but do not change the output. Only the `days` answer and
the detail-level answer have any visible effect.

### 5.1 Delivery phases

Confirmed by the product owner on 2026-08-25. **The order is deliberate and is not a
suggestion** — each phase depends on the one before it.

| Phase | Scope | State |
|---|---|---|
| **1 — Foundation** | Everything in this PRD: all 9 screens, real navigation, local persistence, seeded itineraries, mocked auth. Product data and core flows are local with no cloud account; CARTO map tiles are the only network resource. | v1, what `generate-tasks` slices |
| **2 — Backend** | Firebase (or equivalent): real Google Sign-In, real accounts, saved routes moving off the device. | **Started 2026-09-22 (D12)** — accounts and Google Sign-In are Task-23…25 (DONE); wave 2 (D13, same day) is Firestore saved routes, password reset, email verification and Crashlytics |
| **3 — AI** | Real itinerary generation replacing the seeded implementation. The model is not ready yet. | **Started 2026-09-22 (D14)** — the app's two ends of the wire are specified in `docs/PHASE-3-CONTRACT.md`; the server and model are a teammate's deliverable |

Phases 2 and 3 are **out of scope for v1 but not cancelled**. This PRD's job is to make
them cheap to land later, which is why exactly two seams exist:

- **Generation** (§5) — screens ask for an itinerary, never for seed data.
- **Auth** — screens ask "who is signed in" and "sign in with Google", never for Firebase.

Both are declared in `CLAUDE.md` → Blueprint → Architecture. **No third seam is permitted.**
Nothing else in v1 may be abstracted "for later" — that is speculative generality and
`CLAUDE.md` rule 2 forbids it.

**Nothing designed in the prototype is deferred.** All 9 screens, Login included, are
phase 1 (D1). What phases 2 and 3 add is *real implementations behind those two seams* —
not new screens.

### 5.2 What is seeded vs what is already variable

Confirmed 2026-08-26. **The seeded content is fixed; the app's handling of it is not.**
Phase 1 always returns the same itinerary, but nothing downstream assumes 7 stops, 8 days
or one trip name.

| Treated as **variable** from phase 1 | Where |
|---|---|
| Trip title | `Itinerary.title` — never a literal in a widget |
| Stop count | `derivedMeta`, badge numbering, map pins, export URL all derive it |
| Stop order | `order` list; reorder, remove and restore all operate on it |
| Coordinates | map fits to the actual stop bounds, not a fixed camera |
| Which route a saved entry opens | `itineraryForSavedRoute(routeId)` |
| Day count | from the onboarding `days` answer |

| Genuinely **fixed**, and correctly so | Why |
|---|---|
| The 7 seeded stops and their copy | Phase-1 content; replaced wholesale by phase 3 |
| The 8 Explore POIs | Explore is read-only browsing, not generated |
| The Login backdrop route | Decorative ambience, not the user's itinerary |
| The 5 loading messages, 5 heat labels | UI copy |

**This is why `ItineraryRepository` returns `Itinerary` rather than `List<Stop>`.** An
earlier draft had the Result screen hold the title as a constant; that would have forced
phase 3 to edit a screen, contradicting §5. Corrected 2026-08-26.

### 5.3 Phase 3 pipeline

Described by the product owner 2026-08-26. **Not phase-1 work** — recorded because it
constrains the seam and the data model, both of which are built in phase 1.

```
15 onboarding answers
      ↓  filled into a hidden prompt template
   your server  —  NT-tourism model (fine-tuned, or RAG over NT tourist guides)
      ↓  structured itinerary: place NAMES, times, activities, notes  — no coordinates
   Google Geocoding / Places  —  name → coordinates
   Google Places Photos       —  name → image
      ↓
   Itinerary { title, stops[] }  →  the existing screens, unchanged
```

**The model's output maps onto the phase-1 model exactly.** This is why no screen changes:

| Model returns | Existing field |
|---|---|
| place name | `Stop.name` |
| short descriptor | `Stop.subtitle` |
| why this stop, here | `Stop.aiNote` |
| hour-by-hour schedule | `Stop.detailedPlan` — `{time, activity}` |
| opening hours / fee | `Stop.hours`, `Stop.fee` |
| categories | `Stop.tags` |
| trip name | `Itinerary.title` |
| — resolved by Google, not the model — | `Stop.lat`, `Stop.lng`, `Stop.photoUrl` |

**The model must not produce coordinates.** Ask an LLM for lat/lng and it returns
confident, wrong numbers — pins land in the ocean. Names in, geocoding out. This is the
single most likely way a phase-3 map goes visibly wrong.

**The client must not call the model directly.** App → your server → model. A key shipped
inside an APK is a public key.

**The response needs a strict schema and validation.** Model output is non-deterministic;
decide what happens when a field is missing. `detailedPlan` in particular may come back
empty, and the Detailed view needs a defined fallback.

**Loading has no failure state.** §3.4 specifies a non-interruptible timed transition with
no cancel and no error path — correct for a hard-coded delay, wrong for a network round
trip. Phase 3 needs a designed failure and retry state; none exists in any design file
today.

#### Images — three things to settle before phase 3

1. **Do not scrape Google Maps.** Pulling images "with a script" outside the Places API
   breaches the Google Maps Platform Terms of Service and breaks whenever the page markup
   changes. Use the **Places API photo endpoint**.
2. **Photos are a billable SKU.** Places Photos and Geocoding are both paid Maps Platform
   APIs with a monthly free allowance per SKU — a student-scale project plausibly stays
   inside it, but a **billing account with a card is required** either way. Google
   restructured Maps pricing in 2025; **verify current per-SKU rates and free tiers before
   committing** rather than trusting a number quoted here.
3. **Caching rules are asymmetric.** Google's terms let you store a **`place_id`
   indefinitely** but not the photos themselves — fetch those at display time. So the
   thing worth persisting per stop is the place id, not the image. That is a phase-3 field;
   do not add it in phase 1.

**Free alternative worth weighing:** every marquee NT location — Uluru, Kakadu, Litchfield,
Nitmiluk, Kings Canyon — has openly licensed photography on Wikimedia Commons, which has
no per-request cost, no billing account and no caching restriction. It gives worse coverage
for small venues, so the realistic answer may be Commons first with Places as fallback. A
decision for phase 3, not now.

#### What phase 1 already does right

No change is needed to phase-1 scope. The pieces are in place:

- `ItineraryRepository.itineraryFor(OnboardingAnswers)` **already takes the answers** — the
  prompt input arrives at the seam unchanged.
- It **already returns `Itinerary`**, so a different trip name and stop count need no screen
  edit (§5.2).
- `Stop.photoUrl` and `Poi.photoUrl` exist and are null; every surface renders
  `PlaceholderTile`. Phase 3 swaps that tile for an image widget where the URL is non-null.
- Map markers with thumbnail images have **no design** yet; that is a phase-3 design gap.

---

## 6. Decisions taken

| # | Decision | Effect |
|---|---|---|
| D1 | All 9 screens are v1 | Nothing deferred; the bottom nav is fully wired |
| D2 | Seeded itinerary behind a swappable generation boundary | No AI in v1; screens never touch seed data directly |
| D3 | Saved routes, session and onboarding flag persist | Returning users skip Login and land on Explore (Q2 resolved) |
| D4 | Login validates email and password | Submit-time inline error copy is fixed in Q5 |
| D5 | Google Sign-In is mocked in v1, real in phase 2 | No cloud project needed to build or test v1; auth sits behind a replaceable boundary |
| D6 | Explore search is functional | Filters existing POIs; no-match copy and clear action are fixed in Q6 |
| D7 | "Navigate" launches a single-destination Maps URL | Reuses the export URL builder |
| D8 | The second saved route has its own 4-stop itinerary | Four sourced stops are fixed in Q3 |
| D9 | Account and Language are minimal read-only screens | Two screens with no design source (§3.10) |
| D10 | Fix the prototype's internal inconsistencies | The deviations recorded in §7 |
| D11 | The app ships an account-creation screen | Operator decision 2026-09-10; specified in §3.1a, sliced as Task-21 |
| D12 | Phase 2 starts with Firebase Authentication — email/password and real Google Sign-In behind `AuthRepository`, Android first | Operator decision 2026-09-22, answering P1: Firebase confirmed as the backend; wave 1 is Task-23…25; saved routes stay on the device until Firestore is sliced as its own task; the seam count stays at two. The failure copy phase 1 had no reason to write (Q5, §2.5 of `docs/PHASE-2-3-FOUNDATION.md`) is authored in Task-24 and is binding from there |
| D13 | Phase 2 wave 2: saved routes carry their stops and sync to Firestore under the account with the device copy as the source of truth; password reset; email verification without gating; Crashlytics with a disclosure row | Operator decision 2026-09-22. Answers the rest of P1 and the "no third seam" question in `docs/PHASE-2-3-FOUNDATION.md` §2.3 the way it recommends: Firestore sits **inside** `PreferencesStore` as two injected functions (pull, push), no new interface, the seam count stays at two. Specified in §3.1, §3.9, §3.10 and §4; the store keys stay exactly two, `terra_nt.saved_routes` now holding stops. Password reset leaves §8 |
| D15 | Standing authority for the 2026-09-23 overnight goal run | Operator decision 2026-09-23 ~01:00: visual improvements beyond the prototype are allowed, each recorded as a V-row in §7 with before/after captures in `reports/shots/` and one commit each; features are free, each one leaving §8 as a dated row here; images via `gpt-image-2`. Scope: that run only (`reports/otopilot-2026-09-23-plan.md`); afterwards Blueprint's fidelity rule applies again unchanged |
| D16 | Plan AI shows an empty state until a route exists this session | 2026-09-23 goal run under D15 (Task-40): `ItineraryState.hasRoute` is false until a route is generated or a saved one is opened; Result then shows `No route yet` / `Answer a few questions and we'll plan a route across the Territory.` / `Plan My Route` (the Plan-again path, no confirm) instead of the seeded Full NT route presented as if generated |
| D14 | Phase 3, the app's side: the fifteen answers leave as `PlanRequest` with stable machine keys; the server returns `PlanResponse`; the app validates once at the boundary and swaps `RemoteItineraryRepository` behind the existing seam; Loading gets cancel, failure and retry | Operator decision 2026-09-22. `docs/PHASE-3-CONTRACT.md` is binding for the app and is what the server owner (a teammate) builds against. Answers P2 (RAG or fine-tune is invisible to the app), P3 (one endpoint, Firebase ID token, hosting is theirs), P4 (the prompt is designed in the contract and lives on the server), P5 (the per-field table) and P6 (§3.4). P7 and P8 stay open: the app renders `photoUrl` only when a later task adds the image widget |
| D17 | Demo readiness for 2026-10-01: the operator owns the planning server; Explore gains seven places; every place has a picture | Operator decisions 2026-09-29. The server is `tools/plan_server/` (Task-45) on the operator's machine, the model on the operator's Codex subscription behind a backend switch (OpenRouter API later); teammates supply RAG documents only. Explore's POI list grows from 8 to 15 (Task-46); the seven new illustrations and five tag fallbacks are `gpt-image-2` in the V22 series, so a stop with an unknown name shows its tag's picture instead of the placeholder. iOS is configured from Windows and built by a teammate on a Mac (`docs/IOS-SETUP.md`) |
| D18 | Polish pass before the demo: the design may improve beyond the prototype | Operator decision 2026-09-29: "uygulamanın tasarımını iyileştir … sana bırakıyorum" — the built app looked amateur (the onboarding progress bar named first), and Tarik Base is explicitly not to be applied. Scope: Task-48…51 (road progress and a rendered 4x4 sprite, Loading on the live map with the brand mark, entrance motion and press states, the auth screens' first impression). The project's own tokens stay; new motion tokens are `AppMotion.entrance*`, `pressScale`, `easeEmphasized`. Each visible change is recorded as a V-row at closeout, as under D15 |
| D19 | Endpoint menus and motion that plays when content becomes visible | Operator, 2026-09-30, delegated the choice for question 15 and requested a further polish fix (Task-52). Keep Start and End, replace typing with a short endpoint list; removing them would make the planner guess, and an extra-comments field serves a different purpose. Tab activation now fades the retained Navigator tree after its hidden first-build entrances have finished; question cards fade/slide and ease their height; answer checks reserve their space. Existing tokens, backend fields, manual Next and navigation stacks remain binding |

## 7. Deviations from the prototype

Deliberate, per D10. Each names what the prototype does and why this departs from it.
Nothing else may diverge.

| # | Prototype | This build | Why |
|---|---|---|---|
| V1 | Navigates at 5600 ms with a 1400 ms rotation (L864–871) | 7000 ms | Five messages are seeded; "Routing..." never renders |
| V2 | Result meta is the literal `"7 stops · 8 days"` (L1262) | Derived from live count and `days` | The saved-route entry already derives it (L1023); the two contradict after any remove |
| V3 | Row revert and "Restore N removed" both call `revertOrder()` (L1137, L1277) | Two scoped actions | A full reset matches neither control's label |
| V4 | Export includes skipped stops (L1005–1011) | Skipped stops excluded | Skipping a stop means not going; routing through it contradicts the flag |
| V5 | Result map is a fixed 1–7 iframe; `tnt-focus` handled but never posted | Pins track the live order | Reordering that leaves the map stale is visibly wrong |
| V6 | `confirmDeleteAccount` sets `savedRoutes: null` (L1069) | Clears to an empty list | `null` falls back to the seed, so deleting the account restores the demo routes |
| V7 | Back from onboarding step 0 goes to Login (L938) | Goes to Welcome | D3 persists the session, so Login is a screen the user is already past; Welcome is the screen they actually came from (Q4) |
| V8 | Result sheet uses fixed 190 / 430 / 700px anchors | Clamp anchors to the available sheet height while retaining nominal anchors that fit | A sheet must not extend beyond a smaller phone viewport |
| V9 | Rows keep stored `driveNext` after editing the route | Show the baseline leg only when its original successor still follows; otherwise show `Drive time unavailable`, with no next leg at the last stop | Reorder or removal must not display a drive estimate for a different leg |
| V10 | Explore and Result maps carry a 26px plus/minus zoom control | No zoom buttons; the map keeps pinch and double-tap zoom | Operator decision 2026-09-10: the buttons are redundant on touch, and two 26px buttons stacked 26px apart cannot both carry a non-overlapping 48x48 target without leaving the map's top edge |
| V11 | Step 9 asks "How detailed should your itinerary be?" as a two-card pick (L279) | That question is removed; the new last step (14) asks "Where does your trip start and end?" with two text inputs, and steps 10–14 shift down to 9–13 | Operator decision 2026-09-11: the detail level is a view of the result, not a trip input, so it belongs on Result as a local toggle; where the trip starts and ends is a real routing input the prototype never asked for |
| V12 | Single-select picks auto-advance after 380 ms, a second pick restarting the pending timer (L902–910) | Every step advances on Next only; a pick records the answer and schedules nothing | Operator decision 2026-09-11: the timer moves the screen out from under a user still reading the options, and makes correcting a mis-tap a race |
| V13 | Onboarding runs over the full-bleed map backdrop, its car at fraction `step / 14` of the route behind an 18% scrim | Flat `--canvas` behind the questions; the car drives the progress bar, riding the fill's leading edge and easing with the step card | Operator decision 2026-09-11: a scrimmed map under fifteen question cards is decoration the user cannot read, and it pays for a second animated map on the one screen that needs none; on the progress bar the same car reports where the user actually is |
| V14 | The prototype has no way back into onboarding once a route exists; the header carries only the share action (L432) | A "Plan again" action on the Result header resets the answers and the session edits and returns to step 0, asking "Discard edits and plan again?" inline when the order, removed or skipped set differs from the generated route | Operator decision 2026-09-11: an app whose premise is AI planning must let the user plan again without signing out; the inline confirm reuses the delete-account pattern so a stray tap cannot discard edits |
| V15 | Edit mode keeps the full stop cards and the sheet wherever the user left it (L1137) | Entering edit mode snaps the sheet to the 700px anchor and renders each stop as a 56px row (badge, name, revert, remove, drag handle) | Operator decision 2026-09-11: a 300px card cannot be auto-scrolled inside a 160px viewport, which is why reordering below the fold was impossible; a row shorter than the viewport lets the framework's edge scroller carry it |
| V16 | The backdrop route dots are primary at 85% with a 3px primary ring drawn as a spread shadow (`terra-nt-bg-map.html` L14) | A plain `--ink` dot at the same size, no ring | Operator decision 2026-09-11 ("find another solution for the blue circles on the map"): the ring is a shadow, which Blueprint forbids outside `--shadow-overlay`, and a primary dot next to primary numbered pins reads as a second, unlabelled stop |
| V17 | "Continue with Google" is a `secondary` button — `--surface-1` with a hairline, text only (L64) | An `inverse` button — `--action-inverse-bg` (white) with `--action-inverse-fg` text, no hairline, Google's "G" logo (`assets/images/google_g.png`, Google's own artwork) at icon size on the left | Operator decision 2026-09-22 ("google icon falan koy, beyaz yap butonu"), once Google Sign-In became real (D12): Google's sign-in branding guidelines put the G logo on a white or neutral button, and the phase-1 dark text-only button no longer reads as a Google sign-in. Both colours are existing inverse tokens; the logo is an image asset, not a colour token |
| V18 | Loading is non-interruptible: no cancel, no error path, navigates on a timer (L860–875) | A Cancel button while the request is in flight, a failure state with retry, and navigation on the response rather than on a timer (§3.4) | Operator decision 2026-09-22 (D14): the prototype's Loading fakes a fixed delay; phase 3 makes it a network round trip that can be slow, fail or be refused, and a screen with no way out of any of those is a trap |
| V19 | Explore and Result fit the camera with a flat 30 / 28 px pad; the map runs under nothing | The fit's top pad adds the status-bar inset and, on Explore, the floating search field; Explore clamps that extra reservation so a squeezed viewport keeps a 280 px strip | D15 (2026-09-23 goal run, Task-37): on a phone the map runs full-bleed under the status bar, so Darwin-area pins sat under the clock and the search box (`reports/shots/tour-04-explore.png`) |
| V20 | V9 shows `Drive time unavailable` for a leg whose original successor no longer follows | The row shows `<n> km straight line to <next stop>` — the haversine distance rounded to 5 km — whenever both stops have coordinates; `Drive time unavailable` remains only without them | D15 (2026-09-23 goal run, Task-39, from the audit): pacing is the product, and the distance to the stop that now follows is known; "straight line" says it is not a road distance |
| V21 | Every Explore POI pin is a primary ring on `--surface-2`, identical for every category (`terra-nt-explore-map.html`) | The ring and a centred 5 px dot take the POI's `--tag-*` colour via `tagColor()` (unknown tags fall back to `inkTertiary`); selected fills with the same colour | D15 (2026-09-23 goal run, Task-41, from the audit): a driver scanning the map can tell a wildlife park from a cultural site before tapping; the colours are existing tokens |
| V22 | Every image surface is a `PlaceholderTile` with an icon — the prototype ships no photography, and `photoUrl` is null everywhere | Stop detail's hero, Explore's POI card and the Saved Routes thumbnail show a bundled 1200×800 illustration for the nine seeded NT places (`assets/images/places/`), falling back to the placeholder for anything unmatched; a non-null `photoUrl` renders over the network with the same fallback | D15 (2026-09-23 goal run, Task-42): the operator asked for images; they are `gpt-image-2` illustrations, not photographs, so nothing claims to be a real photo of a real place, and bundling them keeps the no-signal premise intact. P7/P8 stay open — a real photo source is still the server's decision |
| V23 | Onboarding progress is a 4 px line in a bordered pill with a mono `N/15`; the car is a drawn glyph with a blob shadow | An open road (quiet band, dashed centre line, travelled part in primary) under `Step N of 15`; the car on it, on Loading's bar and on the auth map is the rendered 4x4 sprite `assets/images/car.png` | D18 (Task-48): the operator named the progress bar as the most amateur element; the drawn car read as clip-art |
| V24 | Loading is a pulsing primary disc, a pill bar and an underlined `Cancel` on black | The ambient Territory map above a docked panel; the brand mark in a badge with a breathing ring on the pulse tokens; messages crossfade; `Cancel` is a secondary `AppButton` | D18 (Task-49): with the real planner the wait is 30–45 s, the longest a user looks at one screen |
| V25 | Nothing enters; buttons have no pressed state; pushed routes slide in from the edge | Lists, cards and step answers fade and rise in (`Entrance`, staggered); `AppButton` settles to 0.97 while held; pushed routes fade through | D18 (Task-50): static screens were the main source of the prototype feel |
| V26 | Login and Create account open on plain text over the map | The brand mark (the app icon's route and pin) above the title, one spacing rhythm from title to footer, the title and form entering in turn | D18 (Task-51) |
| V27 | An onboarding answer is a bordered chip inside a bordered row | The row is the answer: plain label, a primary edge and a check when chosen | D18 (orchestrator, final tour): the nested borders read as clutter |
| V28 | Onboarding runs over the live map (V13 then made it flat canvas) | A still, very dark bundled illustration of the Territory (`assets/images/onboarding_backdrop.jpg`) behind the questions | Operator, 2026-09-29: the black screen read as unfinished. V13's reasons hold — no second animated map, no tile fetch — so the backdrop is a static image, not the map |
| V29 | A Result stop card is text only | A 112 px band of the place's picture across the top of the card when one exists (the same lookup as Stop detail, tag fallback included); no band otherwise | D18 follow-up: the place is seen before it is read about |
| V30 | Loading shows only the rotating messages | The trip in the user's own words above them: `7 days · Top End · Campervan` and `Darwin to Katherine` | D18 follow-up: a 30–45 s wait reads as work on *this* trip |
| V31 | Question 15 requires typing Start and End | Two menus of existing itinerary endpoint names, no automatic answer, same two strings in the planning request | D19, Task-52: remove keyboard/spelling friction without losing the route's endpoints |
| V32 | Tabs switch instantly after hidden entrance animations have finished; new question height and selected checks snap | Tab activation fades over `AppMotion.base` without rebuilding stacks; a question fades/slides and resizes over the existing 320 ms; row fill/border and fixed check slot animate over `AppMotion.fast` | D19, Task-52: motion follows the user's action; reduced motion shows the new state immediately |

## 8. Out of scope (v1)

**Absent from the prototype and not being invented:** ~~forgot-password or password
reset~~ (phase 2, D13, 2026-09-22 — §3.1); ~~any real backend, server or cross-device
sync~~ (phase 2 and 3, D13/D14); a POI detail screen or adding a POI
to a route; POI filtering by category; geolocation, user location or "near me"; adding a
new stop to an itinerary; editing stop times, durations, fees or notes; regenerating a
route from the Result screen; renaming, duplicating or sharing a saved route; undo after
deleting one; sorting, filtering or searching saved routes; profile editing; real offline
map downloads or cache management; notification, privacy or theme settings.

**Sign-up left this list on 2026-09-10** (D11). It is specified in §3.1a and built by
Task-21; what stays out of scope is the *stored* account, which needs phase 2.

**Deferred to a later phase, not cancelled** (see §5.1): real Google Sign-In and any
Firebase or server-backed auth (D5) — **phase 2 began on 2026-09-22 (D12)** and builds
exactly these; real AI itinerary generation (D2).

**Excluded outright by decision:** a second app language or any i18n (D9); editable
account details (D9).

**Excluded by the design system:** a light mode — there isn't one, and
`design-system/README.md` forbids adding it. Also no gradients beyond the two specified
scrims, no `backdrop-filter`, no glows, no coloured shadows, and no drop shadows outside
`--shadow-overlay` on floating surfaces.

**Not decided here — Blueprint's call:** tablet and landscape layouts, and the golden or
visual-regression testing question, which `CLAUDE.md` → Blueprint explicitly declines to
mandate.

## 9. Open questions

Genuinely undecided. None is answered by a guess elsewhere in this document.

1. **How is visual fidelity verified?** The prototype won't render and the component
   bundle is missing (§2), so "a visual difference is a bug" is still unfalsifiable by any
   automated check. Two options remain for making it falsifiable: repoint the prototype at
   the local token CSS so static layout renders; or accept markup-only fidelity.
   **Still blocks any visual acceptance criterion.**

   **Partially eased 2026-08-26 — review, not verification.** The product owner captured
   ten reference screenshots into `docs/screenshots/`, so a built screen can now be
   compared by eye. That is a review practice, not a verification method, and it does not
   unblock this question. Three limits, recorded so the distinction survives:
   coverage is partial (main screens, default states — no route deletion, no dialogs, no
   remaining onboarding questions, no error states); the captures inherit the prototype's
   own defects (the Google mark missing from "Continue with Google", an outdated car on
   the map); and where the build *should* differ, §7's numbered deviations govern, not the
   image. **No task may cite a file in `docs/screenshots/` as an acceptance criterion.**

   **Restoring `design/screenshots/` is not an option — do not propose it again.**
   Confirmed by the product owner 2026-08-26: those nine PNGs were deleted *deliberately*
   because they are flawed, and they must not be used as a visual reference. This
   correction is written down because every other signal points the wrong way — the files
   are still intact in commit `bdeb783` and a one-line `git checkout` brings them back, so
   anyone reasoning from the repository alone will reach for them. The new captures are a
   **separate set at a different path**; they do not reopen this.
2. **Where does a returning user land?** D3 persists the session, so Login is skipped —
   but the prototype has no design for a launch state, and no way back to Login for
   testing beyond Log Out. Explore? Last-used tab? Result?

   **Resolved 2026-09-05** (answered on the product owner's instruction): **Explore**, and
   the prototype already answers it. `onSkipOnboarding` — its only path into the app that
   is not a fresh generation — goes to `explore` (L1072). That is the designed
   "you are in, with no itinerary in hand" destination, which is exactly a returning
   user's state.

   The two alternatives were rejected on cost, not taste. *Last-used tab* needs a second
   persisted key, has no design, and can restore a tab whose content is gone (a deleted
   saved route). *Result* would open a stale itinerary the user did not ask for, and after
   V2 its meta derives from live state that no longer exists at cold start. Explore needs
   no new persistence and no new screen: the launch route reads the same
   `session.onboardingDone` D3 already stores — false goes to onboarding, true goes to
   Explore.

   **Amended 2026-09-23 (D15, Task-36):** with real accounts (D12) the rule first asks the
   auth seam — nobody signed in lands on **Login**; signed in and not onboarded goes to
   onboarding; signed in and onboarded goes to Explore. The phase-1 rule let a fresh
   install plan with no account, so nothing synced and Profile showed the placeholder.
3. **What are the Red Centre itinerary's 4 stops?** D8 requires them and no design file
   supplies any. Proposal: Alice Springs, Kings Canyon, Uluru-Kata Tjuta plus one more,
   reusing existing seeded copy where it fits.

   **Resolved 2026-09-05** (answered on the product owner's instruction). The four stops,
   in drive order, are **Alice Springs → Alice Springs Desert Park → Kings Canyon →
   Uluru-Kata Tjuta**. Three of them are the existing `seedStops` entries reused
   **verbatim**; only `driveNext` is recomputed for the shorter route, and Uluru-Kata
   Tjuta keeps `driveNext: null` as the last stop.

   The fourth is **Alice Springs Desert Park**, and it is the only candidate whose every
   field already exists in the seed — nothing here is authored:

   | Field | Source |
   |---|---|
   | name, tag `Nature`, description | `POIS` entry `desertpark`, `Terra NT.dc.html` L792 |
   | lat/lng `-23.7180, 133.8330` | `terra-nt-explore-map.html` L27 — its own point, distinct from the Alice Springs stop at `-23.6980, 133.8807` |
   | hours `Alice Springs Desert Park 7:30am–6:00pm` | already written on the Alice Springs stop, L749 |
   | fee `Desert Park entry $40 adult` | same line |

   **Two alternatives were rejected, and the reason matters more than the choice.**
   Splitting `Uluru-Kata Tjuta` into two stops reads better as an itinerary and the copy
   is there — the stop's own plan already breaks the day at 3:00pm for Kata Tjuta — but
   **Kata Tjuta has no coordinates anywhere in the seed**, and Task-03's acceptance
   criteria test coordinates, so an invented pair would be a fabricated value inside a
   tested field. A genuinely new Red Centre place (West MacDonnell, Simpsons Gap) would
   author content the prototype never had.

   **Known redundancy, recorded rather than fixed:** the Alice Springs stop's own hours
   and fee already describe the Desert Park, so those two strings appear on both stops.
   That duplication is the prototype's, not this decision's; `seedStops` is transcribed
   verbatim and is not edited to remove it.

   **Correction, 2026-09-07.** The claim above that "every field already exists" was
   wrong: it enumerated six fields, and the `Stop` model requires four more that no
   source supplies. Rather than leave the gap for a later session to fill silently,
   they are recorded here as **derived**, and the seed comments say so at the point
   of use:

   | Field | Value | Derived from |
   |---|---|---|
   | `subtitle` | `Wildlife & desert ecology` | trimmed from the POI description, in the style of the other subtitles |
   | `duration` | `1 day` | every stop except Kakadu is a single day |
   | `detailedPlan` | 3 entries | the opening and closing times of the sourced `hours` string, plus the `1:00pm Alice Springs Desert Park` entry the Alice Springs stop already carries |
   | `driveNext` (Alice Springs → Desert Park) | `7 km · 15m to Alice Springs Desert Park` | **authored** — the two points are ~7 km apart in the same town and no leg copy exists anywhere in the seed |

   The last row is the only invented content in `data/seed/`. It is one display string,
   it is not parsed by anything (Blueprint: drive copy is a display string), and phase 3
   replaces the whole itinerary anyway.
4. **Back from onboarding step 0 → Login or Welcome?** The prototype goes to Login
   (L938), skipping the screen the user just came from. Possibly deliberate, possibly not
   — it was left out of the V-list because, unlike those six, it isn't self-contradictory.

   **Resolved 2026-09-05** (answered on the product owner's instruction): **Welcome**, and
   it is now deviation **V7**. The prototype's own flow is Login → Welcome
   (`onStartExploring`, L1212) → onboarding (`onCreateRoute`, L1071), so step 0's back
   button skips one screen. Under D3 that is not merely surprising, it is incoherent:
   the session persists, so Back drops a signed-in user onto a login form they have
   already passed and cannot leave except by signing in again. Welcome restores the
   symmetry — every Back returns the screen the user came from — and needs no new copy
   or layout.
5. **What does login validation say when it fails?** D4 adds inline errors; the design has
   no error state, no error copy and no invalid-field styling.

   **Resolved 2026-09-05** (answered on the product owner's instruction). Validation runs
   **on submit only** — never while typing, never on blur — and the first failing field
   takes focus. Two rules, two strings, no new visual language:

   | Field | Rule | Error copy |
   |---|---|---|
   | Email | Non-empty, and matches `<something>@<something>.<something>` with no spaces | `Enter a valid email address.` |
   | Password | Non-empty | `Enter your password.` |

   Both render in `AppTextInput`'s existing error slot (Task-02) in `--tag-red`, and the
   field's border takes the same token while the error shows. An error clears when that
   field next changes. **There is no "wrong password" case**: auth is mocked in phase 1
   and any syntactically valid pair signs in, so copy implying a credential check would
   be a lie the build cannot tell. A password length rule is deliberately omitted for the
   same reason — with no real account there is nothing for it to protect, and it would
   reject valid test input.
6. **What does Explore search show?** D6 makes it real, but there is no design for a
   results list, a no-matches state, or whether the map filters alongside the card.

   **Resolved 2026-09-05** (answered on the product owner's instruction). Search **filters
   the surfaces that already exist; it introduces no rendered results list.** One filtered
   POI collection is computed from the query. It drives the map markers and determines
   whether the one selected POI info card remains eligible; the filtered collection is a
   data list, not a second card UI.

   - **Match:** trim leading/trailing query whitespace, then use a case-insensitive
     substring over the POI's `name` and `tag`. Not the
     description — matching prose returns cards whose reason for matching is invisible.
   - **Empty query:** all eight POIs, identical to today. A whitespace-only query is empty;
     search off is not a state.
   - **No matches:** the bottom card area shows one centred `--color-ink-tertiary` line,
     `No places match your search.`, above a `Clear search` text button that empties the
     field. The map keeps its current viewport and shows no markers.
   - **Selection:** if the selected POI is filtered out, the info card closes and the
     bottom area returns to its unselected state. If it still matches, the single info card
     remains open. A card describing a place the user can no longer see is the same
     disagreement in a different shape.

   No new tokens, no new components: the empty line reuses the Saved Routes empty-state
   pattern (§3.8) and `Clear search` is the existing text-button style.
7. **Are the provisional tag hexes correct?** The six `--tag-*` values were derived from
   the accent hue family, not sampled from the real product
   (`design-system/tokens/colors.css`). Usable, not confirmed. Define them as named tokens
   so a correction stays a one-line change.
8. ~~**Which font files?**~~ **Resolved 2026-08-25:** Inter and JetBrains Mono ship as
   bundled `.ttf` assets in `pubspec.yaml`, not fetched at runtime. Reason: the app is
   about places with no phone signal, so typography must not depend on a network fetch.
   Recorded in `CLAUDE.md` → Blueprint → Stack.

### Deferred — the phase 2 and 3 decisions

Collected 2026-08-26 from §5.1 and §5.3, where they are already stated in context. Gathered
here so that starting a later phase means reading one list instead of re-mining the
document.

**These are deliberately unanswered and must stay that way for now.** None blocks v1;
answering them early is the speculative generality `CLAUDE.md` rule 2 forbids. They are
numbered separately from questions 1–8 above **on purpose** — those are referenced by
number from `docs/TASKS_INDEX.md` and from individual task files, so the list above must
never be renumbered.

| | Decision | Phase |
|---|---|---|
| P1 | Firebase or an equivalent backend; what real Google Sign-In runs on; where saved routes live once they leave the device. **Taken 2026-09-22 (D12):** Firebase Authentication, Google Sign-In through it. **Rest taken the same day (D13):** saved routes in Firestore under the account, device copy first | 2 |
| P2 | Fine-tuned NT-tourism model **or** RAG over NT tourist guides. **Taken 2026-09-22 (D14):** outside the app's boundary; the server owner chooses, the app cannot tell | 3 |
| P3 | The server between app and model. **Endpoint contract taken 2026-09-22 (D14, `docs/PHASE-3-CONTRACT.md` §1);** stack and hosting remain the server owner's | 3 |
| P4 | The hidden prompt template. **Taken 2026-09-22 (D14):** designed in `docs/PHASE-3-CONTRACT.md` §4, lives on the server, never in the client | 3 |
| P5 | The response schema and per-field fallbacks. **Taken 2026-09-22 (D14):** `docs/PHASE-3-CONTRACT.md` §3; an empty `detailedPlan` shows `No detailed plan for this stop.` in the Detailed view | 3 |
| P6 | Loading's failure and retry state. **Taken 2026-09-22 (D14):** §3.4, deviation V18 | 3 |
| P7 | Images: Places API photo endpoint, Wikimedia Commons, or Commons-first-with-Places-fallback. Requires a billing account either way; per-SKU rates must be re-verified when the decision is taken, not trusted from §5.3 | 3 |
| P8 | Map markers carrying thumbnail images — no design exists for them | 3 |

**What phase 1 must keep true regardless of how these land** (§5.3, *What phase 1 already
does right*): the generation seam takes `OnboardingAnswers` and returns `Itinerary`;
nothing downstream assumes a stop count, a day count or a trip name; `photoUrl` stays
nullable with a placeholder behind it; and no coordinate ever originates from a model.

---

## Next step

`CLAUDE.md` → Blueprint was written from this PRD on 2026-08-25 and is now binding: stack,
folder layout, the two seams, verification rules and the forbidden list.

`generate-tasks` can run. Two things to carry into it:

- **Open question 1 is still unanswered** and still has no owner. Until it does, no task
  may claim a *visual* acceptance criterion — behavioural criteria only. This is a real
  limit on what "done" can mean for a screen, not a formality.
- **Questions 2–6 were resolved on 2026-09-05.** The affected tasks carry each binding
  answer in their own file; none remains an implementation blocker.
