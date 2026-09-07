# PRD — Terra NT Route Planner

**Status:** written 2026-08-25 from the prototype in `design/`. Answers *what* and *why*.
The *how* — stack, folder layout, packages, state management — belongs in
`CLAUDE.md` → Part 2, which is written from this document and is still a placeholder.

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

- Email and password are **validated** — format check, primary CTA disabled until valid,
  inline error copy. *(Decision D4; the prototype validates nothing.)*
- "Continue with Google" is a **mock in v1** — it behaves identically to "Start
  Exploring", exactly as the prototype has it. Real Google Sign-In lands in phase 2.
  *(Decision D5, revised 2026-08-25.)*
- Both paths land on Welcome.
- The email in the session is what Profile displays, falling back to `explorer@example.com`.
- No bottom nav here.

### 3.2 Welcome — `Terra NT.dc.html` L70–86

Same backdrop, flat `rgba(1,1,2,0.42)` scrim. One card: "Welcome to Terra NT" over
"Answer a few quick questions and we'll build a route across the Territory for you — or
skip straight to exploring on your own." Two full-width buttons.

- "Create My Route" → Onboarding step 1 of 15.
- "Skip for Now" → marks onboarding done, lands on Explore. No route is generated and
  none is saved.
- No bottom nav.

### 3.3 Onboarding — `Terra NT.dc.html` L87–377, logic L918–948

Fifteen steps, strictly linear, over the progress map. Top bar: back button, pill progress
bar, "n/15" counter. The step card slides in from `translateX(18px)` over 320 ms.

The backdrop car sits at fraction `step / 14` of the route and **travels along the
polyline through every intermediate stop** as steps advance — never a straight chord
between endpoints. The sampler walks a cumulative-distance table
(`terra-nt-bg-map.html` L89–110); animation duration is `700 + span × 3500` ms, eased
`1 - (1-t)³`.

| # | Question | Type | Gate |
|---|---|---|---|
| 0 | Which age range are you in? | single-select, auto-advance | required |
| 1 | How many days is your trip? | slider 1–14, default 7 | none |
| 2 | Who are you traveling with? | single-select | required |
| 3 | What's the main focus of this trip? | **multi-select**, manual Next | ≥1 |
| 4 | What are you traveling in? | single-select | required |
| 5 | What's your budget? | single-select | required |
| 6 | Where do you want to stay? | single-select | required |
| 7 | What's your physical activity level? | single-select | required |
| 8 | Which region do you want to focus on? | single-select | required |
| 9 | How detailed should your itinerary be? | two-card, auto-advance | none |
| 10 | How confident are you driving a 4x4 off-road? | single-select | required |
| 11 | How well do you handle extreme heat? | slider 1–5, default 3 | none |
| 12 | Camping under the stars, or resort comfort? | single-select | required |
| 13 | How interested are you in spotting wildlife? | single-select | required |
| 14 | Comfortable in remote areas with no phone signal? | yes/no, manual | required |

Option labels are in the render block, L1226–1249. Behaviour:

- Single-select picks auto-advance after **380 ms**; a second pick inside that window
  cancels and restarts the pending advance rather than double-advancing (L902–910).
- Progress bar fills to `round(((step + 1) / 15) × 100)`%; counter shows `step + 1`.
- An **"NT-specific"** pill sits above the question on **steps 10–14** — the last five,
  not the last two (badge at L279, 296, 311, 328, 345).
- The step-11 slider shows a text label per notch, from the 5 seeded strings (L799).
- Step 14's button reads "Generate My Route" instead of "Next".
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
  pending navigation and the save.

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
   so it always agrees with the Saved Routes entry. *(Deviation V2.)*
2. Segmented control, Highlights / Detailed. Highlights shows one AI-note line per stop;
   Detailed shows that stop's hour-by-hour schedule. This shares one value with the
   step-9 onboarding answer rather than duplicating it.
3. "Edit Route" toggle — flips to "Done", icon `Pencil` → `Check`.
4. Primary "Export to Google Maps".
5. "Restore N removed stop(s)" — shown only when something has been removed, singular at N=1.
6. Scrollable stop list. **View mode:** chevron, tap opens Stop detail. **Edit mode:**
   drag handle, revert icon, remove icon; tapping the row does not navigate.

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

### 3.10 Account and Language — no design source

Both are **new**, added because their rows now honour their chevrons *(Decision D9)*.
Build them from existing row patterns and tokens; invent no new visual language.

