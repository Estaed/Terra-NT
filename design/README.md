# Terra NT Route Planner — Flutter handoff

Design handoff package for building the app natively in Flutter with Claude Code.

## Contents
- `CLAUDE.md` — drop at the Flutter repo root (or merge into an existing one). Project
  conventions and pointers for Claude Code.
- `PRD.md` — full product spec: every screen, design tokens, state, data model,
  interaction behavior (swipe-to-delete, draggable sheet, reorder, car-follows-route
  map animation).
- `screenshots/` — one PNG per screen, pixel reference.
- `design-reference/` — the original prototype (HTML/React) and its map logic. Read
  for exact copy/timing/state-machine reference — not code to port line-by-line.

## Suggested repo layout
```
terra_nt/                      ← Flutter project root
  CLAUDE.md                    ← from this bundle
  docs/
    PRD.md                     ← from this bundle
    screenshots/               ← from this bundle
    design-reference/          ← from this bundle
  lib/
  ...
```
Keep `docs/` out of anything the analyzer/build treats as source (it already is,
by living outside `lib/`).

## Suggested order of work
1. App shell, navigation, theme/design tokens (`PRD.md` → Design tokens).
2. Auth + onboarding flow (15 steps).
3. Itinerary generation + result screen (map, edit mode, reorder, export).
4. Stop detail screen.
5. Explore map + POI selection.
6. Saved routes + swipe-to-delete + auto-save on generate.
7. Profile + delete-account confirm flow.
8. Car-follows-route map animation (shared by login ambient loop + onboarding).
