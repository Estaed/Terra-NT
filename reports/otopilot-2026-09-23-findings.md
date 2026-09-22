# Findings ledger — 2026-09-23 goal run

One line per finding: `- [ ] <area>: <defect or gap> (source: audit|tour|eye|gate) → Task-NN`. Ticked when its task is DONE on main.

- [ ] Loading: seeded path flashes, V1 7000 ms lost in Task-33 integration (source: orchestrator) → Task-34
- [ ] Loading: retry wiring untested (source: gate) → Task-34
- [x] Account: catch-all hides a misconfigured build (source: gate) → Task-35
- [ ] Launch: a fresh install with nobody signed in lands on onboarding, not Login — phase 1's Q2 rule predates real accounts; plans are made with no uid, nothing syncs, Profile shows the placeholder email (source: tour, `tour-01-launch.png`) → Task-36
- [ ] Explore: the map fit ignores the status bar and the search field; the Darwin-area POI pins sit under the clock and under the search box (source: tour, `tour-04-explore.png`; the prototype has the same fit, ours adds the status bar) → Task-36
