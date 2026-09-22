# Task-24 — Real email/password accounts behind `AuthRepository`, with failure states

**Status: DONE** — verified 2026-09-22
> **Verified against:** 8280a5f437 terra_nt/lib/core/util/auth_failure_mapping.dart df98d4e8e9 terra_nt/lib/data/models/auth_failure.dart e3b0c44298 terra_nt/lib/data/repositories/.gitkeep 58bb68471a terra_nt/lib/data/repositories/auth_repository.dart 774ed4fb6a terra_nt/lib/data/repositories/firebase_auth_repository.dart ff2b12f42e terra_nt/lib/data/repositories/itinerary_repository.dart 9df7df9199 terra_nt/lib/data/repositories/notifiers.dart be2a0fbddb terra_nt/lib/data/repositories/preferences_store.dart e3b0c44298 terra_nt/lib/features/auth/.gitkeep 8bb5c90510 terra_nt/lib/features/auth/auth_backdrop.dart 0718892cbe terra_nt/lib/features/auth/create_account_screen.dart aba0960c42 terra_nt/lib/features/auth/login_screen.dart 2f1bde66a7 terra_nt/lib/features/auth/welcome_screen.dart 51e699e85c terra_nt/lib/features/profile/profile_screen.dart de429b2ed6 terra_nt/test/app/app_launch_test.dart e3b0c44298 terra_nt/test/core/util/.gitkeep dc68e32c82 terra_nt/test/core/util/auth_failure_mapping_test.dart e12b4ca1bc terra_nt/test/core/util/poi_filter_test.dart 4701feb166 terra_nt/test/core/util/util_test.dart e7b57f7397 terra_nt/test/data/repositories/repositories_test.dart 46c1d899d1 terra_nt/test/features/auth/auth_screen_test.dart 960b13b3f7 terra_nt/test/features/auth/create_account_screen_test.dart 6c98cffe8e terra_nt/test/features/auth/welcome_tile_warmup_test.dart c627bad8a4 terra_nt/test/features/profile/profile_screen_test.dart

> **Execution:** agent `codex` · effort `high`
> *Why:* The seam, the failure enum, the copy and the persistence change are all fixed
> below; the criterion is `flutter analyze` + tests against the in-memory implementation.
> The Firebase wrapper itself is thin and is exercised by Task-25's device tour, not here.

**Lane**
- OWNS: `terra_nt/lib/data/models/auth_failure.dart`, `terra_nt/lib/core/util/auth_failure_mapping.dart`, `terra_nt/lib/data/repositories/` (`auth_repository.dart`, new `firebase_auth_repository.dart`, `notifiers.dart`, `preferences_store.dart`), `terra_nt/lib/features/auth/`, `terra_nt/lib/features/profile/profile_screen.dart`, `terra_nt/test/core/util/`, `terra_nt/test/data/repositories/`, `terra_nt/test/features/auth/`, `terra_nt/test/features/profile/profile_screen_test.dart`, `terra_nt/test/app/app_launch_test.dart`
- MUST NOT TOUCH: `terra_nt/pubspec.yaml`, `terra_nt/android/`, `terra_nt/lib/main.dart`, `terra_nt/lib/firebase_options.dart` (Task-23), `terra_nt/lib/shared/` (Task-02), `terra_nt/lib/core/theme/` (Task-01), `terra_nt/lib/app/` (Task-06 — `app_launch.dart` keeps calling `SessionNotifier.load()`, whose contract does not change)
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: Task-23

## Objective

Replace the phase-1 mock with real accounts. After this task, signing in with a wrong
password fails with copy on screen, creating an account with an email that already exists
fails with copy on screen, the signed-in user survives a cold start because Firebase
persists it, signing out really signs out, and deleting the account really deletes it. The
screens do not change shape: every failure lands in an error slot that already exists.

`docs/PRD.md` D12 is the decision; §2.5 of `docs/PHASE-2-3-FOUNDATION.md` is the list of
states phase 1 faked that this task makes real. Password reset and email verification are
**not** in this task (*Later* in `docs/TASKS_INDEX.md`).

## The contracts — fixed, not guidance

### 1. `AuthFailure` — tier 1, `lib/data/models/auth_failure.dart`

```dart
enum AuthFailure {
  invalidCredential,   // wrong password, no such account, malformed credential
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  network,
  tooManyRequests,
  requiresRecentLogin, // Firebase refuses delete until the user signs in again
  cancelled,           // the user dismissed a provider sheet (Task-25 uses it)
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);
  final AuthFailure failure;
}
```

No `package:flutter`, no `package:firebase_auth` import in this file.

### 2. `failureForCode` — tier 1, `lib/core/util/auth_failure_mapping.dart`

One pure function `AuthFailure failureForCode(String code)` from a Firebase error code
string to the enum. The table is the contract:

