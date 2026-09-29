# Task-46 — Seven more places on Explore, and every place gets a picture

> **Execution:** agent `ultracode` · effort `xhigh`
> *Why:* Seed data plus one tier-1 lookup and three call sites, judged by the suite and by eye
> on Explore, Stop detail and Saved Routes; one builder owns it, the screen lens looks at it.

**Lane**
- OWNS: `terra_nt/lib/data/seed/seed_data.dart` (the `seedPois` list only — append), `terra_nt/lib/data/seed/place_images.dart`, `terra_nt/lib/features/explore/explore_screen.dart` (the POI card image call only), `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart` (the hero image call only), `terra_nt/lib/features/saved/saved_routes_screen.dart` (the route thumbnail call only), `terra_nt/test/data/place_images_test.dart`, `terra_nt/test/` files that assert the POI count or list (update the count only)
- MUST NOT TOUCH: `terra_nt/assets/` (the images are final), `terra_nt/lib/data/models/`, `terra_nt/lib/data/repositories/`, `terra_nt/lib/core/`, `terra_nt/lib/shared/`, `terra_nt/pubspec.yaml`, `terra_nt/ios/`, `terra_nt/android/`, `tools/`, `CLAUDE.md`, `AGENTS.md`, `docs/`
- GATE: `cd terra_nt && flutter analyze && flutter test`
- DEPENDS ON: none (the images are committed before `BASE_SHA`)

## Goal

Explore shows fifteen places instead of eight, each with its own illustration, and a stop the
AI names that is not one of the known places still shows a picture chosen by its tag instead
of the grey placeholder.

## Why

Operator, 2026-09-29: "biraz daha lokasyon ekle explore kısmına" and "görselleri codexle
üret". With the planning server live (Task-45), itineraries will name places outside the nine
illustrated ones; today those render the placeholder.

## The contracts — fixed

1. **Images (already committed, 1200×800 JPEG, `gpt-image-2`, same series as V22):**
   `assets/images/places/` gains `kata-tjuta`, `ormiston-gorge`, `karlu-karlu`, `mataranka`,
   `edith-falls`, `wildlife-park`, `standley-chasm`, and the tag fallbacks `tag-nature`,
   `tag-culture`, `tag-adventure`, `tag-wildlife`, `tag-relaxation`. The pubspec already lists
   the directory.
2. **Seven POIs appended to `seedPois`**, in this order, ids fixed:

   | id | name | tag |
   |---|---|---|
   | `kata-tjuta` | Kata Tjuta | Culture |
   | `ormiston` | Ormiston Gorge | Nature |
   | `karlu-karlu` | Karlu Karlu (Devils Marbles) | Culture |
   | `mataranka` | Mataranka Thermal Pool | Relaxation |
   | `edith-falls` | Leliyn (Edith Falls) | Nature |
   | `wildlife-park` | Territory Wildlife Park | Wildlife |
   | `standley-chasm` | Standley Chasm | Adventure |

   - `lat`/`lng`: geocode each name with Nominatim
     (`https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=au&q=…`,
     identifying `User-Agent`, one request per second), rounded to 4 decimal places like the
     seed, and check each falls inside the NT box (`lat −26.5…−10.5`, `lng 128.5…138.5`).
   - `rating`: the place's public review rating (Google Maps or Tripadvisor) rounded to one
     decimal, as a string like the seed. Put the source URL for each rating in a comment
     above the entry. If no public rating can be found, stop and report which one; do not
     invent one.
   - `description`: one factual sentence, at most 80 characters, sentence case, in the voice
     of the existing eight (a what-to-do line, not marketing). No emoji.
   - Kata Tjuta and Karlu Karlu are sacred sites: nothing in the copy suggests climbing or
     entering restricted areas.
3. **`placeImageFor(String name, {Iterable<String> tags = const []})`** — tier 1, no
   `package:flutter`. Name match first, exactly as today, with matchers appended after the
   existing ones (order matters: "Uluru-Kata Tjuta National Park" still maps to `uluru`):
   `kata tjuta`/`olgas` → kata-tjuta, `ormiston` → ormiston-gorge, `karlu karlu`/`devils
   marbles` → karlu-karlu, `mataranka`/`bitter springs` → mataranka, `edith falls`/`leliyn` →
   edith-falls, `wildlife park` → wildlife-park, `standley chasm`/`angkerle` → standley-chasm.
   No name hit → the first of `tags` that is exactly one of `Nature`, `Culture`,
   `Adventure`, `Wildlife`, `Relaxation` → `assets/images/places/tag-<lowercase>.jpg`.
   Neither → `null` (the placeholder stays the last resort).
4. **Call sites pass the tags:** Stop detail `stop.photoUrl ?? placeImageFor(stop.name, tags: stop.tags)`;
   Explore `poi.photoUrl ?? placeImageFor(poi.name, tags: [poi.tag])`; Saved Routes keeps
   keying on the first stop and passes that stop's tags.
5. The Explore camera fits `poiBounds(pois)` and the tile warmup uses the same list, so no fit
   code changes; if the new bounds push a pin under the search field or the status bar, report
   it rather than changing the fit.

## Acceptance Criteria (DoD)

- [ ] `place_images_test.dart` still iterates every seeded stop and POI name and asserts each
      maps to an existing file; it adds: `Uluru-Kata Tjuta National Park` → uluru,
      `Kata Tjuta` → kata-tjuta, an unknown name with tags `["Wildlife"]` → tag-wildlife,
      an unknown name with tags `["Unknown", "Culture"]` → tag-culture, an unknown name with
      no known tag → null, and every `tag-*.jpg` exists.
- [ ] `seedPois` has 15 entries, ids unique, all coordinates inside the NT box.
- [ ] `cd terra_nt && flutter analyze` is clean; `cd terra_nt && flutter test` passes.
- [ ] (eye) Explore on the emulator: fifteen pins, none hidden under the search field or the
      status bar; tapping each new pin shows its card with its own illustration.
- [ ] (eye) Stop detail for a stop whose name is not a known place shows its tag's picture.
