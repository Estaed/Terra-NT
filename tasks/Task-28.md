# Task-28 — Password reset on Login; email verification on Account

> **Execution:** agent `codex` · effort `high` (a bee lane; tonight's bees are Claude by operator decision, 2026-09-22)
> *Why:* Copy, placement and seam calls are fixed below and the criterion is widget
> tests against the in-memory seam. No new visual language: both additions reuse the
> `_AuthLink`, caption and text-button patterns already on those screens.

**Lane**
- OWNS: `terra_nt/lib/features/auth/login_screen.dart`, `terra_nt/lib/features/profile/account/`, `terra_nt/test/features/auth/auth_screen_test.dart`, `terra_nt/test/features/profile/account/`
- MUST NOT TOUCH: `terra_nt/lib/data/` (Task-26 shapes, Task-27 store), `terra_nt/lib/features/auth/create_account_screen.dart` (the verification mail is sent by the seam's `createAccount`, Task-26), `terra_nt/lib/features/profile/profile_screen.dart` (Task-29), `terra_nt/lib/shared/`, `terra_nt/lib/core/theme/`, `terra_nt/pubspec.yaml`
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/auth/ test/features/profile/account/`
- DEPENDS ON: Task-26

## Objective

Two states phase 1 faked become real and reachable (`docs/PRD.md` D13, §3.1, §3.10). A
user who forgot their password can ask for a reset from Login without the screen
revealing which emails exist. A user can see whether their email is verified on Account
and resend the mail. Nothing gates on verification: an unverified account plans and
saves like any other — the app's premise is no signal.

## The contracts — fixed, not guidance

### 1. Login — "Forgot your password? Reset it"

- A second `_AuthLink` directly under the sign-up link, same gap
  (`AppMetrics.loginFormGap` is between the button and the first link; the two links
  are separated by the smallest existing vertical metric on that screen — reuse, do not
  add). `key: ValueKey('login-forgot-password')`, leading `"Forgot your password? "`,
  trailing `"Reset it"`.
- Tap with the email field empty or failing the existing shape check: set the email
  error slot to `Enter your email to reset your password.` (submitted-style, so it
  shows immediately) and send nothing.
- Otherwise call `ref.read(authRepositoryProvider).sendPasswordReset(email)`. While in
  flight the link is disabled (`onTap: null`). On return the link is **replaced** by
  one caption line, `AppType.caption` in `AppColors.inkSubtle`, centred, `key:
  ValueKey('login-reset-sent')`, text `Check your email for a reset link.` — the same
  line for every normal return; the seam already maps "no such account" to a normal
  return (Task-26).
- `AuthException(network)` → password slot shows `No connection. Check your signal and
  try again.`; any other failure → `Something went wrong. Try again.`; the link stays.

### 2. Account — "Email verification" row

- A fourth read-only row after the email row, in the row pattern the screen already
  uses: label `Email verification`, value `Verified` or `Not verified`.
- The value comes from `isEmailVerified()` read once when the screen builds (a
  `FutureBuilder` or an `initState` read into local state — local UI state, not a
  notifier; nothing else observes it). Until it resolves the value line is empty, no
  spinner.
- When not verified, a text button under the value in the existing text-button style,
  `key: ValueKey('account-resend-verification')`, label `Resend email`. Tap →
  `sendEmailVerification()`; disabled in flight; on success the button is replaced by
  the caption `Verification email sent.`; on `network` the caption shows Task-24's
  network copy, on anything else the unknown copy, and the button stays.

### 3. Copy is character for character, sentence case

Every string above is binding (`docs/PRD.md` §3.1, §3.10).

## Execution Guide

Login first: the widget test seeds `InMemoryAuthRepository`, taps the link with an
empty email and asserts the email error; enters a valid email, taps, asserts
`lastResetEmail` and the caption; sets `nextFailure = network`, taps, asserts the
password-slot copy. Then Account with `emailVerified` false → row, button, tap →
`verificationEmailsSent == 1` and the caption; `emailVerified` true → no button.

## Acceptance Criteria (DoD)

- [ ] `auth_screen_test.dart`: the three Login cases above pass, and the sign-in button
      behaviour of the existing tests is unchanged.
- [ ] `account_screen_test.dart` (existing folder): `Not verified` + `Resend email` →
      caption after tap; `Verified` → no button; `nextFailure = network` → network copy
      and the button remains.
- [ ] No new colour, metric, radius or duration constant is added to `core/theme/`
      (`git diff --stat` shows no file under `lib/core/theme/`).
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
