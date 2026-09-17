# Task-05 — Repositories, persistence, and the two seams

Status: DONE

> **Execution:** agent `codex` · effort `high`
> *Why:* Repositories, notifiers and persistence are specified down to the signatures, and Blueprint fixes the two seams.

**Lane**
- OWNS: `terra_nt/lib/data/repositories/`, `terra_nt/test/data/repositories/`
- MUST NOT TOUCH: `terra_nt/lib/data/models/`, `terra_nt/lib/data/seed/` (Task-03), `terra_nt/lib/core/util/` (Task-04), `terra_nt/lib/features/` (Task-06), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/data/`
- DEPENDS ON: Task-03, Task-04

## Objective

Build the state layer: Riverpod notifiers that own all mutable state, local persistence for
what survives a restart, and **the only two abstraction seams the project is allowed**.

Blueprint is explicit: `ItineraryRepository` and `AuthRepository` are interfaces because
phases 3 and 2 replace them (`docs/PRD.md` §5.1). **Nothing else in this task gets an
interface.** One implementation means one concrete class.

## Execution Guide

**Files:** `terra_nt/lib/data/repositories/`.

### Seam 1 — `ItineraryRepository`

```
abstract interface class ItineraryRepository {
  Future<Itinerary> itineraryFor(OnboardingAnswers answers);
  Future<Itinerary> itineraryForSavedRoute(String routeId);
}
```

Phase-1 implementation returns the seeded `Itinerary` regardless of `answers`, and
dispatches on route id for `red-centre` (Task-03's `redCentreStops`, D8). **Screens must
never import `data/seed/`** — that is the whole point of the seam.

**It returns `Itinerary`, not `List<Stop>`, deliberately.** Title and stop count both vary
once real generation lands; if the title lived in the Result widget, phase 3 would have to
edit a screen, which `docs/PRD.md` §5 forbids. Nothing else about the seam is widened —
this is a return type, not a third abstraction.

### Seam 2 — `AuthRepository`

```
abstract interface class AuthRepository {
  Future<Session> signInWithEmail(String email, String password);
  Future<Session> signInWithGoogle();
  Future<void> signOut();
}
```

Phase-1 implementation is in-memory. **`signInWithGoogle` is a mock** that returns the same
result as the email path (D5, revised) — it performs no OAuth and adds no package. Phase 2
swaps this class for a Firebase one; no screen changes.

### Persistence — `PreferencesStore`

A thin concrete wrapper over `shared_preferences`. Persists exactly three things
(`docs/PRD.md` §4): saved routes, the session, and the onboarding-done flag. Everything
else is session-only and must **not** be written — specifically not itinerary order,
skipped stops, edit mode, sheet height, POI selection, or the Offline Maps toggle.

Serialize saved routes as JSON. Reading absent or corrupt data returns the seed for saved
routes and a signed-out session — never throws.

### Notifiers

| Notifier | Owns |
|---|---|
| `SessionNotifier` | email, `onboardingDone`; persists on change |
| `SavedRoutesNotifier` | the list; `upsert`/`delete`; persists on change |
| `OnboardingNotifier` | `OnboardingAnswers` + current step; session-only |
| `ItineraryNotifier` | current stops, `order`, `skipped` set, `editMode`; session-only |
| `ExploreNotifier` | `selectedPoiId`, search query; session-only |
| `ProfileNotifier` | `offlineMaps`, delete-account step; session-only |

Notifiers call Task-04's pure functions — they must not reimplement that logic.

**Two state transitions carry recorded deviations. Implement them as specified, not as the
prototype has them:**

- **Delete account (V6):** clears email, password, the onboarding flag, **and saved routes
  to an empty list**. The prototype sets saved routes to null, which falls back to the seed
  and resurrects the demo routes.
- **Log out:** clears email and password **only**. Saved routes and the onboarding flag
  survive. These two must not share a code path.

## Acceptance Criteria (DoD)

- [x] Exactly two `abstract interface class` declarations exist in `lib/`: `grep -rn "abstract interface class" lib/ | wc -l` returns 2.
- [x] `grep -rn "data/seed" lib/features/` returns nothing (screens never touch seed data).
- [x] `grep -rn "firebase\|google_sign_in" lib/` returns nothing.
- [x] `PreferencesStore` writes exactly three keys; a test asserts that after mutating itinerary order, skipped stops, edit mode, sheet height and the offline toggle, **no new key appears** in the fake preferences.
- [x] Round-trip test: saved routes written then read back are equal, using `SharedPreferences.setMockInitialValues`.
- [x] Corrupt-data test: a malformed stored JSON string yields the seeded routes and does not throw.
- [x] `SavedRoutesNotifier.upsert` delegates to Task-04's `upsert` — a new id lands at index 0, an existing id is replaced in place.
- [x] Delete-account test (V6): after confirming, saved routes are **empty**, and a subsequent fresh read still returns empty rather than the two seeded entries.
- [x] Log-out test: after logging out, email is cleared but saved routes and `onboardingDone` are unchanged.
- [x] `signInWithGoogle` returns a session equivalent to the email path and makes no network call.
- [x] Every notifier test runs on a bare `ProviderContainer` with no widget pumped.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/data/` exits 0.