| Firebase code | `AuthFailure` |
|---|---|
| `invalid-credential`, `wrong-password`, `user-not-found`, `user-disabled`, `INVALID_LOGIN_CREDENTIALS` | `invalidCredential` |
| `email-already-in-use` | `emailAlreadyInUse` |
| `weak-password` | `weakPassword` |
| `invalid-email` | `invalidEmail` |
| `network-request-failed` | `network` |
| `too-many-requests` | `tooManyRequests` |
| `requires-recent-login` | `requiresRecentLogin` |
| anything else | `unknown` |

Pure Dart, no imports. Firebase's code strings are only ever seen here and in the wrapper.

### 3. `AuthRepository` — the seam grows two members

```dart
abstract interface class AuthRepository {
  /// The signed-in email Firebase persisted on this device, or null. Never
  /// touches the network; must answer offline at cold start.
  Future<String?> currentEmail();
  Future<Session> signInWithEmail(String email, String password);
  Future<Session> signInWithGoogle();
  Future<Session> createAccount(String email, String password);
  Future<void> signOut();
  /// Deletes the signed-in account. Throws AuthException(requiresRecentLogin)
  /// when the provider refuses; the caller decides what to show.
  Future<void> deleteAccount();
}
```

Every method may throw `AuthException`; nothing else escapes the seam. The `Session` the
sign-in methods return carries `onboardingDone: false` — the notifier owns that flag, as
today.

### 4. `InMemoryAuthRepository` stays and becomes scriptable

It is the implementation every test uses. Add one field:

```dart
/// When set, the next call that can fail throws it once and clears it.
AuthFailure? nextFailure;
```

`currentEmail()` returns the email of the last successful sign-in, or null after sign-out
or delete. `deleteAccount()` throws `nextFailure` if set, otherwise clears the session.

### 5. `FirebaseAuthRepository` — `lib/data/repositories/firebase_auth_repository.dart`

