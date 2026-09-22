# Task-27 — Saved routes in Firestore under the account, device copy first

**Status: DONE** — verified 2026-09-23 00:33 (otopilot: worktree gate green, integrated gate green on main, 415 tests; console steps and emulator tour pending)

> **Execution:** agent `codex` · effort `high` (a bee lane; tonight's bees are Claude by operator decision, 2026-09-22)
> *Why:* The sync rule, the document path, the injected functions and the rules file are
> all fixed below; the criterion is `flutter analyze` + tests with injected closures.
> The one thing a bee cannot do — enabling the Firestore API and deploying the rules —
> is an operator step listed under *Main loop*, done before integration.

**Lane**
- OWNS: `terra_nt/lib/data/repositories/preferences_store.dart`, `terra_nt/lib/data/repositories/firestore_saved_routes.dart` (new), `terra_nt/lib/data/repositories/notifiers.dart` (`SavedRoutesNotifier`, `SessionNotifier.deleteAccount`, the `preferencesStoreProvider` body only), `terra_nt/test/data/repositories/`, `firebase.json` (new, repo root), `.firebaserc` (new, repo root), `firestore.rules` (new, repo root)
- MUST NOT TOUCH: `terra_nt/pubspec.yaml`, `terra_nt/pubspec.lock`, `terra_nt/lib/data/models/`, `terra_nt/lib/core/`, `terra_nt/lib/data/repositories/auth_repository.dart` and `firebase_auth_repository.dart` (Task-26 owns their shape; consume only), `terra_nt/lib/features/` and `terra_nt/test/features/` (Task-28, 29, 33 — the delete-account order is asserted on the notifier in `test/data/repositories/`, not in a widget test), `terra_nt/android/` (Task-29, Task-32), `terra_nt/lib/main.dart` (Task-29)
- GATE: `cd terra_nt && flutter analyze && flutter test test/data/`
- DEPENDS ON: Task-26

## Objective

A signed-in user's saved routes follow the account: sign in on a second phone and the
routes are there; delete the account and they are gone everywhere. The device copy
stays the source of truth — every screen reads the local key exactly as today, offline
or not, and nothing at cold start waits on Firestore. `docs/PRD.md` D13 and §4 are the
decision; `CLAUDE.md` → Blueprint records *how* it stays inside the two-seam rule: two
functions injected into `PreferencesStore`, no interface.

## The contracts — fixed, not guidance

### 1. `PreferencesStore` gains two injected functions

```dart
typedef PullRemote = Future<List<SavedRoute>?> Function(String uid);
typedef PushRemote = Future<void> Function(String uid, List<SavedRoute> routes);

PreferencesStore({
  Future<SharedPreferences> Function()? preferences,
  PullRemote? pullRemote,   // null → no remote (tests, signed-out)
  PushRemote? pushRemote,
});

/// Local first. When the local key is ABSENT and [uid] is non-null and a remote
/// list comes back non-null, adopts it: writes it locally and returns it. A
/// present local key — including an explicit empty list — is never overwritten
/// by the remote. A remote failure of any kind returns the local result.
Future<List<SavedRoute>> readSavedRoutes({String? uid});

/// Writes locally, then pushes the same list when [uid] is non-null. A push
/// failure is swallowed: the local write already succeeded and Firestore's
/// offline queue retries on its own.
Future<void> saveSavedRoutes(List<SavedRoute> routes, {String? uid});

/// Pushes an empty list (deletes every remote doc) and THROWS on failure —
/// delete-account must not proceed when the remote copy could not be cleared.
Future<void> clearRemote(String uid);
```

The two key constants and the seed fallback are unchanged. "Absent" means
`preferences.getString(savedRoutesKey) == null`, not "malformed".

### 2. `FirestoreSavedRoutes` — `lib/data/repositories/firestore_saved_routes.dart`

One concrete class wrapping `FirebaseFirestore` (constructor-injected), the only file
outside `main.dart` that imports `cloud_firestore`. It supplies the two functions:

- Collection path `users/{uid}/savedRoutes/{routeId}`; a document is
  `savedRouteToJson(route)` plus `updatedAt: FieldValue.serverTimestamp()` — the
  timestamp is document metadata for the console, never read back into the model.
- `pull(uid)` → `get()` on the collection, ordered by nothing, mapped with
  `savedRouteFromJson` (a doc that fails to parse is skipped). Returns `null` when the
  collection is empty, so a fresh account does not wipe the seed on a fresh device.
- `push(uid, routes)` → one `WriteBatch`: set every route, delete every existing doc
  whose id is not in `routes`. Commit once.

Untested by unit (Blueprint's Stack note); its shape is exercised on the emulator by the
main loop.

### 3. Notifier wiring — `notifiers.dart`

- `preferencesStoreProvider` constructs `PreferencesStore(pullRemote: remote.pull,
  pushRemote: remote.push)` with `FirestoreSavedRoutes(FirebaseFirestore.instance)`.
  Tests already override this provider; they pass closures or nothing.
- `SavedRoutesNotifier` reads `ref.read(sessionNotifierProvider).uid` and passes it as
  `uid:` on every `load`, `upsert`, `delete` and `clearForDeleteAccount` call. `load()`
  is called where it is today; it does not become a network wait — `readSavedRoutes`
  returns the local list first and only *adopts* the remote when there is no local key.
- `SessionNotifier.deleteAccount()` order becomes: `store.clearRemote(uid)` (only when
  `uid` is non-null) → `authRepository.deleteAccount()` → clear session, flag and local
  routes. A throw at step one surfaces as `AuthFailure.network` to Profile (wrap any
  non-`AuthException` in `AuthException(AuthFailure.network)`), and nothing after it runs.
  `docs/PRD.md` §3.9 fixes this order.

### 4. Security rules — `firestore.rules` at the repo root

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/savedRoutes/{routeId} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

`firebase.json`: `{ "firestore": { "rules": "firestore.rules" } }`. `.firebaserc`:
`{ "projects": { "default": "terra-nt-cdu" } }`. No indexes file — no query needs one.

## Execution Guide

(1) `PreferencesStore` with the two functions and the adopt rule, tests with closures
that record calls; (2) `FirestoreSavedRoutes`; (3) the notifier wiring and the
delete-account order with its test; (4) the three root files.

The adopt rule is the whole offline story — write its tests first: absent key + remote
list → adopted and written locally; absent key + remote `null` → seed, nothing written;
present key + remote list → local wins; present empty list + remote list → stays empty;
remote throws → local result, no throw.

## Main loop, before integration (operator steps — not the bee's)

1. Enable the Cloud Firestore API on `terra-nt-cdu` (console link in the CLI error
   from 2026-09-22), then `firebase firestore:databases:create "(default)" --location
   australia-southeast1 --project terra-nt-cdu`.
2. `firebase deploy --only firestore:rules` from the repo root.
3. Emulator tour: sign in, generate, see the doc in the console under the uid; clear
   app data, sign in again, the route is back; delete the account, the collection is
   gone.

## Acceptance Criteria (DoD)

- [x] `repositories_test.dart` covers the five adopt-rule cases in the Execution Guide
      and asserts `saveSavedRoutes` calls `pushRemote` with the same list it wrote
      locally, and does not call it when `uid` is null.
- [x] `clearRemote` propagates the closure's exception; a `SessionNotifier.deleteAccount`
      test with a throwing `pushRemote` leaves the session, the flag and the local
      routes untouched and does not call the seam's `deleteAccount` (recording double).
- [x] A `SessionNotifier.deleteAccount` test with a succeeding remote clears all three
      and calls the seam's `deleteAccount` exactly once, after the remote clear.
- [x] `grep -rln "cloud_firestore" lib` lists only `firestore_saved_routes.dart` and
      `notifiers.dart`.
- [x] `firestore.rules`, `firebase.json` and `.firebaserc` exist at the repo root with the
      contents in contract 4.
- [x] The preferences still hold exactly two keys after every mutation the existing
      test performs.
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
