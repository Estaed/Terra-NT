# Task-17 — Saved Routes: list, swipe-to-delete, empty state

## Objective

Build the Saved Routes tab, including the hand-rolled swipe-to-delete gesture. Part 2
forbids `flutter_slidable` here: the spec is absolute pixels and Slidable's thresholds are
screen fractions, so bending it to hit exact px is more code than a `GestureDetector` over
Task-04's already-tested snap functions.

## Execution Guide

**Files:** `terra_nt/lib/features/saved/`.
Sources: `Terra NT.dc.html` L573–612, gesture logic L1032–1064.

**Route card:** `PlaceholderTile` thumbnail, title, meta, relative date label, chevron.

### Swipe-to-delete

A red delete button (`Trash2`) sits **pinned behind** the row; the row translates over it.
All thresholds come from Task-04's `swipe_snap`:

- Track horizontal drag from pointer-down; offset is `clampOffset(base + delta)` → −76…0.
  It must **not** track right-swipes past 0.
- On release, `isOpenAfterRelease(offset)` decides: open snaps to −76, closed to 0. The
  boundary is −38 — `-38` closes, `-39` opens.
- **Only one row open at a time** — opening a second closes the first.
- Transition is `none` while dragging, 200 ms `ease-out` on release.

**Tap handling — three cases, in order:**

1. If the pointer moved more than 4px (`didMove`), it was a drag → **do not navigate**.
2. Else if this row is open → **close it**, do not navigate.
3. Else → open that route on the Result screen.

Tapping the red button deletes immediately — **no confirmation, no undo, no snackbar** —
and resets the swipe state.

### What a route opens

- The generated entry (`generated-trip`) opens the seeded 7-stop itinerary.
- **"7 Days in the Red Centre" opens its own 4-stop itinerary** (D8) via
  `ItineraryRepository.itineraryForSavedRoute`. This is what makes Result data-driven
  rather than hard-wired to one list. *(Depends on Task-03's `redCentreStops`, which is
  blocked on Q3 — if that is still unanswered, this task cannot complete.)*

### Empty state

`Bookmark` icon, "No saved routes yet", "Generate an itinerary with Plan AI and it'll show
up here.", and a "Plan Your First Route" button that switches to the Plan AI tab.

Bottom nav visible, Saved Routes active.

## Acceptance Criteria (DoD)

- [ ] `grep -rn "flutter_slidable\|Slidable" lib/` returns nothing.
- [ ] Widget test: dragging left reveals exactly 76px of the delete button; dragging right from rest keeps the offset at 0.
- [ ] Widget test: releasing at −38 snaps **closed**; releasing at −39 snaps **open**. Both asserted.
- [ ] Widget test: opening a second row closes the first — at most one row is open.
- [ ] Widget test: a tap after a >4px drag does **not** navigate.
- [ ] Widget test: tapping an open row closes it and does **not** navigate.
- [ ] Widget test: tapping a closed row opens Result.
- [ ] Widget test: tapping the red button removes that route immediately, with no confirmation dialog and no snackbar, and resets the swipe offset to 0.
- [ ] Widget test: deleting every route reveals the empty state with all four elements, and "Plan Your First Route" switches to the Plan AI tab.
- [ ] Widget test: the seeded pair renders with titles "Full NT: Darwin to Uluru" and "7 Days in the Red Centre" and their exact meta and date strings.
- [ ] Widget test: opening "7 Days in the Red Centre" loads a **4-stop** itinerary, not the 7-stop one (D8).
- [ ] Widget test: an auto-saved `generated-trip` entry appears at the top of the list.
- [ ] Widget test: deletions persist — after deleting and rebuilding from `PreferencesStore`, the route is still gone.
- [ ] The widget calls `swipe_snap` rather than inlining thresholds: `grep -rn "clampOffset\|isOpenAfterRelease\|didMove" lib/features/saved/` matches.
- [ ] No layout exception at 360px width with a row swiped open.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/saved/` exits 0.
