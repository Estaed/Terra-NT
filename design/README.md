# Terra NT Route Planner — Flutter handoff

Design handoff package for building the app natively in Flutter with Claude Code.

## Contents
- `CLAUDE.md` — project conventions and pointers for Claude Code. Moves to the repo
  root in T-00.
- `PRD.md` — full product spec: every screen, design tokens, state, data model,
  interaction behavior (swipe-to-delete, draggable sheet, reorder, car-follows-route
  map animation).
- `screenshots/` — one PNG per screen, pixel reference.
- `design-reference/` — the original prototype (HTML/React) and its map logic. Read
  for exact copy/timing/state-machine reference — not code to port line-by-line.
- `design-system/` — the token bundle `PRD.md` derives from: `styles.css` +
  `tokens/*.css`. Added 2026-08-25; it was missing from the original handoff, which is
  why `PRD.md` used to call the tag colors "see the design system bundle" with nothing
  to see. **Read `design-system/README.md` before using it** — only `tokens/` transfers
  to this app.

## Repo layout
```
Terra NT/                      ← repo root: git, docs, design, agent config
├── CLAUDE.md                  ← from this bundle (moved up in T-00)
├── README.md                  ← how to run the PIV loop
├── .claude/                   ← agents, skills, settings
├── design/                    ← this bundle, stays put
│   ├── PRD.md
│   ├── screenshots/
│   ├── design-reference/
│   └── design-system/
├── docs/tickets/              ← the 14-ticket breakdown
└── terra_nt/                  ← Flutter project — ONLY the app
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── lib/
    ├── test/
    └── android/  ios/
```

**Nothing from `design/`, `docs/`, `.claude/` or `README.md` goes under `terra_nt/`.**
The Flutter project holds the app and nothing else; the docs live at the repo root,
outside anything the analyzer or build treats as source. Claude Code still picks up the
root `CLAUDE.md` when the working directory is `terra_nt/`, since it reads parent
directories.

Run all Flutter and Dart commands from `terra_nt/`. Doc paths in the tickets and in
`PRD.md` are relative to the repo root — from inside `terra_nt/` that is `../design/…`.

## Suggested order of work
0. Create the Flutter project at `terra_nt/` and settle the repo layout (T-00).
1. App shell, navigation, theme/design tokens (`PRD.md` → Design tokens).
2. Auth + onboarding flow (15 steps).
3. Itinerary generation + result screen (map, edit mode, reorder, export).
4. Stop detail screen.
5. Explore map + POI selection.
6. Saved routes + swipe-to-delete + auto-save on generate.
7. Profile + delete-account confirm flow.
8. Car-follows-route map animation (shared by login ambient loop + onboarding).
