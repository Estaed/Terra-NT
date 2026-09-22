# Task-25 — Real Google Sign-In

> **Execution:** agent `codex`, then a main-loop device tour · effort `high`
> *Why:* The code is one method and one sign-out line, fully specified below. The thing
> that can fail — the Google account sheet, `DEVELOPER_ERROR` from a wrong SHA-1 or a
> missing web client — only fails on a device, so the task is not done at green.

**Lane**
- OWNS: `terra_nt/lib/data/repositories/firebase_auth_repository.dart`, `terra_nt/lib/core/util/auth_failure_mapping.dart` (append the Google rows), `terra_nt/test/core/util/auth_failure_mapping_test.dart`
- MUST NOT TOUCH: everything else — the screens and the notifier already handle `cancelled` and `unknown` (Task-24); `pubspec.yaml`, `android/` (Task-23)
- GATE: `cd terra_nt && flutter analyze && flutter test && flutter build apk --debug` (the device tour below is not gated)
- DEPENDS ON: Task-24

## Objective

"Continue with Google" signs in with a real Google account. Task-24 left
`FirebaseAuthRepository.signInWithGoogle()` throwing `unknown`; this task writes it, and
the Login screen needs no change because the failure copy and the `cancelled` no-op are
already in place.

## The contract — fixed

`google_sign_in` is **7.2.0**; its API is not the 6.x one most examples online show.

```dart
Future<Session> signInWithGoogle() async {
  final google = GoogleSignIn.instance;
  await _ensureGoogleInitialised();          // initialize() once per process
  try {
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException(AuthFailure.unknown);
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final user = (await _auth.signInWithCredential(credential)).user;
    return Session(email: user?.email, onboardingDone: false);
  } on GoogleSignInException catch (e) {
    throw AuthException(failureForGoogleCode(e.code));
  } on FirebaseAuthException catch (e) {
    throw AuthException(failureForCode(e.code));
  }
}
```

- `initialize()` takes **no client ids**: `google_sign_in_android` reads the server client
  id from `google-services.json` (the `client_type: 3` entry Task-23 asserted). Do not
  paste a client id into Dart.
- `failureForGoogleCode(GoogleSignInExceptionCode code)` joins the mapping file, pure:
  `canceled` → `cancelled`; `interrupted`, `providerConfigurationError`,
  `uiUnavailable`, `userMismatch`, `clientConfigurationError`, `unknownError` → `unknown`.
  There is no network code in that enum; a network failure surfaces from Firebase's own
  exception and is already mapped.
- `signOut()` also calls `GoogleSignIn.instance.signOut()` so the next tap shows the
  account chooser instead of silently reusing the last account. Wrap it so a Google
  sign-out failure never blocks the Firebase sign-out.
- `deleteAccount()` is unchanged; a Google-backed user refused with
  `requires-recent-login` gets the Task-24 copy.

## Device tour — the acceptance that has no command

`docs/DEVICE-TOUR.md` applies: this task changes navigation (a system sheet opens over
Login and returns). On the Android emulator with a Google account added, from a clean
install:

1. Tap "Continue with Google", pick the account → Welcome, then Profile shows that email.
2. Sign out, tap again → the account chooser appears (not a silent re-sign-in).
3. Tap, then dismiss the sheet with Back → Login is unchanged, no copy shown, button
   enabled again.
4. Airplane mode, tap → `Google sign-in didn't work. Try again.` or the network copy,
   button enabled again; nothing crashes.
5. Kill and relaunch signed in → lands on the tab shell without a network round trip
   (airplane mode on).

Record the tour under *Result* with the emulator image and what was seen at each step.
Two conditions, never one: no exception in logcat **and** the behaviour above.

## Acceptance Criteria (DoD)

- [ ] `signInWithGoogle()` is implemented as above; `grep -n "initialize(" firebase_auth_repository.dart`
      shows a single call with no `clientId`/`serverClientId` argument.
- [ ] `failureForGoogleCode` exists in `auth_failure_mapping.dart`, imports only
      `package:google_sign_in` for the enum type, and its test covers every enum value.
- [ ] `signOut()` calls `GoogleSignIn.instance.signOut()` and still completes when that
      call throws (guarded).
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes; no test outside the mapping test changed.
- [ ] `cd terra_nt && flutter build apk --debug` succeeds.
- [ ] Device tour steps 1–5 recorded under *Result*, each with the observed outcome.

## Result

_Filled in by `verify-task`; the device tour is written here by the main loop._
