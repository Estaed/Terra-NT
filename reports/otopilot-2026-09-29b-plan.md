# Otopilot plan — 2026-09-29 (b), polish pass (D18)

Operator, 2026-09-29: "uygulamanın tasarımını iyileştir, bar derken de ilerleme çubuğu dedim …
sence neler yanlış? sana bırakıyorum ve güveniyorum". Tarik Base explicitly not applied.

## What looked amateur (main-loop review of the built app)

1. The car is a small drawn icon with a blob shadow — clip-art on the progress bar, Loading and the map.
2. The onboarding progress is a thin line inside a bordered pill with a mono `15/15`.
3. Loading is a flat purple disc, a pill bar and an underlined web-style `Cancel` on black.
4. Nothing moves: every screen and list pops in at once; buttons do not react to a press.
5. Login has no brand; title, form, Google button and two footer links compete at one weight.

## Run

| | |
|---|---|
| Direction | Claude main loop → ultracode engine (Workflow). No fallback row. |
| Seats | this session (`opus`), operator present |
| SOURCE / UNTIL | `tasks` (48–51) / `done` |
| Pre-BASE main-loop commits | `Entrance` widget + test, `AppMotion.entrance*`/`pressScale`/`easeEmphasized`, `assets/images/car.png` (gpt-image-2, chroma-keyed), `assets/images/brand_mark.png` (the app icon artwork) |
| Reviews | screen lens on the emulator for every feature, run one at a time (one emulator); spec and code lenses |
| Fix loop | ≤ 3 rounds, findings ≥ 80 |

| Task | Builder | OWNS (summary) |
|---|---|---|
| 48 Road progress, car sprite | `opus`/`xhigh` | `car_glyph.dart`, `progress_drive.dart`, onboarding header, `metrics.dart` (append) |
| 49 Loading | `opus`/`xhigh` | `features/loading/` |
| 50 Motion, press states | `opus`/`xhigh` | itinerary widgets, Stop detail, Saved, Explore, onboarding steps, `app_button.dart`, page transitions |
| 51 Auth first impression | `opus`/`xhigh` | Login, Create account, Welcome |
