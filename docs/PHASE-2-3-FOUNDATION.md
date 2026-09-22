# Phase 2 & 3 foundation — working draft

Written 2026-09-10 by hand, from `docs/PRD.md` §5.1, §5.3 and §9 *Deferred* (P1–P8), and
from the phase-1 code as it stands after Task-21.

**This file is not binding and amends nothing.** `CLAUDE.md` → Blueprint is still the only
binding architecture, and it is amended by `create-architecture`, never by hand. This is
the input that skill will read: it collects what phases 2 and 3 need, states what we will
and will not build, and turns the P-list into decisions with proposed answers. Every
proposal here is a candidate the product owner still has to take.

---

## 1. The scope boundary — what we build, and what we do not

The product owner fixed this on 2026-09-10, and it is the most important line in the file
because it decides how much of phase 3 is our work at all.

**We do not build the intelligence.** No fine-tuning. No corpus collection. No embedding
pipeline, no vector store, no retrieval tuning, no model hosting. The NT-tourism knowledge
comes from **RAG over collected data**, and that whole side — data, index, model, the
serving of it — is somebody else's deliverable, or a later one.

**We build the two ends of the wire, and nothing between them:**

1. **Outbound** — the fifteen onboarding answers leave the app as one structured request.
2. **Inbound** — a structured itinerary comes back and becomes an `Itinerary` on screen.

Everything in §3 below is one of those two ends, plus the failure states a network round
trip forces into a UI that currently has none. If a paragraph is about how the model
decides anything, it does not belong in this file.

This resolves **P2** only in the narrow sense that matters to the app: RAG, not fine-tune.
The app cannot tell the difference — it sends answers and receives an itinerary — which is
exactly why the choice can sit outside our boundary.

---

## 2. Phase 2 — Firebase

### 2.1 What actually changes

Almost nothing on screen. The seam already exists.

| Today | Phase 2 |
|---|---|
| `MockAuthRepository` — any valid pair signs in | `FirebaseAuthRepository` — real credentials, real Google Sign-In |
| `createAccount` sets the session to the typed email (Task-21) | Real account creation, with the failures a real one has |
| Session in `terra_nt.session` | Firebase's own session; our key holds at most the onboarding flag |
| Saved routes in `terra_nt.saved_routes` | Firestore, with the device copy as the offline cache |

`AuthRepository` is the seam **P1** was reserved for, so no screen changes and no third
seam is created for auth. Saved routes are the problem — see §2.3.

### 2.2 Packages this adds

Proposed, not resolved — versions get pinned from `pubspec.lock` when the change lands,
per Blueprint's rule that the stack table is read from the lock file, never invented.

| Package | Why |
|---|---|
| `firebase_core` | Required by every other Firebase package |
| `firebase_auth` | Email/password and the Google credential |
| `google_sign_in` | The real button behind "Continue with Google" |
| `cloud_firestore` | Saved routes off the device, with built-in offline persistence |

`firebase_crashlytics` is a candidate once `firebase_core` is in (§4).

**Cost of entry to be honest about:** Firebase pulls a large native dependency tree, needs
`google-services.json` per platform, raises the minimum Android SDK, and slows every clean
build. That is the real price of P1, and it is worth naming before the decision, not after.

### 2.3 Saved routes are where "no third seam" gets tested

Blueprint permits exactly two seams and forbids a third. Moving saved routes to Firestore
needs *something* to swap, and `PreferencesStore` is a concrete class the notifiers call
directly. Three ways out, and this is a decision to raise, not to settle here:

1. **Firestore inside the existing store.** `PreferencesStore` keeps its name and its API,
   and gains a remote backing with the local keys as the cache. No new seam, no new
   interface; the offline story lands in one place. Ugly name for what it then does.
2. **Rename it to a repository and give it two implementations.** Honest, and it is a third
   seam. Needs Blueprint amended on purpose.
3. **Firestore's own offline persistence is the cache**, and `terra_nt.saved_routes`
   disappears entirely. Fewest moving parts, but it hands the app's offline premise to a
   library's cache eviction policy, on a device that may be offline for days.

**Recommendation: (1).** It keeps the seam count at two, which Blueprint actually cares about,
and it keeps the offline behaviour ours.

### 2.4 Offline is a product constraint, not a Firebase setting

The app's premise is areas with no phone signal. Nothing added in phase 2 may make a signed
-in user's saved routes unreadable offline, and no screen may block on a network call at
cold start. Whatever §2.3 becomes, the local copy is the source of truth for rendering and
the remote is a synchroniser.

### 2.5 What phase 2 owes that phase 1 faked

Each of these is a real state the current build has no design for. They are the reason
phase 2 is not just a package swap.

