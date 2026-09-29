# Task-51 — First impressions: Login, Create account and Welcome look like a product
**Status: DONE** — verified 2026-09-29 17:05 (ultracode lane, no finding at 80 or above; gate green on main, 573 tests; Login and Welcome seen in the lane's screen review)

> **Execution:** agent `ultracode` · effort `xhigh`
> *Why:* Three auth screens, judged by eye on the emulator; behaviour (auth, reset link,
> Back rules) is already under test and must not move.

**Lane**
- OWNS: `terra_nt/lib/features/auth/login_screen.dart`, `terra_nt/lib/features/auth/create_account_screen.dart`, `terra_nt/lib/features/auth/welcome_screen.dart`, `terra_nt/test/features/auth/`
- MUST NOT TOUCH: `terra_nt/lib/features/auth/auth_backdrop.dart`, `terra_nt/lib/shared/`, `terra_nt/lib/core/theme/` (Task-48 owns `metrics.dart` this wave: a new size goes in a named `static const` at the top of the screen class, commented `// → metrics at integration`), `terra_nt/lib/data/`, `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `terra_nt/lib/app/`, `docs/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: none

## Goal

The first screen a marker or a teammate sees says "finished app": a brand mark and a confident
title block, a form with clear hierarchy and rhythm, and a Welcome card that arrives rather
than appears.

## Why

Operator, 2026-09-29 (`docs/PRD.md` D18): the app looks amateur. Current state:
`reports/shots/final-01-launch.png` (Login), `final-05-welcome.png`, `final-04-form.png`
(Create account). Today Login is plain white text on the map with no brand, the form fields,
the Google button and two footer links compete at the same weight.

## Direction — the contract is the outcome, the route is yours

1. **Brand:** `assets/images/brand_mark.png` (the app icon's route-and-pin artwork, transparent,
   committed) above the "Terra NT" title on Login and Create account, sized by a named constant.
2. **Hierarchy:** title, tagline, form, primary action, divider, Google, footer links — one clear
   order with consistent spacing from `AppSpacing`; the footer links quieter than the actions.
   Copy stays character-for-character.
3. **Motion:** the title block and the form arrive with `Entrance` (`lib/shared/widgets/entrance.dart`,
   staggered by `index`); the Welcome card too.
4. Keyboard, safe-area and attribution behaviour stay as fixed on 2026-09-23 (the tests in
   `test/features/auth/` for the keyboard and the attribution must stay green unchanged in intent).
5. Tokens by name only; no new colour, gradient, glow or shadow.

## Acceptance Criteria (DoD)

- [ ] A widget test finds the brand mark image on Login and on Create account.
- [ ] Every existing auth test passes (sign-in, sign-up, reset link, Google, Back rules,
      keyboard/attribution).
- [ ] `cd terra_nt && flutter analyze` is clean; `cd terra_nt && flutter test` passes.
- [ ] (eye) Login, Create account and Welcome on the emulator, keyboard closed and open: the
      screens read as a finished product and nothing overlaps.
