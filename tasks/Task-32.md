# Task-32 — `RemoteItineraryRepository`, the `PLAN_API_URL` switch, and the stub server

> **Execution:** agent `codex` · effort `high` (a bee lane; tonight's bees are Claude by operator decision, 2026-09-22)
> *Why:* One class over one `POST`, tested with `http`'s `MockClient`; a provider switch;
> a Python stub with fixed modes. The criterion is `flutter analyze` + tests + the stub
> answering `curl`. The emulator tour against the stub is the main loop's, after
> integration.

**Lane**
- OWNS: `terra_nt/lib/data/repositories/remote_itinerary_repository.dart` (new), `terra_nt/lib/data/repositories/notifiers.dart` (the `itineraryRepositoryProvider` body only — Task-27 owns the rest of this file; append-only, touch nothing else in it), `terra_nt/lib/app/plan_config.dart` (new), `terra_nt/test/data/repositories/remote_itinerary_repository_test.dart` (new), `terra_nt/android/app/src/debug/AndroidManifest.xml`, `terra_nt/.env.example`, `tools/plan_stub/server.py` (new, repo root), `tools/plan_stub/README.md` (new)
- MUST NOT TOUCH: `terra_nt/lib/core/util/plan_response.dart` and `plan_request.dart` (Task-31, Task-30 — consume), `terra_nt/lib/data/repositories/preferences_store.dart`, `auth_repository.dart`, `firebase_auth_repository.dart`, `itinerary_repository.dart`, `terra_nt/lib/features/`, `terra_nt/lib/main.dart`, `terra_nt/android/settings.gradle.kts`, `terra_nt/android/app/build.gradle.kts` (Task-29), `terra_nt/pubspec.yaml`, `terra_nt/test/fixtures/` (Task-31 — read only)
- GATE: `cd terra_nt && flutter analyze && flutter test test/data/repositories/remote_itinerary_repository_test.dart`
- DEPENDS ON: Task-27, Task-30, Task-31 (Task-27 for `notifiers.dart`; the provider body is appended after its changes)

## Objective

The second implementation of the generation seam: build the request, send it with the
Firebase ID token, map the answer to an `Itinerary` or a `PlanException`, within one
timeout. Chosen only when `PLAN_API_URL` is configured, so a keyless checkout and the
test suite never open a socket. The stub server lets the whole flow — including every
failure state Task-33 builds — be toured on the emulator before the teammate's server
exists (`docs/PHASE-3-CONTRACT.md` §1, §6, §8; `docs/PRD.md` D14).

## The contracts — fixed, not guidance

### 1. `plan_config.dart` — `lib/app/`

```dart
const planApiUrl = String.fromEnvironment('PLAN_API_URL');
const planTimeout = Duration(milliseconds: 60000);   // contract §1
```

`.env.example` gains `PLAN_API_URL=` with the comment from the contract's §6 (emulator
→ `http://10.0.2.2:8787`).

### 2. `RemoteItineraryRepository` — `lib/data/repositories/remote_itinerary_repository.dart`

```dart
class RemoteItineraryRepository implements ItineraryRepository {
  RemoteItineraryRepository({
    required http.Client client,
    required Uri baseUrl,                 // no trailing slash
    required Future<String?> Function() idToken,   // AuthRepository.idToken
    Duration timeout = planTimeout,
    String Function() requestId = newRequestId,
  });

  /// One attempt. Throws PlanException; never returns a partial itinerary.
  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers);

  /// The requestId of the last attempt, reused by [retry].
  String? get lastRequestId;
  /// Resends the last answers with the same requestId (contract §1, idempotency).
  Future<Itinerary> retry();
}
```

Behaviour, in order: `idToken()` null → `PlanException(unauthorised)`; it throws
`AuthException(network)` → `PlanException(network)`. `POST {baseUrl}/v1/itinerary` with
the three headers from the contract's §1 and `jsonEncode(buildPlanRequest(...))`.
`.timeout(timeout)` → `PlanException(timeout)`. `SocketException`,
`http.ClientException` → `network`. Non-2xx → `PlanException(failureForStatus(status,
body))`. 2xx → `parsePlanResponse(body, days: answers.days)` (its `invalidResponse`
propagates). Nothing is retried inside; the screen decides.

### 3. Provider switch — `notifiers.dart`

```dart
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  if (planApiUrl.isEmpty) return SeedItineraryRepository();
  return RemoteItineraryRepository(
    client: http.Client(),
    baseUrl: Uri.parse(planApiUrl),
    idToken: () => ref.read(authRepositoryProvider).idToken(),
  );
});
```

Tests override the provider as they do today; none sets `PLAN_API_URL`.

### 4. Debug manifest — cleartext to the stub only

`android/app/src/debug/AndroidManifest.xml` gains an `<application
android:usesCleartextTraffic="true" />` merge so a debug build can reach
`http://10.0.2.2:8787`. The main manifest is untouched: release builds stay https-only.

### 5. The stub — `tools/plan_stub/server.py`

Python 3 standard library only (`http.server`, `json`, `argparse`, `time`). Exactly the
modes and behaviours in `docs/PHASE-3-CONTRACT.md` §8, reading the fixture files from
`terra_nt/test/fixtures/plan/` relative to the repo root. Logs one line per request:
method, path, `requestId`, and whether `Authorization` was present. `README.md`: the
run line and the `.env` line, five lines total.

## Execution Guide

Repository with `MockClient` first — every branch is one handler that returns a status
and a fixture body, or throws. Then the provider switch (one `flutter test` run proves
the default path still picks the seed). Then the manifest and the stub; verify the stub
with `curl -X POST localhost:8787/v1/itinerary -d '{}'` in each mode.

## Acceptance Criteria (DoD)

- [ ] `remote_itinerary_repository_test.dart` (MockClient, in-memory token): sends
      `POST` to `/v1/itinerary` with `Authorization: Bearer test-token`, a JSON body whose
      `answers.companions` is a key not a label, and `schemaVersion: 1`; `ok.json` body
      → 5-stop itinerary; 422 + `error_cannot_plan.json` → `cannotPlan`; 401 →
      `unauthorised`; 429 → `rateLimited`; 500 → `serverError`; handler that throws
      `SocketException` → `network`; handler that delays past a 50 ms test timeout →
      `timeout`; `invalid_one_stop.json` → `invalidResponse`; null token →
      `unauthorised` without any request; `retry()` sends the same `requestId` as the
      first attempt.
- [ ] `grep -n "planApiUrl.isEmpty" lib/data/repositories/notifiers.dart` matches, and
      the full test suite passes with no `PLAN_API_URL` defined.
- [ ] `android/app/src/debug/AndroidManifest.xml` contains `usesCleartextTraffic`; the
      main manifest does not (`grep -c` is 0).
- [ ] `python tools/plan_stub/server.py --mode ok --port 8787` answers a `POST` with 200
      and the `ok.json` body; `--mode cannot_plan` answers 422; `--mode error` answers
      500 (checked with `curl` in the report).
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
