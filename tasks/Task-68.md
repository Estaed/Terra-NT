# Task-68: Saved copies of the demo routes get the corrected road facts
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator chose option (a) on 2026-10-01 and named Codex; the migration is a pure function, and the main loop proves it on the emulator's real stored data.

**Status: DONE** — verified 2026-10-01
> **Verified against:** a80aed46f4 terra_nt/lib/core/util/saved_routes_ops.dart 8d940fcbbe terra_nt/lib/data/repositories/preferences_store.dart b4510157b0 terra_nt/test/core/util/saved_routes_order_test.dart 3cc387f620 terra_nt/test/core/util/seed_facts_migration_test.dart fdc31fe4f7 terra_nt/test/data/repositories/repositories_test.dart

**Lane**
- OWNS: `terra_nt/lib/core/util/saved_routes_ops.dart`, `terra_nt/lib/data/repositories/preferences_store.dart`, `terra_nt/test/core/util/saved_routes_order_test.dart`, `terra_nt/test/data/repositories/repositories_test.dart`, `terra_nt/test/core/util/seed_facts_migration_test.dart` (new)
- MUST NOT TOUCH: `terra_nt/lib/data/seed/seed_data.dart` (the source of the corrected facts), `terra_nt/lib/data/repositories/firestore_saved_routes.dart`, `terra_nt/lib/shared/map/` (Task-69), `terra_nt/lib/features/` (Task-69), `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**A user who saved "Full NT" or "7 Days in the Red Centre" before Task-66 sees the corrected
drive distances and times, and nothing else about their saved routes changes.**

- A saved route carries its own stops (Blueprint D13), so Task-66's corrected `seedStops` and
  `redCentreStops` never reached copies saved earlier. The emulator's stored "Full NT" still says
  "670 km · 7h to Alice Springs" and "300 km · 3h to Uluru".
- When saved routes load (local key, or a first pull from the cloud), the seeded route ids
  `full-nt` and `red-centre` have each stop's `driveNext` (and the Nitmiluk `aiNote`) refreshed
  from the current seed.
  - A stop is matched by its name within that route.
  - A stop that is not in the seed is left alone, as is every other field and every other route.
  - The title (the user may have renamed it), order, days and `dateLabel` stay as they are.
- When something changed, the refreshed list is saved once, local first, so the cloud copy catches
  up through the normal push. When nothing changed, nothing is written.
- It is a pure tier-1 function over the models plus a call in `PreferencesStore`. No new
  persisted key (D3 stays two) and no version flag: the function is idempotent.

## Why

Operator decision (a) after the audit wave (`reports/otopilot-2026-10-01-report.md`, "Needs the
operator"). The demo routes are the ones shown to markers, and they still halve the longest drive
in the Territory.

## Acceptance

- [x] The Lane GATE passes.
- [x] Unit tests: an old Full NT copy gets the corrected strings.
  - A renamed copy keeps its title.
  - A route with another id, and a stop not in the seed, are untouched.
  - Running twice changes nothing the second time.
  - An explicitly empty list stays empty (V6), and a malformed key still falls back to the seed.
- [x] Unit test: load writes back only when the migration changed something (store with injected remote closures).
- [x] Real-data check (main loop): install over the emulator's existing stored routes. Full NT shows "1,191 km · about 12h to Alice Springs" and "302 km · 3h 10m to Uluru", the offline suggestion route is unchanged, and the stored key contains no fourth key.

## Out of scope

- Any other kind of saved-data migration. Changing seed facts (Task-66 did).