Wraps `FirebaseAuth.instance` (injected through the constructor so it is at least
constructible in tests; it is not unit-tested — Blueprint's Stack note, 2026-09-22).

- `currentEmail()` → `_auth.currentUser?.email`. No await on the network.
- `signInWithEmail` → `signInWithEmailAndPassword`; `createAccount` →
  `createUserWithEmailAndPassword`; `signOut` → `signOut()`; `deleteAccount` →
  `currentUser!.delete()`.
- Every `FirebaseAuthException` becomes `throw AuthException(failureForCode(e.code))`.
  Nothing else is caught.
- `signInWithGoogle()` throws `AuthException(AuthFailure.unknown)` in this task; Task-25
  writes it. The Login button stays visible and reports that failure through the copy
  below, so the app is never in a state where the button does nothing.

`authRepositoryProvider` in `notifiers.dart` returns `FirebaseAuthRepository(FirebaseAuth.instance)`.
Tests override the provider with the in-memory implementation exactly as they do today.

### 6. Persistence — `terra_nt.session` is deleted

`PreferencesStore` loses `sessionKey`, `readSession` and `saveSession` and gains
`Future<bool> readOnboardingDone()` and `Future<void> saveOnboardingDone(bool)`.
`SessionNotifier.load()` becomes:

```dart
state = Session(
  email: await _authRepository.currentEmail(),
  onboardingDone: await _store.readOnboardingDone(),
);
```

The sign-in, create-account, sign-out and delete paths stop writing the email anywhere;
only `setOnboardingDone` and `deleteAccount` (which resets the flag to false) write the
flag. Blueprint's key table now says exactly two keys; the "no fourth key" test becomes a
"no third key" test and the existing session round-trip test is replaced by an
onboarding-flag round-trip. `app_launch_test.dart` seeds the in-memory repository instead
of a `terra_nt.session` string.

`SessionNotifier.deleteAccount()` calls `_authRepository.deleteAccount()` **first**; only
when it returns does the notifier clear the session, reset the onboarding flag and clear
the saved routes. A refused delete changes nothing.

### 7. Copy — binding from this task, sentence case, character for character

The design has no failure states (`docs/PRD.md` Q5, foundation §2.5); this table is the
spec, in the same way Task-21's copy was. Failures render in `AppTextInput.errorText`, the
slot Task-09 built, in the same style as the client-side validation copy already there.
**Form-level failures render in the error slot of the last field on that form** — the
password field on Login, the confirm-password field on Create account — because that is
the field the eye is on when the button is pressed, and it adds no widget.

| Failure | Login | Create account |
|---|---|---|
| `invalidCredential` | password: `Email or password is incorrect.` | — |
| `emailAlreadyInUse` | — | email: `An account already exists for this email.` |
| `weakPassword` | — | password: `Use at least 6 characters.` |
| `invalidEmail` | email: `Enter a valid email address.` | email: `Enter a valid email address.` |
| `network` | last field: `No connection. Check your signal and try again.` | same |
| `tooManyRequests` | last field: `Too many attempts. Try again later.` | same |
| `cancelled` | nothing shown, form untouched | — |
| `unknown` | last field: `Something went wrong. Try again.` | same |

Google failures on Login (`signInWithGoogle` throwing `unknown` until Task-25, and
whatever Task-25 maps later) show `Google sign-in didn't work. Try again.` in the
password slot; `cancelled` shows nothing.

**Profile, delete account.** The inline confirmation (`_DeleteAccountConfirmation`) gains
an optional error line under its body text, `AppType.caption` in `AppColors.tagRed` like
the input error, and stays open when delete is refused:

| Failure | Copy |
|---|---|
| `requiresRecentLogin` | `Sign in again, then delete your account.` |
| `network` | `No connection. Check your signal and try again.` |
| anything else | `Something went wrong. Try again.` |

Carry it as `String? deleteAccountError` on `ProfileState`; `cancelDeleteAccount` and
`showDeleteAccountConfirmation` clear it.

**While a call is in flight the submitting button is disabled** (`onPressed: null`,
`AppButton` already renders that) and re-enabled when the call returns, success or
failure. No spinner — none is designed.

### 8. Existing client-side validation stays first

The empty-field and email-shape checks Login and Create account already run happen
before any repository call, unchanged. The repository is called only when they pass.

## Execution Guide

Order that keeps the suite green between steps: (1) `auth_failure.dart` and the mapping
with its test; (2) the seam and the in-memory implementation with `nextFailure`; (3)
`PreferencesStore` and `SessionNotifier`, fixing `repositories_test.dart` and
`app_launch_test.dart`; (4) the two auth screens; (5) Profile; (6) the Firebase wrapper
and the provider swap last, so every earlier step is testable without it.

The Firebase wrapper's imports are the only place `package:firebase_auth` appears outside
`main.dart`'s `firebase_core`. `notifiers.dart` imports it only to construct the default.

## Acceptance Criteria (DoD)

- [x] `lib/data/models/auth_failure.dart` and `lib/core/util/auth_failure_mapping.dart`
      import nothing from `package:flutter` or `package:firebase_auth`
      (`grep -L` on both files).
- [x] `test/core/util/auth_failure_mapping_test.dart` covers every row of the code table,
      including the fallback to `unknown`.
- [x] `AuthRepository` declares exactly the six members in contract 3; `InMemoryAuthRepository`
      implements them and honours `nextFailure` once.
- [x] `PreferencesStore` declares exactly two key constants, `savedRoutesKey` and
      `onboardingDoneKey`; `grep -rn "terra_nt.session" lib test` returns nothing.
- [x] `repositories_test.dart`: the onboarding flag round-trips; after sign-in, sign-out,
      reorder, skip, edit mode, sheet height and the offline toggle, the preferences
      contain no key other than the two.
- [x] Notifier tests (`ProviderContainer`, in-memory repository): sign-in with
      `nextFailure = invalidCredential` leaves the state signed out and rethrows;
      `deleteAccount` with `nextFailure = requiresRecentLogin` leaves the session, the
      onboarding flag and the saved routes untouched; a successful delete clears all three.
- [x] Widget tests: Login shows `Email or password is incorrect.` under the password field
      on `invalidCredential`, and `No connection. Check your signal and try again.` on
      `network`; Create account shows `An account already exists for this email.` under
      the email field on `emailAlreadyInUse` and `Use at least 6 characters.` under the
      password field on `weakPassword`; the submit button is disabled while the call is
      pending and enabled after it fails.
- [x] Widget test: Profile's delete confirmation stays open and shows
      `Sign in again, then delete your account.` on `requiresRecentLogin`, and closes with
      the session cleared on success.
- [x] `app_launch_test.dart`: a cold start with the in-memory repository holding an email
      and the flag `true` lands on the tab shell; with no email and the flag `false` it
      lands on onboarding — same outcomes as today, seeded through the seam.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
- [x] `CLAUDE.md` → Blueprint key table already says two keys from this task; nothing in
      it needs editing.

## Result

Verified 2026-09-22 from the main loop. A Claude bee (opus) wrote the code in a worktree
from `509d6c6`; the commit was cherry-picked as `be20aa0`, then integrated:

- The bee wrapped `SessionNotifier.load()` in a `try`/`on Exception` so `boot_test.dart`
  (which pumps the app with no overrides) would survive `FirebaseAuth.instance` throwing
  `[core/no-app]` under test. Reverted: swallowing every exception at cold start hides a
  misconfigured production build as "nobody is signed in". The test now overrides the
  seam with `InMemoryAuthRepository` like every other test; removing that override makes
  it fail, so the guard is real.
- Mutation check: a wrong row in `failureForCode` and a changed word in the Login copy each
  turned the suite red. Replacing the seam's `deleteAccount()` with `signOut()` did **not**
  — the in-memory double could not tell them apart — so
  `delete account deletes on the seam, log out only signs out` was added with a recording
  double; it goes red on that mutation.
- Three pre-existing mojibake literals in `repositories_test.dart` (`Â·` for `·`, in `meta`
  strings no assertion reads) were corrected in the same commit; not a Task-24 defect.

Gate: `flutter analyze` clean; `flutter test` 360 passed. Trajectory: iter 0 green →
mutation gap found → iter 1 green with the new test. `ProfileState` also carries
`deleteAccountPending` (Profile's Delete button disables in flight), and copy-table cells
marked "—" fall back to `Something went wrong. Try again.` — both the bee's simplest
reading, accepted.
