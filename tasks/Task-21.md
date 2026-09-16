# Task-21 — Create account screen

Status: DONE

> **Execution:** agent `codex`, then in the main loop `review-visual` · effort `high`
> *Why:* The screen mirrors Login, which is already built; copy, validation and routing are
> fixed below. Nothing here is an open architecture choice, so plan mode would only restate
> this file.

**Lane**
- OWNS: `terra_nt/lib/features/auth/`, `terra_nt/test/features/auth/`
- MUST NOT TOUCH: `terra_nt/lib/app/` (Task-06 owns the router), `terra_nt/lib/shared/` (Task-02, Task-07), `terra_nt/lib/core/theme/` (Task-01), `terra_nt/pubspec.yaml`
- ALSO EDITS, minimally: `terra_nt/lib/data/repositories/auth_repository.dart` — one new method on the existing seam, nothing else in `data/`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/auth/`
- DEPENDS ON: Task-05, Task-06, Task-09

## Why this task exists

`docs/PRD.md` §8 listed sign-up as out of scope because the prototype has no design for it.
The operator reversed that on **2026-09-10**: the app ships an account-creation path.
`docs/PRD.md` records it as decision **D11** and §3.1a specifies the screen — that section,
not this file, is the spec. This task implements it.

**The prototype does not contain this screen.** Every other screen is measured against
`design/design-reference/Terra NT.dc.html`; this one is measured against §3.1a and against
Login, whose layout it repeats exactly. Copy below is newly authored and is therefore
character-for-character binding here in the same way prototype copy is elsewhere.

## What "creating an account" can mean in phase 1

Phase 1 has no backend and exactly three `shared_preferences` keys, and a fourth is a defect
(`CLAUDE.md` → Part 2). So there is **no credential store**: `createAccount` sets the session
to the typed email, exactly as `signInWithEmail` does. The screen is real, the validation is
real, the persisted account is not. Do not add a user table, a password hash, a fourth
preferences key, or a third abstraction seam. Real accounts arrive with Firebase in phase 2.

## Execution Guide

**Files:** `terra_nt/lib/features/auth/`.

### The shared backdrop

Login and Create account paint the identical backdrop: `RouteCarBackdrop.ambient()` under
the bottom-to-top gradient scrim. That gradient is currently a private top-level in
`login_screen.dart`. Lift the backdrop-plus-scrim into one small widget inside
`lib/features/auth/` and have both screens use it. Two call sites, one visual — this is
deduplication, not speculative generality. Do not create a new folder for it.

### Create account — no prototype reference; `docs/PRD.md` §3.1a

Same vertical distribution as Login: 64px top / 28px side / 40px bottom padding, a header
block centred in the flexible space, a form column anchored to the bottom.

- Header: "Create account" in the Login headline style, one line, shrinking to fit rather
  than wrapping or overflowing. Subhead: "Start exploring the Northern Territory."
- Form column, `AppMetrics.loginFormGap` between items:
  - `AppTextInput` Email, placeholder `you@email.com`
  - `AppTextInput` Password, placeholder `••••••••`, obscured
  - `AppTextInput` Confirm password, placeholder `••••••••`, obscured
  - `AppButton` primary lg full-width "Create Account"
  - a text link, centred: "Already have an account? Sign in"

### The route into it

Login gains one centred text link below "Continue with Google", separated by
`AppMetrics.loginFormGap`: "Don't have an account? Sign up". It pushes Create account onto
the same navigator Login sits on. "Already have an account? Sign in" pops back. Neither
link is a button — caption type, `inkSubtle` body with the trailing verb in `AppColors.ink`,
each carrying the 48px transparent hit target the design system already applies to
undersized controls.

### Validation — the Q5 rules, extended

Validate **on submit only**, focus the first failing field, clear a field's error when that
field next changes. Exact copy:

| Field | Condition | Error |
|---|---|---|
| Email | empty, contains whitespace, or not `<x>@<y>.<z>` | `Enter a valid email address.` |
| Password | empty | `Enter a password.` |
| Confirm password | empty | `Confirm your password.` |
| Confirm password | non-empty and different from Password | `Passwords do not match.` |

**No length, complexity or strength rule** — for the same reason Q5 gave for Login: auth is
mocked, so any such rule would describe a check the build does not perform. No "email already
registered" copy either; nothing stores emails to check against.

### Behaviour

- Submit with everything valid calls `AuthRepository.createAccount(email, password)` and
  lands on Welcome — the same destination as both Login paths.
- The typed email is what Profile displays afterwards.
- `createAccount` is a third method on the existing `AuthRepository` seam, mirroring
  `signInWithEmail`. It is **not** a new seam and **not** a new repository.
- No "Continue with Google" on this screen. Google is one mock path and it lives on Login.
- No bottom nav.

## Acceptance Criteria (DoD)

- [x] Copy matches character-for-character: `Create account`, `Start exploring the Northern Territory.`, `Email`, `Password`, `Confirm password`, `Create Account`, `Already have an account? Sign in`, `Don't have an account? Sign up`. Asserted with `find.text` on the exact strings.
- [x] Widget test: the Login link pushes Create account, and the Create account link pops back to Login.
- [x] Widget test: submitting a valid email, password and matching confirmation lands on Welcome and leaves that email readable from the session.
- [x] Validation widget test: submitting empty renders all three error strings and focuses Email.
- [x] Validation widget test: matching-but-empty is caught by `Confirm your password.`, and a non-empty mismatch renders `Passwords do not match.` and does not navigate.
- [x] Validation widget test: no error appears while typing or on blur before the first submit, and each field's error clears on that field's next edit without clearing the others'.
- [x] Widget test: Create account renders no bottom nav and no "Continue with Google".
- [x] Repository test: `createAccount` produces a session equivalent to `signInWithEmail` with the same email, and writes no fourth `shared_preferences` key.
- [x] Disposal test: popping Create account leaves no active ticker and disposes all three controllers.
- [x] The backdrop widget is used by both Login and Create account, and `login_screen.dart` no longer declares its own scrim.
- [x] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/auth/` returns nothing.
- [x] No layout exception at 320px width, at 360x640 with a 400px keyboard inset, or at textScaleFactor 1.5.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/features/auth/` exits 0.