- **Wrong password / no such account.** Q5 recorded that phase 1 deliberately has no
  credential-failure copy because there is no credential check. Phase 2 creates one.
- **Email already in use**, on the Task-21 create-account screen.
- **Password rules.** Task-21 omits a length rule on purpose; Firebase enforces one, and
  its message needs our copy.
- **Password reset**, and possibly email verification. Neither screen exists.
- **Delete account for real.** Firebase requires recent re-authentication to delete a user,
  so the inline confirm in Profile (deviation V6) is not enough on its own.
- **Network failure on any of the above.** No design file has one.
- **Firestore security rules**, so one account cannot read another's routes.

---

## 3. Phase 3 — the AI integration surface

Only the two ends of the wire, per §1.

### 3.1 Shape

```
OnboardingAnswers  →  PlanRequest (JSON)  →  our server  →  [RAG + model, not ours]
                                                   ↓
                                          geocoding + photos (server side)
                                                   ↓
Itinerary  ←  validation + mapping  ←  PlanResponse (JSON)
```

**The app never talks to a model and never holds a model key.** §5.3 already fixes this: a
key inside an APK is a public key. The app talks to one endpoint of ours.

### 3.2 Outbound — the request

- One JSON object built from `OnboardingAnswers` in tier 1, pure Dart, unit-testable
  without a widget. This is the natural home: it is a pure transform, and Blueprint puts pure
  transforms in `core/util/`.
- **Stable machine keys, not display copy.** The answers are currently held as the strings
  the UI shows. Serialising those ships English UI copy into the model's context and breaks
  the moment a label is reworded. Every answer needs an identifier that does not change
  when its label does. **This is a phase-1 data-model gap worth fixing early**, because it
  touches `OnboardingAnswers` and its seed, both of which are already tested.
- **`schemaVersion` on the request**, so the server can reject a build it cannot serve
  rather than guessing.
- **The prompt template is not in the app** (P4). We send answers; the server fills the
  template. A prompt shipped in the client is a prompt any user can read, edit and replay.

### 3.3 The endpoint contract

Proposed, to be confirmed with whoever builds the server (P3):

| | |
|---|---|
| Method | `POST /v1/itinerary` |
| Auth | Firebase ID token in `Authorization` — this is why phase 2 comes first |
| Body | `PlanRequest` (§3.2) |
| Success | `200` with `PlanResponse` (§3.4) |
| Client timeout | One value, generous; generation is slow. A cancel path is required |
| Failure | `4xx` the app shows as "we cannot plan this", `5xx`/timeout as "try again" |
| Rate limit | `429` with a retry hint; the server, not the app, protects the model budget |

An idempotency key on the request lets a retry after a timeout return the same itinerary
instead of paying for a second generation. Cheap to add at design time, awkward later.

### 3.4 Inbound — the response, and the rule that keeps the map correct

**The model returns names, never coordinates.** §5.3 is explicit and it is the single most
likely way a phase-3 map goes visibly wrong: an LLM asked for lat/lng returns confident,
wrong numbers and the pins land in the ocean. Geocoding runs on the server, where the Maps
key already lives and where results can be cached across users.

The response maps onto the phase-1 model exactly — that mapping table is `docs/PRD.md` §5.3
and is not repeated here. What is still owed is **P5, the per-field failure policy**, and it
is the difference between a robust screen and a crash:

| Missing field | Proposed behaviour |
|---|---|
| `title` | Fall back to a generated title from the day count; never blank |
| a stop's `name` | The stop is dropped, not rendered nameless |
| `lat`/`lng` unresolved by geocoding | The stop is dropped **before** it reaches the app; a stop with no point breaks the map fit |
| `detailedPlan` empty | The Detailed view shows the existing empty treatment, not an empty list rendering as a blank panel |
| `hours`, `fee`, `aiNote` | Nullable already; the row hides |
| `tags` unknown value | Already handled — `tagColor()` falls back to `AppColors.inkTertiary`, and Blueprint names that fallback as the contract |
| zero valid stops | Not an itinerary. This is the failure path in §3.5, not an empty Result screen |

**Validation happens once, at the boundary, and produces either an `Itinerary` or a typed
failure.** No screen ever sees a half-parsed response. `RemoteItineraryRepository` is the
swap behind the existing `ItineraryRepository` seam — that is what the seam was for.

### 3.5 Loading needs a failure state, and today it has none (P6)

§3.4 of the PRD specifies a non-interruptible timed transition: no cancel, no error path,
five messages, 7000 ms (V1). That is correct for a hard-coded delay and wrong for a network
round trip that can take longer, fail, or be refused.

What phase 3 needs, and what no design file contains:

