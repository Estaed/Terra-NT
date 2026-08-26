# Task-01 — Design tokens → ThemeData

**Status: DONE** — verified 2026-08-26.

## Objective

Transcribe the token bundle into `core/theme/` so that every later task references design
values **by name**. Part 2 forbids hardcoding a hex, size, radius or duration in a widget;
this task is what makes that rule followable.

Source of truth: `design/design-system/tokens/*.css`. Read
`design/design-system/README.md` first — only `tokens/` transfers to this app.

## Execution Guide

**Files:** `terra_nt/lib/core/theme/` — one file per token family, mirroring the CSS:
`colors.dart`, `typography.dart`, `spacing.dart`, `radius.dart`, `elevation.dart`,
`motion.dart`, plus `app_theme.dart` that assembles `ThemeData`.

**Transcribe, do not reinterpret.** Every custom property in the CSS becomes a named Dart
constant. Keep the CSS name recognisable: `--color-surface-1` → `AppColors.surface1`,
`--radius-card` → `AppRadius.card`, `--duration-base` → `AppMotion.base`. A reviewer must
be able to diff the Dart against the CSS by eye.

**Semantic aliases are aliases, not copies.** `--bg-card: var(--color-surface-1)` becomes
`AppColors.bgCard = AppColors.surface1`, referencing the same constant. Duplicating the
hex defeats the point — a correction must stay a one-line change.

**The six `--tag-*` colours are provisional** (`docs/PRD.md` Q7). Define them as named
constants for exactly that reason. Do not inline them anywhere.

**Typography:** the CSS defines 13 type roles as
`--type-<role>-{family,size,weight,leading,tracking}`. Model a role as one Dart object
producing a `TextStyle`. Note two things from `docs/PRD.md` §2: tracking is aggressively
negative on display sizes and **positive (+0.4px) on the eyebrow role only**; and the
desktop display sizes (80/56/40px) belong to the marketing site — this app's largest is
44px. Carry the family/weight/tracking ramp, not the desktop sizes.

**`app_theme.dart`** wires the dark `ThemeData`: canvas as `scaffoldBackgroundColor`, the
font families from Task-00's bundled assets, and the text theme from the roles. There is
**no light theme** — do not define one.

**Elevation:** depth is surface-step plus 1px hairline. The only shadow is
`--shadow-overlay`; also carry the focus ring and the 1px inset edge highlight.

## Acceptance Criteria (DoD)

- [x] `lib/core/theme/` contains `colors.dart`, `typography.dart`, `spacing.dart`, `radius.dart`, `elevation.dart`, `motion.dart`, `app_theme.dart`.
- [x] Every custom property in `design/design-system/tokens/colors.css` has a corresponding named constant, including all six `--tag-*` values.
- [x] `test/core/theme/tokens_test.dart` asserts the exact value of at least: `canvas` = `#010102`, `surface1` = `#0f1011`, `primary` = `#5e6ad2`, `ink` = `#f7f8f8`, `inkTertiary` = `#62666d`, `hairline` = `#23252a`, `success` = `#27a644`, and all six tag colours.
- [x] Semantic aliases reference their base constant rather than repeating a literal — verified by `grep -c "0xFF" lib/core/theme/colors.dart` being no greater than the number of *base* colour tokens in the CSS.
- [x] A test asserts the 13 type roles exist and that the eyebrow role's letter-spacing is positive while at least one display role's is negative.
- [x] `AppMotion` defines 80/120/160/240 ms and both easing curves.
- [x] No light `ThemeData` is defined anywhere: `grep -rn "Brightness.light" lib/` returns nothing.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test` exits 0.
