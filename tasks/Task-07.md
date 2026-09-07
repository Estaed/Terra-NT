# Task-07 — Map foundation: flutter_map, CARTO tiles, marker widgets

Status: DONE

> **Execution:** agent `codex`, then in the main loop `review-visual` · effort `high` · plan mode no
> *Why:* Rerouted 2026-09-07. The `flutter_map` wiring is prescribed and every
> acceptance criterion is a command or a code assertion — Q1 forbids a visual one.
> The eye check is a separate advisory step afterwards, so this reports as
> **green, review-visual pending**, never plain green.

**Lane**
- OWNS: `terra_nt/lib/shared/map/`, `terra_nt/test/shared/map/`
- MUST NOT TOUCH: `terra_nt/lib/shared/widgets/` (Task-02), `terra_nt/lib/data/` (Task-03, Task-05), `terra_nt/lib/app/` (Task-06), `terra_nt/lib/features/` (the screen tasks), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/shared/map/`
- DEPENDS ON: Task-03

## Objective

Build the shared map layer all three map surfaces sit on. The prototype runs Leaflet in
iframes and talks to it over `postMessage`; **Part 2 forbids WebView or iframe — native
widgets only**, and the messaging plumbing does not survive the port. Marker taps become
ordinary widget callbacks.

## Execution Guide

**Files:** `terra_nt/lib/shared/map/`.

**`TerraMap`** — one configurable base widget over `FlutterMap`:

- Tile layer: `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png`,
  subdomains `abcd`, `maxZoom` 19. This is the same source all three prototype maps use,
  which is why fidelity is exact rather than approximated.
- **Attribution must be visible** — "© OpenStreetMap © CARTO". This is a licensing
  requirement, not styling; do not hide it to clean up the layout.
- `interactive` flag: `false` reproduces the Login backdrop (the prototype disables
  dragging, touch zoom, scroll wheel, double-click, box zoom, keyboard and tap —
  `terra-nt-bg-map.html` L40–41); `true` for Explore and Result.
- Background colour while tiles load is `surface1`, matching the prototype's `#0f1011`.
- Fit-to-bounds helper with the padding each surface uses: 26px backdrop, 30px Explore,
  28px Result.
- **Zoom controls:** hidden on the backdrop (`zoomControl: false`), **visible on Explore and
  Result** (`zoomControl: true`). `flutter_map` ships no zoom buttons, so this is a small
  overlay widget — two stacked buttons using `surface1` + hairline, matching the search
  pill's treatment.
- **Marker tooltips:** the prototype binds a name tooltip to every Explore POI pin and every
  Result numbered pin, positioned above the marker with an 8–10px offset. On a touch device
  a hover tooltip has no trigger, so bind it to **long-press** rather than dropping it.

**Marker widgets** (plain Flutter widgets — this is what `flutter_map` buys us):

| Widget | Spec |
|---|---|
| `RouteDotMarker` | 8px `primary` circle at 85% opacity with a 3px `rgba(94,106,210,.18)` ring. Backdrop route points. |
| `NumberedPinMarker` | 26px pin carrying its 1-based position number. Result screen. |
| `PoiPinMarker` | 30px pin with a selected state. Explore. |

**`DashedRoutePolyline`** — `primary`, 3px weight. The prototype uses `dashArray '1,7'` on
the backdrop and `'1,6'` on the Result map, at 0.75 and 0.85 opacity respectively. Keep
both as parameters rather than hardcoding one.

**Design values come from Task-01 tokens.** The hex values quoted above are from the
prototype for identification only — reference `AppColors.primary`, not a literal.

**No state here.** `TerraMap` takes markers, polylines and callbacks as parameters. Tier 3:
widgets never own app state.

## Acceptance Criteria (DoD)

- [x] `grep -rn "WebView\|webview\|InAppWebView\|iframe" lib/` returns nothing.
- [x] `grep -rn "postMessage" lib/` returns nothing.
- [x] `grep -rnE "0x[0-9a-fA-F]{8}" lib/shared/map/` returns nothing.
- [x] The tile URL template in code matches the prototype's CARTO `dark_all` URL exactly — asserted by a test comparing against the literal string.
- [x] Widget test: `TerraMap` renders an attribution widget containing both "OpenStreetMap" and "CARTO".
- [x] Widget test: with `interactive: false`, drag and scale gestures do not change the camera; with `interactive: true`, they do.
- [x] Widget test: `NumberedPinMarker` renders the number passed to it; passing 3 renders "3".
- [x] Widget test: `PoiPinMarker` invokes its `onTap` callback, and renders a visibly distinct selected state (asserted on the resolved colour, not a screenshot).
- [x] Widget test: `TerraMap` given N markers renders N marker widgets.
- [x] Widget test: zoom controls render when `zoomControl: true` and are absent when false; tapping them changes the camera zoom.
- [x] Widget test: long-pressing a marker shows a tooltip carrying that marker's name; it is absent before the press.
- [x] No layout exception at 360px width: `TerraMap` renders with markers and zoom controls at that width — the test pumps it and asserts no `FlutterError` was recorded.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/shared/map/` exits 0.
