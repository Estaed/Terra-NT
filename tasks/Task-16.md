# Task-16 — Explore: interactive map, POI selection, search

> **Execution:** agent main loop · effort `high` · plan mode **yes**
> *Why:* Q6 (search behaviour) was answered 2026-09-05, so the **content** is fixed. This
> remains main-loop work with Plan mode because one filtered list must drive the marker
> layer, card list and info card together on the app's first `interactive: true` map.

**Lane**
- OWNS: `terra_nt/lib/features/explore/`, `terra_nt/test/features/explore/`
- MUST NOT TOUCH: `terra_nt/lib/shared/map/` (Task-07), `terra_nt/lib/data/` (Task-03, Task-05), `terra_nt/lib/app/` (Task-06), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/explore/`
- DEPENDS ON: Task-05, Task-06, Task-07

## Objective

Build the Explore tab: a fully interactive map of the 8 seeded POIs, the bottom info card,
and the search that Decision D6 promotes from a static label to a working control.

## Answered — `docs/PRD.md` Q6 (2026-09-05)

Search **filters what already exists; there is no rendered results list.** One filtered POI
collection drives the markers and the eligibility of the single selected info card. It is
a data list, not a second card UI. Match trims the query, then applies a case-insensitive
substring over POI `name` and `tag` only. Empty or whitespace-only query shows all eight.
No matches shows a centred `inkTertiary` line `No places match your search.` over a
`Clear search` text button, with the map keeping its viewport and dropping its markers.
If the selected POI is filtered out, the info card closes; if it still matches, it remains
open. Full reasoning under Q6.

## Execution Guide

**Files:** `terra_nt/lib/features/explore/`.
Sources: `Terra NT.dc.html` L385–418; markers and coordinates from
`terra-nt-explore-map.html` L22–31.

**Map:** `TerraMap` with `interactive: true` — pan and zoom **enabled**, unlike the Login
backdrop. Fit to the POI bounds with 30px padding. Attribution stays visible, and
`zoomControl: true` so the zoom buttons show (the prototype's Explore map has them).

**Markers:** one `PoiPinMarker` per seeded POI, at the **POI coordinates from the map
file** — not the stop coordinates (Task-03 already enforces this distinction).

**Search pill:** floating 20px from top/left/right; `surface1`, hairline border, pill
radius, overlay shadow, 16px `Search` icon, placeholder "Search the Territory" in
`inkTertiary`. Copy stays the same; only the behaviour changes (Q6). Filtering never
moves the camera. Clearing the field, including via `Clear search`, restores all markers.

**POI info card** (bottom, 16px insets):

- 76px `PlaceholderTile`, then name (16px, weight 600), a rating line (`Star` icon, rating,
  a 3px separator dot, then `TagDot` + tag label), and the description at 12.5px
  `inkMuted`.
- A 26px circular close (`X`) button at top-right clears the selection.
- Tapping another marker **swaps the card's content**; it does not stack or open a second
  card.

**Read-only browsing.** There is no "add this POI to my route" action, no POI detail screen,
no category filtering and no user location. The card is the full extent of POI detail.

Bottom nav visible, Explore active.

## Acceptance Criteria (DoD)

- [ ] Widget test: 8 POI markers render, and a test asserts Ubirr's marker sits at `-12.4260, 132.9760` (the map-file coordinate, not the Kakadu stop's).
- [ ] Widget test: the map is interactive — a drag changes the camera, unlike the Login backdrop.
- [ ] Widget test: zoom controls are visible and functional on this map.
- [ ] Widget test: long-pressing a POI marker shows a tooltip with that POI's name.
- [ ] Widget test: tapping a marker opens the info card with that POI's name, rating and description.
- [ ] Widget test: tapping a second marker **replaces** the card's content; exactly one card is present at any time.
- [ ] Widget test: tapping the `X` closes the card and clears `selectedPoiId`.
- [ ] Widget test: the tag dot colour comes from `tagColor` — asserted for a Nature POI (green) and a Culture POI (purple).
- [ ] Widget test: the search pill renders the placeholder "Search the Territory".
- [ ] Widget test: a mixed-case name substring and a tag substring each render exactly the matching marker set; descriptions are not searched, and leading/trailing query whitespace is ignored.
- [ ] Widget test: clearing a non-empty query restores all 8 markers without changing the camera viewport.
- [ ] Widget test: a no-match query renders no POI markers plus the exact no-results copy and `Clear search`; tapping it empties the field, removes the empty state and restores all 8 markers.
- [ ] Widget test: when filtering excludes `selectedPoiId`, the single info card closes and selection clears; when the selected POI still matches, exactly one info card remains with unchanged content.
- [ ] Widget test: the bottom nav is visible with Explore active and the other three tabs in `inkTertiary`.
- [ ] `grep -rn "Places\|places_api" lib/features/explore/` returns nothing — photos are placeholder tiles in v1.
- [ ] No layout exception at 360px width with the info card open.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/explore/` returns nothing.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/explore/` exits 0.
