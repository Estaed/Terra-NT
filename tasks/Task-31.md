# Task-31 — `PlanFailure` and `parsePlanResponse`, with one fixture per failure row

**Status: DONE** — verified 2026-09-23 00:27 (otopilot: worktree gate green, integrated gate green on main, 403 tests)

> **Execution:** agent `codex` · effort `high` (a bee lane; tonight's bees are Claude by operator decision, 2026-09-22)
> *Why:* Tier 1 pure Dart against a fixed table (`docs/PHASE-3-CONTRACT.md` §3.3); the
> criterion is `flutter analyze` + tests reading fixture files. Nothing to judge by eye.

**Lane**
- OWNS: `terra_nt/lib/data/models/plan_failure.dart` (new), `terra_nt/lib/core/util/plan_response.dart` (new), `terra_nt/test/core/util/plan_response_test.dart` (new), `terra_nt/test/fixtures/plan/` (new)
- MUST NOT TOUCH: `terra_nt/lib/core/util/stop_json.dart` (Task-26 — consume `stopFromJson`, do not edit), `terra_nt/lib/data/repositories/`, `terra_nt/lib/features/`, `terra_nt/pubspec.yaml`
- GATE: `cd terra_nt && flutter analyze && flutter test test/core/util/plan_response_test.dart`
- DEPENDS ON: Task-26

## Objective

Validation happens once, at the boundary, and produces either an `Itinerary` or a typed
failure — no screen ever sees a half-parsed response (`docs/PRD.md` D14, P5). This task
is that boundary: the failure type every later task throws and catches, and the parser
that applies the per-field table. The fixtures it writes are also what the stub server
(Task-32) serves, so the emulator tour and the unit tests exercise one body.

## The contracts — fixed, not guidance

### 1. `PlanFailure` — `lib/data/models/plan_failure.dart`

```dart
enum PlanFailure {
  network, timeout, cannotPlan, rateLimited, unauthorised, serverError,
  invalidResponse, cancelled,
}

class PlanException implements Exception {
  const PlanException(this.failure, [this.detail]);
  final PlanFailure failure;
  final String? detail;   // for logs; never shown
}
```

### 2. `parsePlanResponse` — `lib/core/util/plan_response.dart`

```dart
/// [days] is the answer that produced the request; only the title fallback uses it.
Itinerary parsePlanResponse(String body, {required int days});
```

Applies `docs/PHASE-3-CONTRACT.md` §3.3 row by row, and throws
`PlanException(PlanFailure.invalidResponse, <why>)` on: body not a JSON object,
`schemaVersion != 1`, `stops` not a list, fewer than 2 stops surviving the drops. Uses
`stopFromJson` for the per-stop fallbacks; wraps it so that a `FormatException` (missing
`name`, bad `lat`/`lng`) **drops that stop** rather than failing the response. Adds the
two checks `stopFromJson` does not make: the NT bounding box (`lat −26.5…−10.5`,
`lng 128.5…138.5`, outside → drop) and `photoUrl` must start with `http://` or
`https://` (else `null`). Keeps the first 14 valid stops. `placeId` and `sources` are
ignored. Title fallback: `'$days-day Northern Territory trip'`.

Also here, because Task-32 and Task-33 both need it:

```dart
/// HTTP status + body → the failure the contract's §1 table names.
PlanFailure failureForStatus(int statusCode, String body);
```

`400`/`422` → `cannotPlan`; `401` → `unauthorised`; `429` → `rateLimited`; any other
non-2xx → `serverError`; an `error.code` of `cannot_plan`/`unauthorised`/`rate_limited`
in the body overrides the status, an unknown code does not.

### 3. Fixtures — `test/fixtures/plan/`

| File | Content |
|---|---|
| `ok.json` | A valid 5-stop Top End response with every optional field exercised at least once (`fee` null on one stop, `driveNext` null on the last, `photoUrl` an https URL on one, an unknown tag `"Foodie"` on one, an empty `detailedPlan` on one) |
| `invalid_one_stop.json` | Valid shape, one stop |
| `invalid_version.json` | `schemaVersion: 2` |
| `missing_title.json` | No `title`; otherwise `ok.json` |
| `stop_without_name.json`, `stop_string_lat.json`, `stop_outside_nt.json` | One bad stop each among four good ones |
| `stop_missing_fields.json` | A stop with only `name`, `lat`, `lng` |
| `bad_plan_entry.json` | A `detailedPlan` with one entry lacking `activity` |
| `bad_photo_url.json` | `photoUrl: "ftp://…"` |
| `fifteen_stops.json` | 15 valid stops |
| `error_cannot_plan.json`, `error_rate_limited.json`, `error_unknown_code.json` | Error bodies from the contract's §1 |

Copy in `ok.json` is realistic NT content in the prototype's voice, sentence case; the
stub serves it to a human on the emulator.

## Execution Guide

Write `PlanFailure` first (two siblings import it), then the parser against `ok.json`,
then one test per fixture. Read fixtures with `File('test/fixtures/plan/<name>')`
relative to `terra_nt/` — `flutter test` runs from there.

## Acceptance Criteria (DoD)

- [x] Both new `lib/` files import no `package:flutter`.
- [x] `plan_response_test.dart` has one test per fixture file above and asserts, in
      order: `ok.json` → 5 stops, title kept, the null `fee`, the null last `driveNext`,
      the https `photoUrl` kept, `"Foodie"` kept in tags, the empty `detailedPlan`;
      `invalid_one_stop`, `invalid_version` → `invalidResponse`; `missing_title` →
      `'7-day Northern Territory trip'` with `days: 7`; the three bad-stop fixtures → 4
      stops; `stop_missing_fields` → the contract fallbacks on that stop;
      `bad_plan_entry` → the other entries kept; `bad_photo_url` → null;
      `fifteen_stops` → 14.
- [x] `failureForStatus` is tested for 200-with-error-body (code wins), 400, 401, 422,
      429, 500, 503, and 400 with an unknown code (`cannotPlan` from the status).
- [x] `cd terra_nt && flutter analyze` is clean.
- [x] `cd terra_nt && flutter test` passes.
