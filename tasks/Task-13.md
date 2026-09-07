# Task-13 — Result screen: map panel, draggable sheet, header, export

> **Execution:** agent `codex`, then in the main loop `review-visual` · effort `high` · plan mode no
> *Why:* Rerouted 2026-09-07. Several surfaces, but the Execution Guide names each
> one: absolute sheet anchors 190/430/700 delegating to Task-04's `nearestSnap`,
> `DraggableScrollableSheet` forbidden and grepped for, and V2/V4/V5 each spelled
> out. Reports as **green, review-visual pending**.

**Lane**
- OWNS: `terra_nt/lib/features/itinerary/`, `terra_nt/test/features/itinerary/`
- MUST NOT TOUCH: `terra_nt/lib/features/itinerary/widgets/` (Task-14 owns the stop list) and `terra_nt/lib/features/itinerary/stop_detail/` (Task-15), `terra_nt/lib/core/util/` (Task-04), `terra_nt/lib/shared/map/` (Task-07), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/itinerary/`
- DEPENDS ON: Task-04, Task-05, Task-06, Task-07

## Objective

Build the Result screen's frame — the route map, the draggable sheet and its header
controls — with the stop list stubbed. Task-14 fills the list in. The split keeps the
sheet's drag mechanics and the list's reorder mechanics in separate test suites.

## Execution Guide

**Files:** `terra_nt/lib/features/itinerary/`.

### Map panel (top 340px)

`TerraMap` from Task-07, `interactive: true`, `zoomControl: true`, with
`NumberedPinMarker`s and a dashed polyline at `dashArray '1,6'`, opacity 0.85, fitted with
28px padding. Each pin carries its stop's name as a long-press tooltip.

**Deviation V5:** pins are built from the **live order**, so reordering renumbers them and
removing a stop removes its pin. The prototype's map is a fixed 1–7 iframe that never
updates. Drive the markers off the same `ItineraryNotifier.order` the list uses — one
source, not two.

> The prototype's `terra-nt-map.html` also handles a `tnt-focus` fly-to message that
> nothing ever sends. It is dead code. Do **not** implement fly-to in this task; it is not
> in `docs/PRD.md` scope.

### Draggable sheet

**Part 2 forbids `DraggableScrollableSheet` here** — its snap sizes are fractions of screen
height and this spec is absolute pixels. Build a height-driven panel: `GestureDetector` on
a grabber handle updating a height value, with an `AnimatedContainer`-style transition on
release.

- The nominal anchors remain **190 / 430 / 700px**. Compute usable height after top and
  bottom system insets. When it is below 700, clamp the top anchor and drag ceiling to
  that height; keep 190 and 430 unchanged whenever they fit and coalesce anchors that do
  not. Pass the usable height to Task-04's `nearestSnap`; do not reimplement it here.
- Transition is disabled while dragging and 220 ms `ease-out` on release.

### Sheet header

1. **Title** — read from `Itinerary.title` (Task-03), **never a string literal in this
   widget**. In phase 1 that value happens to be "Full NT: Darwin to Uluru" because there is
   one seeded itinerary; in phase 3 the model supplies it. A literal here would force phase
   3 to edit this screen, which `docs/PRD.md` §5 forbids.
2. **Meta — derived, never hard-coded (Deviation V2).** Use Task-04's `derivedMeta(stopCount,
   days)` so it always agrees with the Saved Routes entry. The prototype hard-codes
   `"7 stops · 8 days"` even after a stop is removed.
3. **Segmented control** Highlights / Detailed via `AppChip`. It reads and writes
   **`answers.detailed`** — the same value onboarding step 9 set. One value, not two.
4. **"Edit Route" toggle** — flips label to "Done" and icon `Pencil` → `Check`, with
   selected chip styling while active.
5. **Primary "Export to Google Maps"** — calls Task-04's URL builder and launches via
   `url_launcher`. Skipped stops are excluded (**V4**). No-ops below 2 stops.
6. **"Restore N removed stop(s)"** link — rendered only when something is removed. Wiring
   is Task-14's; render the slot here.

Bottom nav visible, Plan AI active.

## Acceptance Criteria (DoD)

- [ ] `grep -rn "DraggableScrollableSheet" lib/` returns nothing.
- [ ] Widget test: with at least 700px usable height, dragging the handle beyond either bound clamps the height to 190 and 700.
- [ ] Widget test: releasing at 300 snaps to 190; at 320 snaps to 430; at 310 snaps to **190** (tie → lower).
- [ ] Widget test: with 600px usable height, the anchors are 190 / 430 / 600, dragging cannot exceed 600, and the sheet remains scrollable at the clamped top anchor. With at least 700px usable height, the nominal 700 anchor is unchanged.
- [ ] Widget test: the sheet delegates to `nearestSnap` — `grep -n "nearestSnap" lib/features/itinerary/` matches.
- [ ] Widget test: the title renders `Itinerary.title` — asserted by injecting an itinerary with a **different** title and a **different** stop count, and seeing both reflected. `grep -rn "Full NT: Darwin to Uluru" lib/features/` returns nothing.
- [ ] Widget test: the meta is derived — with `days = 5` and 7 stops it reads `"5 days · 7 stops"`; after removing one stop it reads `"5 days · 6 stops"`.
- [ ] Widget test: the meta shown here equals the `meta` on the `generated-trip` entry held by `SavedRoutesNotifier` (the entry Task-12 upserts — the Saved Routes *screen* does not exist yet).
- [ ] Widget test: toggling the segmented control writes `answers.detailed`, and a value set during onboarding is already reflected when the screen opens.
- [ ] Widget test: the edit toggle flips its label between "Edit Route" and "Done".
- [ ] Widget test: export builds the expected URL for the current order and passes it to a faked launcher; with one stop it does not launch.
- [ ] Widget test: export omits a skipped stop from the URL (V4).
- [ ] Widget test: the map renders one numbered pin per stop in the current order; after a reorder the numbering follows position, and after a removal there is one fewer pin (V5).
- [ ] Widget test: zoom controls are visible, and long-pressing a numbered pin shows that stop's name.
- [ ] `grep -rn "tnt-focus\|flyTo" lib/` returns nothing.
- [ ] No layout exception at any nominal or usable-height-clamped snap height.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/itinerary/` returns nothing.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/itinerary/` exits 0.
