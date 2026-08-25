# Task-03 — Domain models and seed data (pure Dart)

## Objective

Define the data types and transcribe the prototype's seeded content. This is Part 2 tier 1:
**no `package:flutter` import may appear in any file this task creates.** Everything here
is testable without a widget.

## ⛔ Blocked on `docs/PRD.md` Q3

Decision D8 requires "7 Days in the Red Centre" to open **its own 4-stop itinerary**, and
no design file supplies those 4 stops. The proposal on record is Alice Springs, Kings
Canyon, Uluru-Kata Tjuta plus one more, reusing existing seeded copy. **Get this answered
before authoring `redCentreStops`.** Everything else in this task can proceed.

## Execution Guide

**Files:** `terra_nt/lib/data/models/` and `terra_nt/lib/data/seed/`.

**Models** — plain immutable Dart classes. Derived from the prototype's shapes, not
invented:

- `Stop` — name, subtitle, `LatLng`-free coordinates (store raw `double lat, lng`; keep
  `latlong2` out of tier 1), hours, **nullable** fee, duration, **nullable** `driveNext`
  (null on the last stop only), `aiNote`, `List<String> tags`, `List<PlanEntry>
  detailedPlan`, and **nullable `photoUrl`**.
  > `photoUrl` is transcription, not speculation: the prototype's own seed carries
  > `photo: ""` on three stops (L720, L737, L750) and on the Uluru POI (L794). It is null
  > throughout phase 1 and every surface renders `PlaceholderTile` — **do not build image
  > loading in phase 1.** Phase 3 fills it from Google Places (`docs/PRD.md` §5.3).
- `PlanEntry` — time, activity.
- **`Itinerary`** — `title` + `List<Stop> stops`. The title travels **with** the stops, not
  as a constant in a widget. Phase 1 seeds it as "Full NT: Darwin to Uluru"; phase 3's model
  returns its own title and stop count, and no screen changes. Without this the Result
  screen would hardcode the title, which contradicts `docs/PRD.md` §5 ("swapping in real
  generation must not touch any screen").
- `Poi` — id, name, tag, rating, description, lat, lng, **nullable `photoUrl`** (same reasoning).
- `SavedRoute` — id, title, meta, dateLabel.
- `OnboardingAnswers` — the 15 values in `docs/PRD.md` §3.3, with defaults `days = 7`,
  `heat = 3`, `detailed = false`, `focus = const []`, the rest null. Needs `copyWith`.
- `Session` — email, `onboardingDone`.

**Seed data** — transcribe **verbatim**, including punctuation and ellipses:

| Constant | Source |
|---|---|
| `seedStops` (7) | `Terra NT.dc.html` L693–784 |
| `seedPois` (8) | names/tags/ratings/descriptions L786–796; **coordinates from `terra-nt-explore-map.html` L22–31** |
| `seedSavedRoutes` (2) | L803–806 |
| `loadingMessages` (5) | L798 |
| `heatLabels` (5) | L799 |
| `redCentreStops` (4) | ⛔ blocked, see above |

**The POI model is split across two files and the coordinates deliberately differ from the
stop coordinates** — Ubirr sits at −12.4260, 132.9760 while the Kakadu *stop* is at
−12.6692, 132.8352. Do not "fix" this by reusing stop coordinates.

**Tags on stops are plain strings.** The tag→colour mapping is logic and belongs in
Task-04, not here — tier 1 data carries no colours.

## Acceptance Criteria (DoD)

- [ ] `grep -rn "package:flutter" lib/data/models lib/data/seed` returns nothing.
- [ ] `grep -rn "latlong2" lib/data/models lib/data/seed` returns nothing.
- [ ] `seedStops.length == 7`, in order Darwin → Litchfield → Kakadu → Nitmiluk → Alice Springs → Kings Canyon → Uluru-Kata Tjuta.
- [ ] `Itinerary` carries both `title` and `stops`; a test builds one with 4 stops and a different title, proving neither is fixed at 7 or to one string.
- [ ] Only the last stop has `driveNext == null`; exactly the stops that carry a fee in the prototype have non-null `fee` (Darwin and Litchfield differ — Darwin's is null, Litchfield's is `"Free entry"`).
- [ ] `seedPois.length == 8` and a test asserts Ubirr's coordinates are `-12.4260, 132.9760`, proving POI coordinates came from the map file, not the stop list.
- [ ] `photoUrl` is null on every seeded stop and POI, and `grep -rn "Image.network\|NetworkImage\|CachedNetworkImage" lib/` returns nothing — phase 1 loads no remote images.
- [ ] `loadingMessages.length == 5` and the last entry is exactly `"Routing..."`.
- [ ] `heatLabels.length == 5` and each string matches the prototype character-for-character.
- [ ] A test asserts `seedStops[2].detailedPlan` has 10 entries (Kakadu is the 2-day stop) and that its first entry time is `"7:00am"`.
- [ ] `OnboardingAnswers()` defaults are `days == 7`, `heat == 3`, `detailed == false`, `focus.isEmpty`, and every other field null.
- [ ] `copyWith` is tested to change one field and leave the rest identical.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/data/` exits 0.
