# Task-64: With no signal, nothing waits for the network
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator approved the 2026-10-01 audit wave and named Codex; the save path is testable with injected remote functions, and the device check is the main loop's.

**Status: DONE** — verified 2026-10-01, eye check pending: 1
> **Verified against:** 2c4b342981 terra_nt/lib/core/util/maps_url.dart b498ccd988 terra_nt/lib/data/repositories/firestore_saved_routes.dart 72ea7b94ab terra_nt/lib/data/repositories/preferences_store.dart e669c839d1 terra_nt/lib/features/itinerary/result_screen.dart 4a619aa711 terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart 4f43ea4510 terra_nt/lib/features/itinerary/widgets/result_stop_list.dart 275e738759 terra_nt/lib/shared/map/terra_map.dart 7b33e00429 terra_nt/lib/shared/widgets/placeholder_tile.dart 2a9bd05e62 terra_nt/test/core/util/util_test.dart d5dec95260 terra_nt/test/data/repositories/repositories_test.dart 83d0c6b410 terra_nt/test/features/itinerary/result_screen_test.dart b0d47d3beb terra_nt/test/features/itinerary/stop_detail/stop_detail_screen_test.dart 01f59b1326 terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart 1fc0de83e5 terra_nt/test/shared/map/terra_map_test.dart e125a0f987 terra_nt/test/shared/widgets/placeholder_tile_test.dart

**Lane**
- OWNS: `terra_nt/lib/data/repositories/preferences_store.dart`, `terra_nt/lib/data/repositories/firestore_saved_routes.dart`, `terra_nt/lib/shared/map/terra_map.dart`, `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart`, `terra_nt/lib/features/itinerary/widgets/result_stop_list.dart`, `terra_nt/lib/shared/widgets/placeholder_tile.dart`, `terra_nt/lib/core/util/maps_url.dart`, `terra_nt/test/data/repositories/repositories_test.dart`, `terra_nt/test/shared/map/terra_map_test.dart`, `terra_nt/test/features/itinerary/result_screen_test.dart`, `terra_nt/test/features/itinerary/stop_detail/stop_detail_screen_test.dart`, `terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart`, `terra_nt/test/shared/widgets/placeholder_tile_test.dart`, `terra_nt/test/core/util/util_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/data/repositories/notifiers.dart` (Task-65), `terra_nt/lib/core/util/saved_routes_ops.dart` (Task-65), `terra_nt/lib/features/saved/` (Task-65), `terra_nt/lib/shared/map/tile_cache.dart`, `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**A signed-in user with no signal can do everything the app promises offline, and when
something needs the network the app says so instead of hanging or doing nothing.**

- **Saving never waits for the cloud.** Today `PreferencesStore` awaits `pushRemote` after the
  local write, and `FirestoreSavedRoutes.push` awaits a `get()` and a `batch.commit()`. A
  Firestore commit completes only when the server acknowledges it. So with no signal, saving
  the offline suggestion (Loading → "Use an offline route") can hang before Result opens.
  - Every save returns as soon as the local key is written. The remote push runs after, not
    awaited by the caller. It must not throw into the UI, and the cloud copy catches up later.
  - Delete-account keeps its current contract: it must know the remote was cleared.
  - The push should also not depend on a server read it cannot get offline; the builder chooses
    how, inside Blueprint D13 (local key is the source of truth).
- **Unviewed map areas explain themselves.** Where tiles are not cached and cannot load, the map
  says so plainly: only areas you have opened are kept offline (D22). The stop list and place
  details remain the useful fallback. No bulk download.
- **Navigate and Export never silently do nothing.**
  - Export is disabled, with a short reason, when fewer than two active stops remain.
  - When the maps app cannot be opened, the user is told so and can copy the destination
    coordinates instead.
- **A failed online photo falls back to the bundled picture.** When a stop's `photoUrl` fails to
  load, show its bundled place or category picture, not a blank placeholder.

## Why

`reports/research/2026-10-01-qol-audit.md` rows 2, 11, 15 and 17. The app's premise is no signal.
The offline route from Task-60 is exactly the path a user in the outback takes, and it must not
hang there.

## Acceptance

- [x] The Lane GATE passes.
- [x] Unit tests: a save with a remote push that never completes still returns after the local write, and the local key holds the routes. A push that throws does not surface. Delete-account still fails when the remote clear fails.
- [x] Unit tests: the push performs no blocking server read before writing (or the builder's equivalent guarantee), with the remote functions injected as closures (no Firebase test double, per Blueprint).
- [x] Widget tests: Export is disabled with its reason below two active stops. A failed launch shows the message and the copy-coordinates action. A failing `photoUrl` shows the bundled picture.
- [x] Widget test: a tile layer whose tiles fail shows the offline-area explanation.
- [x] Device check (main loop, `emulator-5554`, signed in): airplane mode on, plan a trip, "Use an offline route". Result opens within a few seconds and the route is in Saved. After airplane mode goes off, the cloud copy catches up. Pan to an area never opened: the explanation shows. Logcat has no Flutter exception.
  *2026-10-01, main loop:* Result opened 0.66 s after the tap in airplane mode, and the route was in Saved. The offline-area note showed. Logcat had only tile lookup failures (expected offline), no exception. **Cloud catch-up not verified:** no Firestore console access from the main loop. Only the unit tests cover it.
- [ ] (eye) The offline-area explanation and the Export reason read as calm information, not as error dumps.

## Out of scope

- Saved route management (Task-65). Bulk tile download (D22).
- Changing which data persists (D3 keys stay two).
