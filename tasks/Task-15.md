# Task-15 — Stop detail screen

Status: DONE

> **Execution:** agent `codex`, then in the main loop `review-visual` · effort `high` · plan mode no
> *Why:* Rerouted 2026-09-07. One screen riding patterns Task-13 already established,
> with D7's Navigate action delegating to Task-04's URL builder. Reports as
> **green, review-visual pending**.

**Lane**
- OWNS: `terra_nt/lib/features/itinerary/stop_detail/`, `terra_nt/test/features/itinerary/stop_detail/`
- MUST NOT TOUCH: `terra_nt/lib/features/itinerary/` outside `stop_detail/` (Task-13 owns the frame, Task-14 the list), `terra_nt/lib/core/util/` (Task-04), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/itinerary/`
- DEPENDS ON: Task-13

## Objective

Build the pushed detail screen for one stop, including the skip toggle that Task-14's list
renders, and the "Navigate" action that the prototype leaves dead.

## Execution Guide

**Files:** `terra_nt/lib/features/itinerary/stop_detail/`.
Source: `Terra NT.dc.html` L524–572.

**Layout, top to bottom:**

1. **260px `PlaceholderTile` hero** (Task-02) with the back button (`ArrowLeft`) overlaid.
   Back returns to Result.
2. Name and subtitle.
3. Tag chips — `TagDot` + label, colour from Task-04's `tagColor`.
4. **Info card:** an "Hours" row, and a "Park entry fee" row that renders **only when the
   stop has a fee**. When `fee` is null the row is omitted entirely — not rendered empty,
   not rendered with a placeholder.
5. **AI-note callout** with the `Zap` icon.
6. **Footer:** secondary Skip/Unskip + primary "Navigate".

**Skip/Unskip:**

- The label is `"Skip"` when the stop is not skipped and `"Unskip"` when it is.
- Tapping toggles the flag and **returns immediately to Result**, where the row now renders
  at 0.5 opacity (or full again after Unskip).
- The state lives in `ItineraryNotifier` (Task-05), keyed by the stop's **original index**,
  so it survives leaving and re-entering, and is unaffected by reordering.

**"Navigate" (Decision D7):** the prototype's button has no handler. Here it launches a
single-destination Google Maps URL for this stop via Task-04's `singleDestinationUrl` and
`url_launcher`. It reuses the export machinery rather than building a second URL path.

**No bottom nav** — this sits on top of the Plan AI tab's stack.

## Acceptance Criteria (DoD)

- [x] Widget test: name, subtitle, hours and AI note render verbatim from the seeded stop.
- [x] Widget test: a stop **with** a fee renders the "Park entry fee" row with its value; a stop **without** one renders no fee row at all — asserted on both Darwin (`fee == null`) and Litchfield (`"Free entry"`).
- [x] Widget test: the footer secondary button reads "Skip" when not skipped and "Unskip" when skipped.
- [x] Widget test: tapping Skip toggles the flag **and** pops back to Result in one action.
- [x] Widget test: after skipping, the Result row for that stop renders at 0.5 opacity; after unskipping, at full opacity.
- [x] Widget test: skipped state survives leaving and re-entering the screen.
- [x] Widget test: skipped state is keyed to the stop, not the position — reordering the list does not move the skip to a different stop.
- [x] Widget test: "Navigate" passes a single-destination URL containing this stop's coordinates to a faked launcher.
- [x] Widget test: back returns to Result, and the screen renders no bottom nav.
- [x] No layout exception at 360px width with the longest seeded strings (Darwin's Mindil Beach hours line is the longest).
- [x] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/itinerary/stop_detail/` returns nothing.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/features/itinerary/` exits 0.
