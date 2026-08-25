# Terra NT Design System — token bundle

The authoritative token values behind `docs/PRD.md` → Design tokens. Pulled from the Claude
Design project on 2026-08-25 (`_ds/terra-nt-design-system-987a6ab7-8eb5-4860-9137-4514d98e8a43/`).
This is the bundle `docs/PRD.md` referred to but that was **not** part of the original handoff.

## What is here

| File | Contents |
|---|---|
| `styles.css` | Entry point — `@import` lines only. |
| `tokens/colors.css` | Canvas, 4-step surface ladder, 3 hairlines, 4-step ink ladder, primary + hover + press, success, inverse, and the **6 product tag hexes**. |
| `tokens/typography.css` | 13 type roles as `--type-<role>-{family,size,weight,leading,tracking}`. |
| `tokens/spacing.css` | 4·8·12·16·24·32·48·96 scale + component paddings. |
| `tokens/radius.css` | 4 → 24px plus pill, with semantic aliases. |
| `tokens/elevation.css` | Surface/border recipes per level, focus ring, edge highlight, overlay shadow. |
| `tokens/motion.css` | Durations + easings. **House defaults, not brand-documented** — see below. |
| `tokens/fonts.css` | Font families and the Google Fonts substitution. |
| `tokens/base.css` | Document defaults (dark canvas, body type, link colours, focus ring). |

## What transfers to the Flutter app — and what does not

**Read this before treating the upstream design system as a spec for this app.**

Upstream, this system documents the **Terra NT marketing website** for a different
product — an issue tracker. Its component inventory (`PricingCard`, `TopNav`, `Footer`,
`PricingTabs`, `ChangelogRow`, …), its desktop breakpoints (1440/1280/1024/768/480), its
1280px container and 56px sticky nav, and its marketing copy rules describe that website.
None of it describes the route-planner phone app.

- **Transfers:** everything in `tokens/` — the colour ladders, type roles, spacing scale,
  radii, elevation recipes, motion values. These are the numbers `ui/core/theme/` defines.
- **Transfers as a rule, not a value:** the restraint rules — lavender is scarce (brand
  mark, one primary CTA per section, focus ring, link emphasis, nothing else); depth is
  surface-step + hairline, never a drop shadow; hover *lightens*, never darkens; press is
  colour-only, no scale or translate; no gradients, no `backdrop-filter`, no glow, no
  light mode.
- **Does not transfer:** the component inventory, the responsive table, the marketing
  content rules, `ui_kits/`, `templates/`, `guidelines/`, `components/`. The app's own
  component list is `docs/PRD.md` + `screenshots/`. Do not port a `PricingCard`.

The app's screen spec is `docs/PRD.md`. This bundle only settles *what the numbers are*.

## Deviations this app makes on purpose

- **Card padding.** The system specifies 24px card interiors; this app uses 14–16px on
  compact mobile list rows for density. Recorded in `docs/PRD.md` → Design tokens.
- **Type scale.** The system's display roles top out at 80px for desktop hero headlines.
  The app's largest is 44px (Login). Use the roles' *family/weight/tracking ramp*, not the
  desktop sizes.

## Three substitutions to confirm

1. **Fonts.** The real Terra NT Display / Text / Mono cuts are proprietary and were never
   supplied. `tokens/fonts.css` substitutes **Inter** (400/500/600/700) and **JetBrains
   Mono** (400/500). In Flutter that means either the `google_fonts` package or bundled
   `.woff2`/`.ttf` files in `pubspec.yaml` — **decide in T-00**, because goldens are
   font-rendering-sensitive and re-deciding later invalidates every checked-in golden.
2. **Icons.** No Terra NT glyph set exists; upstream substitutes Lucide 1.33.0 —
   consistent with `CLAUDE.md` → Stack choosing `flutter_lucide`. Outline only, 2px round
   caps, `currentColor`, no fills.
3. **Product tag palette.** The six tag hexes in `tokens/colors.css` are **provisional** —
   derived from the accent hue family, not sampled from the real product. They are usable
   values, not confirmed ones. See `docs/tickets/terra-nt-route-planner.md` → decision 1.

`tokens/motion.css` carries the same caveat: the source documented no animation at all, so
the 80/120/160/240 ms durations and the two easing curves are house defaults. The app's own
timings (380 ms auto-advance, 320 ms step slide, 1.6 s pulse, 1.4 s message rotation) come
from the prototype and override these where they conflict.
