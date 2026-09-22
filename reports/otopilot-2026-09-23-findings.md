# Findings ledger — 2026-09-23 goal run

One line per finding: `- [ ] <area>: <defect or gap> (source: audit|tour|eye|gate) → Task-NN`. Ticked when its task is DONE on main.

- [x] Loading: seeded path flashes, V1 7000 ms lost in Task-33 integration (source: orchestrator) → Task-34
- [x] Loading: retry wiring untested (source: gate) → Task-34
- [x] Account: catch-all hides a misconfigured build (source: gate) → Task-35
- [x] Launch: a fresh install with nobody signed in lands on onboarding, not Login — phase 1's Q2 rule predates real accounts; plans are made with no uid, nothing syncs, Profile shows the placeholder email (source: tour, `tour-01-launch.png`) → Task-36
- [x] Explore: the map fit ignores the status bar and the search field; the Darwin-area POI pins sit under the clock and under the search box (source: tour, `tour-04-explore.png`; the prototype has the same fit, ours adds the status bar) → Task-37
- [x] Result: stops 1–3 sit under the status bar, same fit defect (source: tour, `tour-05-06-pair.png`) → Task-37
- [ ] Plan AI: a user who skipped onboarding sees the seeded Full NT route as if generated ("7 days · 7 stops"); no empty state (source: tour) → Task-40
- [x] Profile: signed-out user sees the placeholder email and a Log Out row (source: tour) → closed by Task-36's routing
- [ ] Auth wrapper: `currentUser!` throws a TypeError past the seam when the user is gone (source: audit) → Task-38
- [ ] Plan parser: an empty-string stop name is kept, contract says drop (source: audit) → Task-38
- [ ] Goal gate: lib/data coverage below 97% (source: gate) → Task-38
- [x] Result: an edited leg says "Drive time unavailable" where the distance is known (source: audit, improvement) → Task-39
- [x] Explore: POI markers identical regardless of category; tag colours exist (source: audit, improvement) → Task-41
- [ ] Stop detail / Explore / Saved: no images anywhere (source: operator) → image wave after 02:01
