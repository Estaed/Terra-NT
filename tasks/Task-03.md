# Task-03 — Domain models and seed data (pure Dart)

Status: DONE

> **Execution:** agent `codex` · effort `high` · plan mode no
> *Why:* Tier 1 pure Dart models and seed data; acceptance is `flutter analyze` plus unit tests. Q3 (the Red Centre stops) was answered 2026-09-05; the seed input is on record.

**Lane**
- OWNS: `terra_nt/lib/data/models/`, `terra_nt/lib/data/seed/`, `terra_nt/test/data/models/`, `terra_nt/test/data/seed/`
- MUST NOT TOUCH: `terra_nt/lib/core/util/` (Task-04), `terra_nt/lib/data/repositories/` (Task-05), `terra_nt/lib/features/` (Task-06), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/data/`
- DEPENDS ON: none

## Objective

Define the data types and transcribe the prototype's seeded content. This is Part 2 tier 1:
**no `package:flutter` import may appear in any file this task creates.** Everything here
is testable without a widget.

## Answered — `docs/PRD.md` Q3 (2026-09-05)

`redCentreStops` is **Alice Springs → Alice Springs Desert Park → Kings Canyon →
Uluru-Kata Tjuta**. The three shared stops are the `seedStops` entries reused verbatim,
with `driveNext` recomputed for the shorter route and `null` on Uluru-Kata Tjuta. The
Desert Park stop is assembled entirely from copy that already exists — see the field
table under Q3; **author nothing that is not sourced there.** The duplicated hours and
fee between Alice Springs and the Desert Park are the prototype's, and stay.

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
| `redCentreStops` (4) | `docs/PRD.md` Q3 — 3 stops reused from `seedStops`, Desert Park assembled from L792 + L749 + explore-map L27 |

**The POI model is split across two files and the coordinates deliberately differ from the
stop coordinates** — Ubirr sits at −12.4260, 132.9760 while the Kakadu *stop* is at
−12.6692, 132.8352. Do not "fix" this by reusing stop coordinates.

**Tags on stops are plain strings.** The tag→colour mapping is logic and belongs in
Task-04, not here — tier 1 data carries no colours.

## Acceptance Criteria (DoD)

- [x] `grep -rn "package:flutter" lib/data/models lib/data/seed` returns nothing.
- [x] `grep -rn "latlong2" lib/data/models lib/data/seed` returns nothing.
- [x] `seedStops.length == 7`, in order Darwin → Litchfield → Kakadu → Nitmiluk → Alice Springs → Kings Canyon → Uluru-Kata Tjuta.
- [x] `Itinerary` carries both `title` and `stops`; a test builds one with 4 stops and a different title, proving neither is fixed at 7 or to one string.
- [x] Only the last stop has `driveNext == null`; exactly the stops that carry a fee in the prototype have non-null `fee` (Darwin and Litchfield differ — Darwin's is null, Litchfield's is `"Free entry"`).
- [x] `seedPois.length == 8` and a test asserts Ubirr's coordinates are `-12.4260, 132.9760`, proving POI coordinates came from the map file, not the stop list.
- [x] `photoUrl` is null on every seeded stop and POI, and `grep -rn "Image.network\|NetworkImage\|CachedNetworkImage" lib/` returns nothing — phase 1 loads no remote images.
- [x] `loadingMessages.length == 5` and the last entry is exactly `"Routing..."`.
- [x] `heatLabels.length == 5` and each string matches the prototype character-for-character.
- [x] A test asserts `seedStops[2].detailedPlan` has 10 entries (Kakadu is the 2-day stop) and that its first entry time is `"7:00am"`.
- [x] `OnboardingAnswers()` defaults are `days == 7`, `heat == 3`, `detailed == false`, `focus.isEmpty`, and every other field null.
- [x] `copyWith` is tested to change one field and leave the rest identical.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/data/` exits 0.

## Verification note — 2026-09-07

`verify-task` found the suite green and the implementation wrong. Every box above was
already ticked and every test passed, because the tests asserted the values the seed
already held. Diffing `data/seed/seed_data.dart` against the prototype's `STOPS` block
(`Terra NT.dc.html` L693) found:

- **Stop 0 was authored, not transcribed.** It carried the `darwin-wf` POI's name and
  **its coordinates** (`-12.4680, 130.8410` instead of the stop's `-12.4634, 130.8456`) —
  exactly the reconciliation the Execution Guide above forbids — plus invented
  `subtitle`, `hours` and `aiNote`, and a `detailedPlan` missing the prototype's opening
  `9:00am` entry.
- **Punctuation was retyped rather than transcribed:** 8 × `·` written as `•`, 6 × `–`
  and 3 × `—` written as `-`, and one `·` written as `–`. Part 2 requires copy
  character-for-character.
- **The Darwin → Litchfield leg read `1h 20m`;** the prototype says `1h 30m`.
- **`redCentreStops` contradicted the Q3 answer,** seeding Nitmiluk instead of Alice
  Springs Desert Park.

All seven stops now match the prototype field-for-field, including `detailedPlan` entry
counts. Five tests were added to pin the transcription, and each was mutation-tested to
confirm it fails when the value regresses. The four Desert Park fields with no source are
recorded as derived in `docs/PRD.md` Q3.
