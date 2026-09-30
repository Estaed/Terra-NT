# Task-63: Map areas you have opened stay on the phone for 30 days
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator chose this after the 2026-09-30 offline-map research (Blueprint D22) and named Codex; the change is small, and cache behaviour is testable.

**Lane**
- OWNS: `terra_nt/lib/main.dart`, `terra_nt/lib/shared/map/terra_map.dart`, `terra_nt/lib/shared/map/tile_cache.dart` (new), `terra_nt/lib/core/util/tile_cache_key.dart` (new), `terra_nt/lib/features/profile/profile_screen.dart`, `terra_nt/test/shared/map/tile_cache_test.dart` (new), `terra_nt/test/shared/map/terra_map_test.dart`, `terra_nt/test/core/util/tile_cache_key_test.dart` (new), `terra_nt/test/features/profile/profile_screen_test.dart`
- MUST NOT TOUCH: `terra_nt/pubspec.yaml` and `terra_nt/pubspec.lock` (`path_provider` is already declared by the main loop), `terra_nt/lib/shared/map/tile_warmup.dart`, `terra_nt/lib/data/`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**A map area the user has looked at still shows with no phone signal, for up to 30 days, and the
app says so honestly.**

- **The cache survives.** Tiles are cached by `flutter_map`'s built-in
  `BuiltInMapCachingProvider`, configured once at startup:
  - The cache lives in the app-support directory (`path_provider`), not the OS cache
    directory that Android may clear.
  - `overrideFreshAge` is 30 days, a named constant whose comment cites CARTO's Basemap Terms
    (2026-09-29, device caching at most 30 days).
- **Stale is not blank.** Today CARTO's `max-age=86400` makes a cached tile stale after a day.
  A stale tile is refetched, and with no signal it goes blank. With the 30-day freshness, a
  tile viewed yesterday renders offline today.
- **The key does not split the cache.** The cache key is the tile URL without its `?key=`
  query, as a pure tier-1 function, so a new CARTO key keeps the existing cache.
- **Honest copy.** Profile gets an information row in the style of the existing
  "Crash reports" row: a title and one plain line saying that map areas you have opened stay
  available offline for up to 30 days. Wording is the builder's; it must promise no more than that.
- Every map in the app (Explore, Result, Loading, onboarding, the Welcome warm-up) keeps
  working as today, online and with no key.

## Why

The app's premise is driving where there is no signal, yet the map went blank a day after it
was viewed. A bulk "download route" is not allowed on CARTO (Blueprint D22), so the honest
version is to keep what the user has already seen for as long as the terms allow.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Unit tests: the cache key of two tile URLs that differ only in `key=` is identical; different z/x/y or `{r}` give different keys; a URL with no query is unchanged.
- [ ] Tests: the configured provider uses a 30-day `overrideFreshAge` and a directory under app support, not the OS cache. A failure to get the directory falls back to `flutter_map`'s default cache rather than crashing startup.
- [ ] Widget test: Profile shows the offline-map information row, and it has no switch or action.
- [ ] Device check (main loop, `emulator-5554`): open Full NT in Result and let the map load, turn on airplane mode, force-stop and relaunch, and reopen it. The tiles viewed before still render. If the emulator clock can be moved forward two days, the same holds after that. Logcat shows no Flutter exception.
- [ ] (eye) Profile's new row reads plainly next to "Crash reports" and does not look like a setting.

## Out of scope

- A "download this route" button or any bulk prefetch (CARTO terms, D22).
- Changing tile provider or moving to vector tiles.
- Cache-management UI (size, clear), and changes to the Welcome warm-up.

Fixed: the tile URL template `cartoDarkTileUrl` and `additionalOptions` stay as they are.
