# Task-12 — Loading screen and auto-save on generate

> **Yürütme:** ajan `codex` · efor `high` · plan modu hayır
> *Gerekçe:* Timer, five messages and auto-save on generate; deviation V1 states the timing exactly.

## Objective

Build the non-interruptible transition between Onboarding and Result, and the auto-save
that happens during it. Small screen, but it carries **Deviation V1** and the upsert that
Saved Routes depends on.

## Execution Guide

**Files:** `terra_nt/lib/features/loading/`.

**Layout** (`Terra NT.dc.html` L378–384): centred 64px `primary` circle, 28px gap, status
line at 15px `inkSubtle` centred with 40px side padding and a fixed 22px min-height so
rotating text does not shift the layout.

**Pulse:** scale 1 → 1.4 and opacity 0.9 → 0.3 on a **1.6 s** loop, `ease-in-out`,
symmetric (out and back).

**Message rotation:** every **1400 ms**, in order, starting at index 0, through Task-03's
`loadingMessages`.

### Deviation V1 — read before implementing

The prototype clears its interval at **5600 ms**, one tick before the fifth message
(`"Routing..."`) would show. That is a bug: five messages are seeded and only four ever
render. **This build runs 7000 ms** (5 × 1400) so each message gets one full turn.

Do not "fix" this back to 5600 during implementation.

**On completion — all three, in this order:**

1. Set `onboardingDone`.
2. **Upsert** the generated route into Saved Routes under the stable id
   `generated-trip` — title from `Itinerary.title`, meta from Task-04's `derivedMeta`
   (stop count and `days`), date label "Generated just now". Both title and count come from
   the returned itinerary, not from literals, so a phase-3 model with a different trip name
   and a different number of stops needs no change here. Re-running onboarding **updates
   that one entry rather than adding a second** (Task-04's `upsert`, already tested).
3. Navigate to Result.

**Non-interruptible:** no back button, no cancel, no bottom nav. But leaving by any means —
a system back gesture, a route pop — **must cancel both timers**, so the navigation and the
upsert do not fire afterwards. This is Part 2 Verification Rule 4 and the most likely defect
in this screen.

**No real generation.** The delay is hard-coded; there is no future to await
(`docs/PRD.md` §5). The itinerary comes from `ItineraryRepository`, which in phase 1
returns the seeded stops.

## Acceptance Criteria (DoD)

- [ ] Widget test: the status line shows `loadingMessages[0]` at t=0, `[1]` at 1400 ms, `[2]` at 2800 ms, `[3]` at 4200 ms, and **`[4]` — `"Routing..."` — at 5600 ms**. All five asserted.
- [ ] Widget test: navigation to Result fires at **7000 ms**, not before — asserted still-on-Loading at 6999 ms.
- [ ] Widget test: after the transition, `onboardingDone` is true.
- [ ] Widget test: after the transition, Saved Routes contains an entry with id `generated-trip` **at index 0**, whose title equals the returned `Itinerary.title` and whose date label is "Generated just now".
- [ ] Widget test: with a faked repository returning a 4-stop itinerary under a different title, the saved entry reflects **both** — proving neither is hardcoded.
- [ ] Widget test: completing onboarding **twice** leaves exactly one `generated-trip` entry, updated in place — the list length is unchanged on the second run.
- [ ] Widget test: the entry's meta comes from `derivedMeta`, reflecting the `days` answer — asserted with a non-default day count.
- [ ] Disposal test: popping the route at 3000 ms fires **no** navigation and creates **no** saved route afterwards, and leaves no active timer.
- [ ] The screen renders no bottom nav, no back button and no cancel affordance.
- [ ] `grep -rn "5600" lib/features/loading/` returns nothing.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/loading/` returns nothing.
- [ ] No layout exception at 360px width with the longest of the five messages on screen — the test pumps at that width and asserts no `FlutterError` was recorded.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/loading/` exits 0.