- **Account:** read-only rows — avatar, display name, email — plus a back button. No editing.
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

Plain terms — field names and types are Part 2's business.

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
| **2 — Backend** | Firebase (or equivalent): real Google Sign-In, real accounts, saved routes moving off the device. | Planned, not specified here |
| **3 — AI** | Real itinerary generation replacing the seeded implementation. The model is not ready yet. | Planned, not specified here |

Phases 2 and 3 are **out of scope for v1 but not cancelled**. This PRD's job is to make
them cheap to land later, which is why exactly two seams exist:

- **Generation** (§5) — screens ask for an itinerary, never for seed data.
- **Auth** — screens ask "who is signed in" and "sign in with Google", never for Firebase.

Both are declared in `CLAUDE.md` → Part 2 → Architecture. **No third seam is permitted.**
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
| The Login / onboarding backdrop route | Decorative ambience, not the user's itinerary |
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

## 8. Out of scope (v1)

**Absent from the prototype and not being invented:** sign-up, forgot-password or password
reset; any real backend, server or cross-device sync; a POI detail screen or adding a POI
to a route; POI filtering by category; geolocation, user location or "near me"; adding a
new stop to an itinerary; editing stop times, durations, fees or notes; regenerating a
route from the Result screen; renaming, duplicating or sharing a saved route; undo after
deleting one; sorting, filtering or searching saved routes; profile editing; real offline
map downloads or cache management; notification, privacy or theme settings.

**Deferred to a later phase, not cancelled** (see §5.1): real Google Sign-In and any
Firebase or server-backed auth (D5); real AI itinerary generation (D2).

**Excluded outright by decision:** a second app language or any i18n (D9); editable
account details (D9).

**Excluded by the design system:** a light mode — there isn't one, and
`design-system/README.md` forbids adding it. Also no gradients beyond the two specified
scrims, no `backdrop-filter`, no glows, no coloured shadows, and no drop shadows outside
`--shadow-overlay` on floating surfaces.

**Not decided here — Part 2's call:** tablet and landscape layouts, and the golden or
visual-regression testing question, which `CLAUDE.md` → Part 2 explicitly declines to
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
   it is not parsed by anything (Part 2: drive copy is a display string), and phase 3
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
   Recorded in `CLAUDE.md` → Part 2 → Stack.

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
| P1 | Firebase or an equivalent backend; what real Google Sign-In runs on; where saved routes live once they leave the device | 2 |
| P2 | Fine-tuned NT-tourism model **or** RAG over NT tourist guides — §5.3 states the either/or and picks neither | 3 |
| P3 | The server between app and model: stack, hosting, and the endpoint contract. §5.3 fixes only that it *must* exist (an API key inside an APK is a public key) | 3 |
| P4 | The hidden prompt template itself — §5.3 names it as a pipeline stage, nothing defines its content | 3 |
| P5 | The response schema, and what happens per field when the model omits one. `Stop.detailedPlan` is called out specifically: the Detailed view needs a defined fallback | 3 |
| P6 | Loading's failure and retry state. §3.4 specifies a non-interruptible timed transition with no cancel and no error path — correct for a fixed delay, wrong for a network round trip, and no design file has one | 3 |
| P7 | Images: Places API photo endpoint, Wikimedia Commons, or Commons-first-with-Places-fallback. Requires a billing account either way; per-SKU rates must be re-verified when the decision is taken, not trusted from §5.3 | 3 |
| P8 | Map markers carrying thumbnail images — no design exists for them | 3 |

**What phase 1 must keep true regardless of how these land** (§5.3, *What phase 1 already
does right*): the generation seam takes `OnboardingAnswers` and returns `Itinerary`;
nothing downstream assumes a stop count, a day count or a trip name; `photoUrl` stays
nullable with a placeholder behind it; and no coordinate ever originates from a model.

---

## Next step

`CLAUDE.md` → Part 2 was written from this PRD on 2026-08-25 and is now binding: stack,
folder layout, the two seams, verification rules and the forbidden list.

`generate-tasks` can run. Two things to carry into it:

- **Open question 1 is still unanswered** and still has no owner. Until it does, no task
  may claim a *visual* acceptance criterion — behavioural criteria only. This is a real
  limit on what "done" can mean for a screen, not a formality.
- **Questions 2–6 were resolved on 2026-09-05.** The affected tasks carry each binding
  answer in their own file; none remains an implementation blocker.
