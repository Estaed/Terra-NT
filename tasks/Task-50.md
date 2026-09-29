# Task-50 — Content enters instead of popping in; buttons answer the touch

> **Execution:** agent `ultracode` · effort `xhigh`
> *Why:* Applying one shared primitive across several screens, with a press state on the
> shared button; judged by eye and guarded by the widget suite.

**Lane**
- OWNS: `terra_nt/lib/features/itinerary/widgets/`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart`, `terra_nt/lib/features/saved/saved_routes_screen.dart`, `terra_nt/lib/features/explore/explore_screen.dart`, `terra_nt/lib/features/onboarding/steps/onboarding_steps.dart`, `terra_nt/lib/shared/widgets/app_button.dart`, `terra_nt/lib/core/theme/app_theme.dart` (page transitions only), `terra_nt/test/features/itinerary/`, `terra_nt/test/features/saved/`, `terra_nt/test/features/explore/`, `terra_nt/test/features/onboarding/steps/`, `terra_nt/test/shared/widgets/app_button_test.dart`, `terra_nt/test/core/theme/`, `terra_nt/test/integration/itinerary_profile_test.dart`, `terra_nt/test/integration/explore_map_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/shared/widgets/entrance.dart` (use it, do not change it), `terra_nt/lib/core/theme/motion.dart`, `terra_nt/lib/core/theme/colors.dart`, `terra_nt/assets/`, `terra_nt/pubspec.yaml`, `terra_nt/lib/features/loading/`, `terra_nt/lib/features/auth/`, `terra_nt/lib/features/onboarding/onboarding_screen.dart`, `terra_nt/lib/features/onboarding/widgets/`, `terra_nt/lib/shared/map/`, `docs/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: none (`Entrance` and the tokens are committed before `BASE_SHA`)

## Goal

Screens stop appearing all at once: lists and cards arrive with a short staggered fade-and-rise,
pushed screens transition smoothly, and a pressed button visibly responds — the difference
between a prototype and a product.

## Why

Operator, 2026-09-29: "uygulamaya animasyonlar ekleyelim", the app looks amateur
(`docs/PRD.md` D18). Today nothing in the app moves except the map car and Loading.

## Direction — the contract is the outcome, the route is yours

1. Use `Entrance` (`lib/shared/widgets/entrance.dart`: fade + 12 px rise, `index` staggers,
   capped, honours reduce-motion) on: Result's stop cards and header, the Plan AI empty state,
   Saved Routes' cards and its empty state, Explore's POI card when it appears (and when the
   selection changes), the onboarding options of each step as the step arrives, and Stop
   detail's content below the hero. Not on every widget — on the units a user reads as
   "things arriving".
2. `AppButton`: a pressed state that scales to `AppMotion.pressScale` over `AppMotion.fast`
   and back, without changing layout, disabled buttons excluded.
3. Page transitions: pushed routes (Stop detail, Account, Language, Create account) use one
   consistent, quiet transition on Android and iOS through `ThemeData.pageTransitionsTheme`
   (for example a fade-through or the platform's zoom), not the default slide from the left
   edge of a white page.
4. No new duration, curve or colour: `AppMotion.entrance*`, `pressScale`, `easeEmphasized`,
   `fast`, `base`, `slow` exist for this. No bounce, no overshoot, no parallax.
5. Behaviour and timing stay: V12, the 320 ms step slide, swipe-to-delete, the sheet snaps,
   Back behaviour. Widget tests that looked for content right after a pump may need a
   `pump(AppMotion.entrance…)`; never weaken what a test asserts.

## Acceptance Criteria (DoD)

- [ ] A widget test shows Result's first stop card starting below full opacity and fully shown
      after the entrance; one for Saved Routes' cards.
- [ ] A widget test holds an `AppButton` down and finds a `Transform`/`ScaleTransition` at
      `AppMotion.pressScale`, released back to 1.
- [ ] `ThemeData.pageTransitionsTheme` is set for Android and iOS.
- [ ] `cd terra_nt && flutter analyze` is clean; `cd terra_nt && flutter test` passes.
- [ ] (eye) On the emulator: Result, Saved, Explore card, an onboarding step and Stop detail
      animate in; nothing flickers, nothing waits more than ~0.6 s to appear.
