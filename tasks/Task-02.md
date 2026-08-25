# Task-02 — Shared design-system widgets

## Objective

Rebuild the component layer the prototype imports but never ships. `Button`, `TextInput`
and `Icon` come from `_ds_bundle.js`, which is **not in the repo** (`docs/PRD.md` §2, gap
3), so their internals are not recoverable — they must be reconstructed from Task-01's
tokens. Every screen task after this one composes these instead of styling from scratch.

## Execution Guide

**Files:** `terra_nt/lib/shared/widgets/`.

Build only what the prototype actually uses. Counted usages: `Button` ×14, `Icon` ×41,
`TextInput` ×2. Adding a component no screen needs is a Part 1 rule 2 violation.

| Widget | Reconstructed from |
|---|---|
| `AppButton` | Variants `primary` / `secondary`, size `lg`, optional `fullWidth`. Padding 8×14px, `AppRadius.md` (8px). Primary = `actionPrimaryBg` on `actionPrimaryFg`; secondary = `actionSecondaryBg` over `borderCard`. |
| `AppTextInput` | Label above field, padding 8×12px, `AppRadius.md`, hairline border, focus ring = 2px `primaryFocus` at 50% opacity. Supports `obscureText` and an error slot (Task-09 fills the copy). |
| `AppIcon` | Thin wrapper over `flutter_lucide`. Outline only, 2px round caps, `currentColor`, **never filled**. Takes size and colour; defaults to inheriting. |
| `AppChip` | The prototype's `chipStyle(selected)`: selected = `surface2` / `ink` / `hairlineStrong`; unselected = `surface1` / `inkSubtle` / `hairline`. Used by onboarding options, segmented controls and the edit toggle. |
| `AppPillBadge` | 2×8px padding, pill radius, `surface2`, hairline border, 11px caption, `inkTertiary`. This is the "NT-specific" badge. |
| `TagDot` | 5px circle + label. Takes its colour as a **parameter** — it does not know the tag→colour mapping. Callers pass it (from Task-04's `tagColor`, once that exists). |
| `PlaceholderTile` | The icon-in-box treatment used wherever a photo would go: `surface2`, hairline border, centred `Image` icon. Parameterised by size — 76px on Explore, 260px-tall hero on Stop detail, thumbnail on Saved Routes. |
| `SettingsRow` | Icon + label + optional value + optional chevron. Profile, Account and Language all use it. |

**Hover and press states:** the design system's rule is that hover *lightens* and press is
colour-only — no scale, no translate. On a phone build only the pressed state is
reachable, so implement press and leave hover to the token values.

**Nothing here reads app state.** These are presentational widgets taking parameters. Part
2 tier 3: widgets never own app state.

## Acceptance Criteria (DoD)

- [ ] `lib/shared/widgets/` contains the eight widgets in the table and no others.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/shared/` returns nothing — no colour literal outside `core/theme/`.
- [ ] `grep -rnE "EdgeInsets\.(all|symmetric|only)\([^)]*[0-9]" lib/shared/` shows only values sourced from `AppSpacing` constants (no bare numeric literals for padding).
- [ ] Widget test: `AppButton` renders its child, invokes `onPressed` on tap, and renders differently for `primary` vs `secondary` (assert on the resolved background colour, not on a screenshot).
- [ ] Widget test: `AppTextInput` with `obscureText: true` hides input, and its error slot renders supplied text when non-null and occupies no space when null.
- [ ] Widget test: `AppChip` resolves the selected/unselected colour triple exactly as the table specifies.
- [ ] Widget test: `PlaceholderTile` renders at the size passed and contains the `Image` icon.
- [ ] `TagDot` takes a `Color` parameter and imports nothing from `core/util/` — `grep -n "core/util" lib/shared/widgets/tag_dot.dart` returns nothing.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test` exits 0.

## Note on visual criteria

Per `docs/PRD.md` Q1 (unresolved), no acceptance criterion in this task asserts visual
likeness — there is nothing in the repo to compare against. Criteria assert **resolved
token values and behaviour**, which are checkable in code.
