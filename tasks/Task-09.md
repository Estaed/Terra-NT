# Task-09 — Login and Welcome screens

> **Yürütme:** ajan ana döngü (Claude) · efor `medium` · plan modu hayır
> *Gerekçe:* Two straightforward screens against reference captures. ⛔ Q5 (validation copy) is a one-sentence answer, not a plan.

## Objective

Fill in the two pre-app screens. Both sit on Task-08's animated backdrop; they differ only
in scrim and content. First task where a real screen replaces a Task-06 placeholder.

## ⛔ Blocked on `docs/PRD.md` Q5

D4 requires Login to validate email and password, but the design specifies **no error
state, no error copy and no invalid-field styling**. `AppTextInput` already has an error
slot (Task-02). **The copy and the rules must be answered before validation ships.**
Everything else here proceeds.

## Execution Guide

**Files:** `terra_nt/lib/features/auth/`.

### Login — `Terra NT.dc.html` L46–69

- Backdrop: `RouteCarBackdrop` in **ambient** mode, under a bottom-to-top gradient scrim
  (`rgba(1,1,2,0.5)` → `0.72` at 45% → canvas at 92%).
- Content column: 64px top / 28px side / 40px bottom padding. Headline "Terra NT" at 44px
  display weight 600, tracking −1.4px; subhead "Discover the Northern Territory." at 18px
  `inkMuted`.
- Fields: `AppTextInput` Email (placeholder `you@email.com`) and Password (placeholder
  `••••••••`, obscured).
- `AppButton` primary lg full-width "Start Exploring"; an "or" divider between two 1px
  hairlines; `AppButton` secondary lg full-width "Continue with Google".

**Behaviour:**

- Both buttons call `AuthRepository` and land on Welcome.
- **"Continue with Google" is a mock** (D5, revised) — it calls `signInWithGoogle()`, which
  returns the same result as the email path. No OAuth, no package, no network.
- The typed email is stored in the session and is what Profile later displays; Profile falls
  back to `explorer@example.com` when it is empty.
- Validation (D4): format check, primary CTA disabled until valid, inline error — **copy
  blocked on Q5**.

### Welcome — `Terra NT.dc.html` L70–86

- Same backdrop, but a **flat** `rgba(1,1,2,0.42)` scrim rather than a gradient.
- One card: `surface1`, `hairlineStrong` border, card radius, overlay shadow, 28×24px
  padding. Headline "Welcome to Terra NT" (24px, tracking −0.4px); body: "Answer a few
  quick questions and we'll build a route across the Territory for you — or skip straight
  to exploring on your own."
- Two full-width buttons, 12px gap: primary "Create My Route", secondary "Skip for Now".

**Behaviour:**

- "Create My Route" → Onboarding at step 0.
- **"Skip for Now" marks onboarding done and lands on Explore.** It does **not** run the
  generator and does **not** create a saved route. The consequence is testable: the Plan AI
  tab now opens Result rather than Login.

Neither screen shows the bottom nav.

## Acceptance Criteria (DoD)

- [ ] Copy matches character-for-character: `Terra NT`, `Discover the Northern Territory.`, `Start Exploring`, `or`, `Continue with Google`, `Welcome to Terra NT`, `Create My Route`, `Skip for Now`, and the Welcome body sentence. Asserted with `find.text` on the exact strings.
- [ ] Widget test: "Start Exploring" navigates to Welcome.
- [ ] Widget test: "Continue with Google" navigates to Welcome and produces a session equivalent to the email path.
- [ ] Widget test: the email typed into the field is readable from the session afterwards.
- [ ] Widget test: "Create My Route" lands on Onboarding at step 0.
- [ ] Widget test: after "Skip for Now", `onboardingDone` is true, **no saved route was created** (the list is unchanged), and the Plan AI tab opens Result rather than Login.
- [ ] Widget test: neither screen renders the bottom nav.
- [ ] The Login backdrop is non-interactive — a drag gesture over it does not move the map.
- [ ] Disposal test: popping Login leaves no active ticker (the ambient loop is infinite).
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/auth/` returns nothing.
- [ ] No layout exception at 360px width on either screen.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/auth/` exits 0.
