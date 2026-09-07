# Task-14 — Result screen: stop list, edit mode, reorder / remove / restore

> **Execution:** agent main loop (Claude) · effort `high` · plan mode **yes**
> *Why:* Edit mode, reorder, remove and V3's scoped revert interact; the interaction shape is the work, not the file list.

## Objective

Fill in the sheet's stop list and its two modes. This task carries **Deviation V3**, the
subtlest correction in the project: the prototype wires two differently-labelled controls to
one full-reset action, and neither label matches what it does.

## Execution Guide

**Files:** `terra_nt/lib/features/itinerary/widgets/`.

All list mutations call Task-04's `itinerary_ops` functions, which are already unit-tested.
**Do not reimplement ordering logic in the widget.**

### Stop row

Numbered badge (position, 1-based), name, subtitle, tag chips (`TagDot` + label, colour via
Task-04's `tagColor`), and a footer carrying `duration` plus the result of Task-04's
`driveNextForPosition`. Show the opened itinerary's seeded `driveNext` only when that
stop's original successor remains immediately next. If a reorder or removal creates a
different non-final leg, render `Drive time unavailable`; omit the next-leg line at the
live last stop. Never borrow legs from the global seven-stop seed.

**Highlights mode** shows one `aiNote` line per stop. **Detailed mode** shows that stop's
hour-by-hour `detailedPlan`. The mode comes from `answers.detailed` (Task-13).

### View mode vs edit mode

| | View | Edit |
|---|---|---|
| Trailing | `ChevronRight` | drag handle + revert + remove |
| Row tap | opens Stop detail | **does nothing** |
| Reorder | disabled | `ReorderableListView` |

Reordering renumbers badges 1..N by position. Each row keeps its own duration; drive-time
copy follows the truthful baseline-adjacency rule above rather than moving stale copy with
the row.

### Deviation V3 — the two restore controls are different

The prototype points both at `revertOrder()`, which resets the whole order and restores
every removed stop. That matches neither label.

- **Per-row revert icon** (`RotateCcw`) → `revertOne(order, originalIndex)`. Moves **that
  one stop** to its original index, clamped to the current list length. Other present stops
  may shift by one, but their relative order is preserved and removed stops stay removed.
  Shown **only when that stop has moved**.
- **"Restore N removed stop(s)" link** → `restoreRemoved(order, totalStops)`. Re-inserts
  **every removed stop** at its original index while preserving manual reordering of stops
  that were never removed. Does not touch per-row revert state.

Label from Task-04's `removedLabel(n)` — singular at N = 1. The link is hidden when nothing
is removed.

### Skipped ≠ removed

A **skipped** stop stays in the list at 0.5 opacity with a "Skipped" marker. A **removed**
stop leaves the list. The two states are independent and must not share a field. Skipping is
toggled from Stop detail (Task-15), not here.

## Acceptance Criteria (DoD)

- [ ] Widget test: badges renumber 1..N by position after a reorder and each row's duration still matches its own stop.
- [ ] Widget test: an unchanged baseline adjacency shows that itinerary's seeded `driveNext`; a changed non-final leg shows `"Drive time unavailable"`; the live last stop renders no next-leg line. The same assertions pass for the Red Centre itinerary's own baseline.
- [ ] Widget test: Highlights shows `aiNote`; Detailed shows the `detailedPlan` entries. Switching modes swaps them.
- [ ] Widget test: in view mode a row shows a chevron and tapping opens Stop detail; in edit mode it shows handle/revert/remove and tapping does **not** navigate.
- [ ] Widget test: reorder is only possible in edit mode.
- [ ] **V3 test — per-row revert is scoped:** with stops reordered *and* one removed, tapping a row's revert returns that stop to its clamped original index, preserves every other present stop's relative order, and **does not restore the removed stop**.
- [ ] **V3 test — restore is scoped:** with one stop removed and others manually reordered, tapping "Restore …" re-inserts the removed stop at its original index **and preserves the manual reorder** of the rest.
- [ ] Widget test: the revert icon is absent on a row sitting at its original index.
- [ ] Widget test: the restore link is hidden with nothing removed, reads `"Restore 1 removed stop"` at one, and `"…2 removed stops"` at two.
- [ ] Widget test: a skipped stop renders at 0.5 opacity, stays in the list, and removing a *different* stop does not change its skipped state.
- [ ] Widget test: skipped and removed are independent — a stop can be skipped without being removed and vice versa.
- [ ] The widget calls `itinerary_ops` rather than mutating or deriving route legs inline: `grep -rn "revertOne\|restoreRemoved\|removedLabel\|driveNextForPosition" lib/features/itinerary/` matches.
- [ ] No layout exception with the longest seeded rows at 360px width.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/itinerary/` exits 0.
