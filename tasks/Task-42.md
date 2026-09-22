# Task-42 — Place images replace the placeholders on Stop detail, Explore and Saved Routes

> **Execution:** agent `codex` · effort `high` (a bee lane; the goal run's bees are Claude by operator decision, 2026-09-23)
> *Why:* A name→asset lookup in tier 1 and one optional image slot in the shared tile,
> judged by widget tests. The images were generated with `gpt-image-2` by the
> orchestrator (operator decision, `docs/PRD.md` D15) and are already in
> `terra_nt/assets/images/places/`; recorded as V22 at integration.

**Lane**
- OWNS: `terra_nt/lib/data/seed/place_images.dart` (new), `terra_nt/lib/shared/widgets/placeholder_tile.dart`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart` (the hero call only), `terra_nt/lib/features/explore/explore_screen.dart` (the POI card thumbnail call only), `terra_nt/lib/features/saved/saved_routes_screen.dart` (the route thumbnail call only), `terra_nt/pubspec.yaml` (the `flutter: assets:` list only — add `- assets/images/places/`; no dependency line changes), `terra_nt/test/data/place_images_test.dart` (new), `terra_nt/test/shared/widgets/`
- MUST NOT TOUCH: `terra_nt/assets/` (the files are final), `terra_nt/lib/data/models/`, `terra_nt/lib/data/repositories/`, `terra_nt/lib/core/theme/` except appending a named metric, `terra_nt/lib/features/itinerary/result_screen.dart` and `widgets/` (Task-40), `terra_nt/test/features/itinerary/` (Task-40), `terra_nt/android/`, `tools/goal_gate.py`
- GATE: `cd terra_nt && flutter analyze && flutter test test/data/place_images_test.dart test/shared/widgets/ test/features/explore/ test/features/saved/`
- DEPENDS ON: Task-41

## The contracts — fixed

1. **Assets (already present):** `assets/images/places/{darwin,mindil,litchfield,kakadu,nitmiluk,alice-springs,desert-park,kings-canyon,uluru}.jpg`, 1200×800.
2. **`place_images.dart`** — tier 1, no `package:flutter`:
   `String? placeImageFor(String name)` returns `assets/images/places/<slug>.jpg` by
   case-insensitive substring match, first hit wins, in this order:
   `Desert Park`→desert-park, `Alice Springs`→alice-springs, `Mindil`→mindil,
   `Darwin`→darwin, `Litchfield`→litchfield, `Kakadu`/`Ubirr`→kakadu,
   `Nitmiluk`/`Katherine`→nitmiluk, `Kings Canyon`/`Watarrka`→kings-canyon,
   `Uluru`→uluru; anything else → `null`. (Order matters: "Alice Springs Desert Park"
   must map to desert-park, "Darwin Waterfront" to darwin.)
3. **`PlaceholderTile`** gains an optional `String? image` on both constructors. When
   non-null it renders `Image.asset(image, fit: BoxFit.cover)` clipped to the tile's
   existing radius, with `errorBuilder` falling back to the current placeholder body.
   When `image` is an `http(s)` URL it renders `Image.network` with the same
   `errorBuilder` — that is the phase-3 `photoUrl` path (`docs/PRD.md` §5.3). Null keeps
   today's placeholder exactly. The constructors may stop being `const`-only; call sites
   that pass `image` drop `const`.
4. **Call sites:** Stop detail hero passes `stop.photoUrl ?? placeImageFor(stop.name)`;
   Explore's POI card passes `poi.photoUrl ?? placeImageFor(poi.name)`; Saved Routes
   passes `placeImageFor(route.stops.isEmpty ? route.title : route.stops.last.name)` (the
   destination is the memorable image).
5. Hero overlays (the back button) keep their contrast: if the hero needs a scrim for
   the button, reuse the existing scrim token; no new gradient.

## Acceptance Criteria (DoD)

- [ ] `place_images_test.dart` covers every seeded stop and POI name (iterate `seedStops`, `redCentreStops` and the POI seed) and asserts each maps to an existing file under `assets/images/places/` (use `File(...).existsSync()` relative to `terra_nt/`), plus `Alice Springs Desert Park`→desert-park and an unknown name → null.
- [ ] A widget test pumps `PlaceholderTile.hero(image: 'assets/images/places/uluru.jpg')` and finds an `Image` whose provider is an `AssetImage` with that path; with `image: null` it finds no `Image`.
- [ ] A widget test with an `image` that fails to load renders the placeholder icon (errorBuilder path).
- [ ] `grep -n "assets/images/places/" pubspec.yaml` matches.
- [ ] `cd terra_nt && flutter analyze` is clean.
- [ ] `cd terra_nt && flutter test` passes.
