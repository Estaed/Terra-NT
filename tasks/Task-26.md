# Task-26 — Saved routes carry their stops; the auth seam grows for wave 2 and phase 3

> **Execution:** agent `claude` bee · effort `high`
> *Why:* Every signature is fixed below and the criterion is `flutter analyze` + tests
> against the in-memory seam. Nothing here is judged by eye. It runs alone as wave 1
> because five sibling tasks depend on the signatures it writes.

**Lane**
- OWNS: `terra_nt/lib/data/models/saved_route.dart`, `terra_nt/lib/data/models/session.dart`, `terra_nt/lib/core/util/stop_json.dart` (new), `terra_nt/lib/data/seed/seed_data.dart` (the `seedSavedRoutes` constant only), `terra_nt/lib/data/repositories/` (`auth_repository.dart`, `firebase_auth_repository.dart`, `itinerary_repository.dart`, `notifiers.dart`, `preferences_store.dart`), `terra_nt/lib/features/loading/loading_screen.dart`, `terra_nt/lib/features/saved/saved_routes_screen.dart`, `terra_nt/test/core/util/stop_json_test.dart` (new), `terra_nt/test/data/`, `terra_nt/test/features/loading/`, `terra_nt/test/features/saved/`, `terra_nt/test/app/`, `terra_nt/test/integration/`
- MUST NOT TOUCH: `terra_nt/pubspec.yaml` and `terra_nt/pubspec.lock` (resolved 2026-09-22, do not run `pub add`), `terra_nt/lib/features/auth/` (Task-28), `terra_nt/lib/features/profile/` (Task-28, Task-29), `terra_nt/lib/features/onboarding/` (Task-30), `terra_nt/lib/data/models/onboarding_answers.dart` (Task-30), `terra_nt/lib/shared/`, `terra_nt/lib/core/theme/`, `terra_nt/android/`, `terra_nt/lib/main.dart` (Task-29)
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: Task-25

## Objective

Two things phase 1 could fake stop being fakeable. First, a saved route was a title and
a label because every itinerary was seeded and `itineraryForSavedRoute(id)` could look
the stops up; a generated route (phase 3) and a synced one (Task-27) have nowhere else
to live, so `SavedRoute` gains `stops` and the seam's lookup method goes. Second, the
auth seam gains the five members wave 2 and phase 3 need — `currentUid`, `idToken`,
`sendPasswordReset`, `sendEmailVerification`, `isEmailVerified` — so Task-27, 28 and 32
can run in parallel without touching the same files.

Also fixed here because the same file is open: Loading fetches the itinerary from the
seam and never hands it to `ItineraryNotifier`, so Result renders the notifier's seed
default. Invisible in phase 1 (they are the same route); the first real response would
have exposed it (`docs/PRD.md` §3.4).

`docs/PRD.md` D13 and §4 are the decision; `CLAUDE.md` → Blueprint → key table says the
persisted shape.

## The contracts — fixed, not guidance

### 1. `SavedRoute` gains `stops`

```dart
class SavedRoute {
  final String id;
  final String title;
  final String meta;
  final String dateLabel;
  final List<Stop> stops;
  const SavedRoute({required this.id, required this.title, required this.meta,
      required this.dateLabel, required this.stops});
}
```

`seedSavedRoutes` becomes `full-nt` → `seedStops`, `red-centre` → `redCentreStops`
(both already exist in `seed_data.dart`). Titles and labels unchanged.

### 2. `stop_json.dart` — tier 1, `lib/core/util/stop_json.dart`

```dart
Map<String, Object?> stopToJson(Stop stop);
Stop stopFromJson(Map<String, Object?> json);   // throws FormatException on a bad shape
Map<String, Object?> savedRouteToJson(SavedRoute route);
SavedRoute savedRouteFromJson(Map<String, Object?> json);  // throws FormatException
```

Keys are the field names exactly: `name, subtitle, lat, lng, hours, fee, duration,
driveNext, aiNote, tags, detailedPlan, photoUrl`, with `detailedPlan` a list of
`{time, activity}`. `fee`, `driveNext`, `photoUrl` serialise as JSON `null` when null.
`stopFromJson` throws `FormatException` when `name`, `lat` or `lng` is missing or of the
wrong type; every other missing field takes the same fallback `docs/PHASE-3-CONTRACT.md`
§3.3 names (`subtitle` `""`, `duration` `"1 day"`, `hours` `"Hours not listed"`,
`aiNote` `""`, `tags` `[]`, `detailedPlan` `[]`, nullable fields `null`). Task-31 builds
its parser on this function; the fallbacks live here once. No `package:flutter` import.

### 3. `PreferencesStore` stores stops

`saveSavedRoutes` writes `savedRouteToJson`; `readSavedRoutes` reads
`savedRouteFromJson` and keeps the existing rule: a missing key or a `FormatException`
falls back to the seed, an explicitly persisted empty list stays empty. An old entry
without `stops` therefore falls back to the seed — there are no users, this is fine, and
the Blueprint key table says so.

### 4. The generation seam loses a member

```dart
abstract interface class ItineraryRepository {
  Future<Itinerary> itineraryFor(OnboardingAnswers answers);
}
```

