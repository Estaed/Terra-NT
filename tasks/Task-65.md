# Task-65: Saved routes can be undone, renamed and put in order
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator approved the 2026-10-01 audit wave and named Codex; list operations are pure and fully testable.

**Lane**
- OWNS: `terra_nt/lib/features/saved/saved_routes_screen.dart`, `terra_nt/lib/data/repositories/notifiers.dart`, `terra_nt/lib/core/util/saved_routes_ops.dart`, `terra_nt/test/features/saved/saved_routes_screen_test.dart`, `terra_nt/test/core/util/saved_routes_order_test.dart`, `terra_nt/test/data/repositories/saved_routes_notifier_test.dart` (new)
- MUST NOT TOUCH: `terra_nt/lib/data/repositories/preferences_store.dart` (Task-64), `terra_nt/lib/data/repositories/firestore_saved_routes.dart` (Task-64), `terra_nt/test/data/repositories/repositories_test.dart` (Task-64), `terra_nt/lib/features/itinerary/` (Task-64), `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: none

## Goal

**A saved route can be deleted without fear, named by the user, and placed where the user wants
it in the list.**

- **Undo after delete.** Swipe-to-delete shows "Route deleted" with Undo for a few seconds. Undo
  puts the complete route back at its original position.
- **Rename.** Each saved route can be renamed from a small per-route menu on its card. The title
  is saved locally and syncs like any other change.
- **Order.** The same menu offers Move up / Move down. The order persists; Firestore already
  stores each route's position. No new horizontal gesture, since Saved already uses swipe-to-delete.
- The explicit-empty-list rule (V6) and the `generated-trip` upsert keep working. A renamed
  generated route keeps its id.

## Why

`reports/research/2026-10-01-qol-audit.md` rows 5, 13 and 16. Delete is one swipe away and
final today, and routes cannot be told apart or arranged.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Unit tests: restoring a deleted route at its index; rename keeps id, stops and days; move up/down at both ends; the persisted order survives a reload through the store with injected remote closures.
- [ ] Widget tests: delete shows Undo, and Undo restores the card at its position. Rename updates the card. Move up/down reorders. Swipe-to-delete, open, empty state and the explicit empty list are unchanged.
- [ ] At 360 px and 2x text, the card menu and the Undo message do not overflow (test).
- [ ] Device tour (Blueprint Verification 6, gesture): the main loop swipes to delete, undoes, renames and reorders on `emulator-5554`. Logcat has no Flutter exception.
- [ ] (eye) The card menu sits quietly on the card and does not compete with the cover.

## Out of scope

- Duplicating or keeping a copy of a generated route (needs an identity decision).
- Saving Result edits back to a route.