- A **cancel** that actually aborts, and returns to the screen the user came from.
- An **error state** with a retry, distinguishing "try again" from "we cannot plan this".
- A **timeout** longer than 7000 ms, with the message rotation continuing rather than
  stalling on the last message.
- A decision on **auto-save**: Task-12 saves on generate. A failed generation must not
  leave a saved route behind.

### 3.6 Testing it without a network

Blueprint forbids network calls in phase 1 and the verification rules demand testable logic.
Both survive phase 3 if the boundary is drawn as above: the request builder and the response
validator are pure functions with fixture JSON, including a deliberately malformed fixture
per row of the §3.4 table. Nothing in the test suite ever reaches the server.

---

## 4. Beyond Firebase and AI — what else is owed

Not scale work. Each of these is either a hole a user falls into today or a thing the two
phases above force into existence.

**Ranked by how much it hurts.**

1. **~~There is no way to plan a second route.~~ Closed 2026-09-12 by Task-22c:** the
   Result header carries "Plan again" (`docs/PRD.md` deviation V14), which resets the
   answers and the session edits and returns to onboarding step 0, asking "Discard edits
   and plan again?" inline when there are unsaved edits. Tested in
   `test/features/itinerary/result_plan_again_test.dart`.
2. **Offline Maps is a toggle that does nothing.** Profile shows "Download maps for areas
   with no signal" and no download exists. On an app about no-signal areas this is the one
   fake control users will actually try. Either it downloads tiles or the row goes.
3. **Language is a screen with one language.** English is listed and selected; nothing
   switches. Real localisation is a large piece of work and every string in the app is
   currently a literal — this is a decision (build it, or reduce the screen), not a bug.
4. **No error or empty states anywhere.** Phase 1 needs none because nothing fails. Phase 2
   and 3 add network, auth and generation failures to screens that have no visual language
   for failure. This is a design deliverable, not a coding one, and it blocks both phases.
5. **Crash reporting.** Once `firebase_core` is in, Crashlytics is nearly free and turns
   "it broke on a phone in Kakadu" into a stack trace. Requires a privacy line.
6. **Places photos** (P7) and marker thumbnails (P8) — both already on the P-list, both
   billable, both needing a placeholder path that already exists (`photoUrl` is nullable).
7. **Analytics.** Deliberately last, and arguably out of scope: it is the one item here that
   serves us rather than the user.

---

## 5. Decisions this file proposes, and what stays open

| | Decision | Proposed here | Still open |
|---|---|---|---|
| P1 | Backend | Firebase — auth, Firestore, later Crashlytics | Confirm; the build-weight cost is real (§2.2) |
| P2 | Fine-tune or RAG | RAG, and outside our boundary (§1) | Nothing for the app |
| P3 | The server | One endpoint, Firebase ID token, no key in the app (§3.3) | Stack, hosting, owner |
| P4 | Prompt template | Server-side, never in the client | Its content |
| P5 | Response schema | Per-field fallbacks (§3.4) | Confirm each row |
| P6 | Loading failure | Cancel, retry, timeout, no save on failure (§3.5) | Needs a design |
| P7 | Images | — | Unchanged |
| P8 | Marker thumbnails | — | Unchanged |
| **new** | Saved routes vs "no third seam" | Firestore inside `PreferencesStore` (§2.3) | Blueprint amendment either way |
| **new** | Stable answer identifiers | Add them; UI copy must not be the wire format (§3.2) | Touches phase-1 tested code |
| **new** | Second route generation | Done — "Plan again", V14, Task-22c (2026-09-12) | Nothing |
| P1 | **Taken 2026-09-22** (`docs/PRD.md` D12) | Firebase confirmed; wave 1 is email/password + Google Sign-In (Task-23…25); Firestore is a later task | Saved-routes seam question (§2.3) waits for that task |
| **all** | **Taken 2026-09-22 evening** (`docs/PRD.md` D13, D14) | §2.3 → option (1), as two injected functions (Task-27); stable answer keys (Task-30); P2–P6 answered in `docs/PHASE-3-CONTRACT.md`; §3.5 Loading states in PRD §3.4 (Task-33) | P7/P8 images; the server itself (teammate) |

---

## 6. Order

Phase 2 before phase 3, as `docs/PRD.md` §5.1 fixes — and §3.3 gives the mechanical reason
rather than just the stated one: the server authenticates requests with a Firebase ID
token, so there is nothing to authenticate with until phase 2 exists.

Before either: **§4.1**. It is phase-1 product work, it needs no backend, and it is a
bigger hole than anything phases 2 and 3 close. *(Closed 2026-09-12, Task-22c — see §4.1.
Phase 2 started 2026-09-22.)*