`itineraryForSavedRoute` is deleted from the interface and from
`SeedItineraryRepository`. `ItineraryNotifier.loadForSavedRoute(String)` becomes
`void openSavedRoute(SavedRoute route)` and sets
`ItineraryState.forItinerary(Itinerary(title: route.title, stops: route.stops))`.
`saved_routes_screen.dart` calls it with the tapped route. Declared dead means deleted:
`_redCentreTitle` goes with it.

### 5. `AuthRepository` gains five members

```dart
abstract interface class AuthRepository {
  Future<String?> currentEmail();
  /// Firebase's stable user id, or null when signed out. Offline-safe.
  Future<String?> currentUid();
  /// A fresh ID token for the planning endpoint, or null when signed out.
  /// May touch the network to refresh; throws AuthException(network) if it cannot.
  Future<String?> idToken();
  Future<Session> signInWithEmail(String email, String password);
  Future<Session> signInWithGoogle();
  Future<Session> createAccount(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
  /// Sends the reset mail. Resolves normally when no account exists for the
  /// email — the screen must not learn which emails are registered.
  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();
  /// Cached flag; best-effort reload behind it, never throws for a network miss.
  Future<bool> isEmailVerified();
}
```

`Session` gains `final String? uid;` (nullable, default null, `copyWith` if one exists).
`SessionNotifier.load()` fills it from `currentUid()`; the sign-in paths keep whatever
the seam returns.

`InMemoryAuthRepository`: `currentUid()` returns `'uid-<email>'` for the signed-in email;
`idToken()` returns `'test-token'` when signed in, else null; `sendPasswordReset`
records the email in a public `lastResetEmail` field and honours `nextFailure`;
`sendEmailVerification` increments a public `verificationEmailsSent` counter and honours
`nextFailure`; `isEmailVerified` returns a public `emailVerified` field (default
`false`).

`FirebaseAuthRepository`: `currentUid` → `currentUser?.uid`; `idToken` →
`currentUser?.getIdToken()`; `sendPasswordReset` → `sendPasswordResetEmail`, mapping
`user-not-found` to a normal return and everything else through `failureForCode`;
`sendEmailVerification` → `currentUser!.sendEmailVerification()`;
`isEmailVerified` → `try { await currentUser?.reload(); } catch (_) {}` then
`currentUser?.emailVerified ?? false`. `createAccount` calls `sendEmailVerification()`
inside a `try`/`catch` that ignores the failure (`docs/PRD.md` §3.10). `failureForCode`
is unchanged.

### 6. Loading hands the itinerary to the notifier

In `_complete`, immediately after `itineraryFor` returns and before the onboarding flag
is set: `ref.read(itineraryNotifierProvider.notifier).setItinerary(itinerary)`. The
upserted `SavedRoute` carries `stops: itinerary.stops`.

## Execution Guide

Order that keeps the suite green between steps: (1) `stop_json.dart` with its test;
(2) `SavedRoute` + seed + store, fixing `repositories_test.dart` and the seed test;
(3) the seam and notifier change, fixing `saved_routes_screen.dart` and its test;
(4) the auth seam growth, in-memory first, then the Firebase wrapper; (5) Loading.

Existing tests that construct `SavedRoute` need `stops:` — pass `const []` where the
stops are irrelevant and the seed lists where the test opens the route. Grep for
`itineraryForSavedRoute` and `loadForSavedRoute` afterwards; both must return nothing.

## Acceptance Criteria (DoD)

- [ ] `lib/core/util/stop_json.dart` imports no `package:flutter`; `stop_json_test.dart`
      round-trips every seeded stop (`stopFromJson(stopToJson(s))` equals `s` field by
      field), asserts the three fallbacks for missing `subtitle`/`hours`/`duration`, and
      asserts `FormatException` for a missing `name`, a string `lat`, and a non-list
      `detailedPlan`.
- [ ] `seedSavedRoutes[0].stops` is `seedStops` and `[1].stops` is `redCentreStops`
      (asserted in `models_seed_test.dart`).
- [ ] `repositories_test.dart`: a saved list with stops round-trips through
      `PreferencesStore`; an entry without `stops` falls back to the seed; an explicitly
      empty list stays empty; the preferences still hold exactly two keys after every
      mutation the existing test performs.
- [ ] `grep -rn "itineraryForSavedRoute\|loadForSavedRoute" lib test` returns nothing;
      `saved_routes_screen_test.dart` opens `red-centre` and the itinerary state holds
      four stops titled `7 Days in the Red Centre`.
- [ ] `AuthRepository` declares exactly the eleven members in contract 5; the in-memory
      implementation's `currentUid`, `idToken`, `sendPasswordReset` (with `nextFailure`),
      `sendEmailVerification` and `isEmailVerified` are each covered by a test in
      `repositories_test.dart`.
- [ ] `Session` carries `uid`; `SessionNotifier.load()` sets it from the seam (test with
      the in-memory repository signed in).
- [ ] `loading_screen_test.dart`: after completion the itinerary notifier's state holds
      the itinerary the (fake) repository returned — use a repository returning a
      two-stop itinerary with a distinct title and assert the title — and the upserted
      `generated-trip` carries those two stops.
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
