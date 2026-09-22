# Otopilot plan — 2026-09-22 night

| | |
|---|---|
| SOURCE | `tasks` — Task-26…33 (phase 2 wave 2 + phase 3 wave 1), nothing beyond them |
| UNTIL | `2026-09-23T07:00` (local, AUSCST); resolved at plan time 23:55 |
| Direction | Claude main loop orchestrates, **Claude bees** (`--orchestrator claude --delegate claude`) — operator decision ("claude swarm kullan"); no Codex, no fallback row |
| Planner | `fable` (this foreground session) |
| Orchestrator | `fable`, same session — the operator is asleep and no `opus` session is open; the quota cost of that is recorded per wave below |
| BASE_SHA | `git rev-parse HEAD` after this plan is committed (preflight OK on `cf7dde5` + routing commit; re-run after the plan commit) |
| Baseline gate | `cd terra_nt && flutter analyze && flutter test` — running at plan time, result recorded in the first checkpoint |
| Stop markers | none in Task-26…33 (preflight) |
| Quota at plan time | Claude 5 saatlik 52% (resets 01:20), haftalık 51% (resets 27 Sep); Codex unused |
| Timebox per bee | 45 min wall clock; second attempt 30 min |
| Wave minutes (for `--wave-minutes`) | 60 |

## Waves

| Task | Wave | Agent | Tier | Effort | OWNS (short) | GATE | Attempts |
|---|---|---|---|---|---|---|---|
| 26 Saved routes carry stops; seam growth | 1 | Claude bee | `opus` | high | models `saved_route`, `session`; `core/util/stop_json.dart`; seed `seedSavedRoutes`; `data/repositories/*`; `features/loading`, `features/saved`; tests | `flutter analyze && flutter test` | ≤2 |
| 27 Firestore saved routes | 2 | Claude bee | `opus` | high | `preferences_store.dart`, `firestore_saved_routes.dart`, `notifiers.dart` (store + saved-routes + delete order); `test/data/repositories/`; root `firestore.rules`, `firebase.json`, `.firebaserc` | `flutter analyze && flutter test test/data/` | ≤2 |
| 28 Password reset, email verification | 2 | Claude bee | `sonnet` | high | `features/auth/login_screen.dart`, `features/profile/account/`; their tests | `flutter analyze && flutter test test/features/auth/ test/features/profile/account/` | ≤2 |
| 29 Crashlytics | 2 | Claude bee | `sonnet` | high | `main.dart`, two Gradle files, `profile_screen.dart`, its test, `boot_test.dart` | `… && flutter build apk --debug` | ≤2 |
| 30 Answer keys, PlanRequest | 2 | Claude bee | `sonnet` | high | `onboarding_answers.dart`, `seed/onboarding_options.dart`, `core/util/plan_request.dart`, `features/onboarding/`; tests | `flutter analyze && flutter test test/core/util/ test/features/onboarding/` | ≤2 |
| 31 PlanFailure, parsePlanResponse | 2 | Claude bee | `sonnet` | high | `models/plan_failure.dart`, `core/util/plan_response.dart`, `test/fixtures/plan/`, its test | `flutter analyze && flutter test test/core/util/plan_response_test.dart` | ≤2 |
| 32 RemoteItineraryRepository, stub | 3 | Claude bee | `sonnet` | high | `remote_itinerary_repository.dart`, `notifiers.dart` (provider body), `app/plan_config.dart`, debug manifest, `.env.example`, `tools/plan_stub/`; its test | `flutter analyze && flutter test test/data/repositories/remote_itinerary_repository_test.dart` | ≤2 |
| 33 Loading failure state | 3 | Claude bee | `opus` | high | `features/loading/`, `result_stop_list.dart`, `stop_detail_screen.dart`, `core/util/plan_failure_copy.dart`; tests | `flutter analyze && flutter test test/features/loading/ test/features/itinerary/ test/core/util/plan_failure_copy_test.dart` | ≤2 |

Dependency graph: 26 → {27, 28, 29, 30, 31} → {32 (needs 27, 30, 31), 33 (needs 31)}.
Wave 2 ownership is pairwise disjoint (preflight `owns_disjoint` OK after the two fixes:
Task-27's delete-order test moved to the notifier test, Task-32 depends on Task-27).

Shared, append-only: `terra_nt/lib/data/repositories/notifiers.dart` (27 then 32, serial by
dependency); `terra_nt/test/data/models_seed_test.dart` (26 then 30, serial by dependency).

Full project gate on main after every cherry-pick: `cd terra_nt && flutter analyze && flutter test`.
`verify-task`'s deterministic stand-in is that gate; DONE ticks land in the task's integrated commit.

## Excluded

None of the eight. Main-loop sequels that are **not** part of the run and are reported as
pending: Task-27 console steps (Firestore API enable, `databases:create`, rules deploy) and
emulator tour; Task-32 stub tour on the emulator; Task-33 device tour (Back behaviour).

## Quota estimate per wave (window points, Claude 5-hour)

| Wave | Bees | Estimate | Measured |
|---|---|---|---|
| 1 | 1 × opus | 8 | — |
| 2 | 2 × opus + 3 × sonnet | 25 | — |
| 3 | 1 × opus + 1 × sonnet | 12 | — |

The 5-hour window resets at 01:20; wave 1 runs before it, waves 2–3 after. Weekly at 51%
leaves room. Between waves: `onkontrol.py --quota-only --orchestrator claude --delegate claude
--until 2026-09-23T07:00 --wave-minutes 60`.

## Checkpoints

Appended to `reports/otopilot-2026-09-22-report.md` after each wave: rows, measured quota
delta, next wave.
