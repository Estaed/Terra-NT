# Task-49 — Loading looks like a route being planned, not a placeholder
**Status: DONE** — verified 2026-09-29 17:05 (ultracode lane, 1 fix round: route kept clear of the status bar; gate green on main, 573 tests; emulator tour)

> **Execution:** agent `ultracode` · effort `xhigh`
> *Why:* One screen with timers and failure states already tested; the change is visual and
> judged by eye on the emulator, with the existing behaviour tests as the guard.

**Lane**
- OWNS: `terra_nt/lib/features/loading/`, `terra_nt/test/features/loading/`
- MUST NOT TOUCH: `terra_nt/lib/core/theme/` (Task-48 owns `metrics.dart` this wave: a new size goes in a named `static const` at the top of the screen class, commented `// → metrics at integration`), `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `terra_nt/lib/shared/`, `terra_nt/lib/features/onboarding/`, `terra_nt/lib/data/`, `docs/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: none

## Goal

The 7-to-60-second wait feels like Terra NT working on the user's trip: the Territory map
alive behind the content, the brand mark instead of a flat purple disc, the rotating messages
crossfading, and Cancel looking like a button instead of an underlined web link.

## Why

Operator, 2026-09-29 (`docs/PRD.md` D18): the app looks amateur. With the real planner a
generation takes 30–45 s, so Loading is now the screen users look at longest. Current state:
`reports/screens/2026-09-29-tour/tour-02-loading.png`.

## Direction — the contract is the outcome, the route is yours

1. **Backdrop:** the same ambient map the auth screens use (`RouteCarBackdrop` / the
   `TerraMap` backdrop in `lib/shared/map/`, read-only here) behind a scrim so the text stays
   readable; it must render without network (tiles missing is fine — the car and route still
   move).
2. **Centre:** `assets/images/brand_mark.png` (the app icon's route-and-pin artwork,
   transparent, committed) in place of the disc, with the existing pulse tokens
   (`AppMotion.loadingPulse*`) turned into a soft halo or breathing scale — restrained, no
   bounce.
3. **Messages:** the five rotating messages crossfade (`AppMotion.slow` or `base`) instead of
   swapping.
4. **Cancel and failure buttons:** use the app's own `AppButton` variants (secondary or ghost),
   no underline.
5. Everything else stays: V1's 7000 ms on success, cancel/failure/retry behaviour and copy
   (`docs/PRD.md` §3.4), Back = Cancel, the looping progress bar (Task-48 restyles it; keep
   using `ProgressDrive.looping`).
6. Tokens by name only; no new colour, gradient beyond the scrim, glow or coloured shadow.

## Acceptance Criteria (DoD)

- [ ] Every existing Loading test passes unchanged in intent (timings, cancel, retry,
      failure copy, Back = Cancel); a test finds the brand mark image and no plain disc.
- [ ] Cancel is an `AppButton` (widget test).
- [ ] `cd terra_nt && flutter analyze` is clean; `cd terra_nt && flutter test` passes.
- [ ] (eye) On the emulator Loading shows the moving map behind a scrim, the mark breathing,
      messages crossfading, and reads as finished product next to Result.
