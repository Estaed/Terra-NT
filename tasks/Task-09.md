# Task-09 — Login and Welcome screens

> **Execution:** agent `codex`, then in the main loop `review-visual` · effort `high` · plan mode no
> *Why:* Rerouted 2026-09-07. Two screens whose copy, validation and routing are all
> fixed — Q5 answered the exact inline error strings on 2026-09-05. Reports as
> **green, review-visual pending**.

**Lane**
- OWNS: `terra_nt/lib/features/auth/`, `terra_nt/test/features/auth/`
- MUST NOT TOUCH: `terra_nt/lib/app/` (Task-06 owns the router), `terra_nt/lib/data/` (Task-05), `terra_nt/lib/shared/` (Task-02, Task-07), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/auth/`
- DEPENDS ON: Task-05, Task-06

## Objective

Fill in the two pre-app screens. Both sit on Task-08's animated backdrop; they differ only
in scrim and content. First task where a real screen replaces a Task-06 placeholder.

## Answered — `docs/PRD.md` Q5 (2026-09-05)

Validate **on submit only**, focus the first failing field. Email must be non-empty and
match `<something>@<something>.<something>` with no spaces → `Enter a valid email
address.` Password must be non-empty → `Enter your password.` Both render in
`AppTextInput`'s existing error slot in `--tag-red`, and clear when that field next
changes. **No "wrong password" copy and no length rule** — auth is mocked in phase 1,
so either would describe a check the build does not perform.

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
- Validation (D4 / answered Q5): validate on submit, focus the first failing field, and
  render the exact inline copy recorded above. Clear a field's error when that field changes.

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
- [ ] Validation widget test: submitting with both fields invalid renders both exact error strings and focuses Email, the first failing field.
- [ ] Validation widget test: entering a syntactically valid email clears only the email error; submitting again with an empty password focuses Password and does not navigate.
- [ ] Validation widget test: errors do not appear while typing or on blur before the first submit, and each field's error clears on that field's next edit without clearing the other field's error.
- [ ] Widget test: "Create My Route" lands on Onboarding at step 0.
- [ ] Widget test: after "Skip for Now", `onboardingDone` is true, **no saved route was created** (the list is unchanged), and the Plan AI tab opens Result rather than Login.
- [ ] Widget test: neither screen renders the bottom nav.
- [ ] The Login backdrop is non-interactive — a drag gesture over it does not move the map.
- [ ] Disposal test: popping Login leaves no active ticker (the ambient loop is infinite).
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/auth/` returns nothing.
- [ ] No layout exception at 360px width on either screen.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/auth/` exits 0.
