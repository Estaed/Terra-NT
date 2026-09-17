# Task-06 — App shell: routing, tab shell, bottom nav

Status: DONE

> **Execution:** agent `codex` · effort `high`
> *Why:* Rerouted 2026-09-07. The architecture call this task reserved is already
> made: `docs/ADVICE.md` prescribes `IndexedStack` + one `Navigator` per tab, with
> `go_router` held in reserve only if that loses tab state and `auto_route` forbidden
> outright. A delegate does not choose a router — it builds the prescribed one and
> **stops and reports** if the state tests cannot pass, because adding a package
> amends Blueprint's Stack table and is the operator's call. See `docs/UNATTENDED.md`.

**Lane**
- OWNS: `terra_nt/lib/app/`, `terra_nt/test/app/`
- MUST NOT TOUCH: `terra_nt/lib/features/` (the screen tasks own their own bodies), `terra_nt/lib/data/` (Task-03, Task-05), `terra_nt/lib/core/` (Task-01, Task-04), `terra_nt/lib/shared/` (Task-02, Task-07), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/app/`
- DEPENDS ON: Task-05

## Objective

Stand up navigation for all eleven destinations with placeholder screen bodies, so every
screen task after this one only fills in a body that is already routable. Establishes the
per-tab navigation stacks and the bottom nav.

## Answered — `docs/PRD.md` Q2 (2026-09-05)

The launch route reads the `session.onboardingDone` flag D3 already persists: false goes
to onboarding, **true goes to Explore**. No second persisted key, no new screen — Explore
is where the prototype's own `onSkipOnboarding` lands (L1072). Last-used tab and Result
were both rejected; the reasons are under Q2.

## Execution Guide

**Files:** `terra_nt/lib/app/`.

**Routing:** declarative router with a stateful tab shell so each tab keeps its own stack
across switches (`docs/PRD.md` §3.11). Destinations:

| Route | Nav bar | Notes |
|---|---|---|
| login, welcome, onboarding, loading | hidden | linear pre-app flow |
| explore, result, saved, profile | **visible** | the four tabs |
| stopDetail | hidden | pushed onto the **Plan AI** stack |
| account, language | hidden | pushed onto the **Profile** stack |

**Bottom nav** (`lib/app/widgets/bottom_nav.dart`): 64px tall, `surface1`, 1px hairline top
border, four equal-width tabs, 20px icon over an 11px caption with a 4px gap. Active tab
full `ink`, the other three `inkTertiary`. Labels and icons exactly:
Explore/`Compass`, Plan AI/`Sparkles`, Saved Routes/`Bookmark`, Profile/`User`.

**Two behaviours that are logic, not chrome:**

1. **The Plan AI tab is conditional** (L887): it opens Result when `onboardingDone`, and
   Login when not. This is the one tab that can leave the shell.
2. **Stop detail keeps Plan AI conceptually active while hiding the bar**, because it sits
   on top of that tab's stack. Account and Language do the same for Profile.

**Placeholder bodies:** each screen route renders a bare `Scaffold` naming itself. Later
tasks replace the body only — no task after this one should need to touch the router,
except to remove a placeholder.

**Do not** implement a swipe-between-tabs gesture; tabs change by tap only.

## Acceptance Criteria (DoD)

- [x] All eleven routes resolve and render without throwing.
- [x] Navigation test: the bar is present on explore/result/saved/profile and **absent** on login, welcome, onboarding, loading, stopDetail, account and language.
- [x] Navigation test: with `onboardingDone == false`, tapping Plan AI lands on Login; with `true`, it lands on Result. Both directions asserted.
- [x] Navigation test: push Stop detail on the Plan AI stack, switch to Profile, switch back — **Stop detail is still on top**, proving per-tab stacks.
- [x] Navigation test: push Account on the Profile stack, switch tabs and back — Account is still on top.
- [x] The bottom nav renders exactly four tabs with the labels `Explore`, `Plan AI`, `Saved Routes`, `Profile`.
- [x] A test asserts the active tab's icon and label resolve to `AppColors.ink` and the inactive ones to `AppColors.inkTertiary`.
- [x] `grep -rnE "0x[0-9a-fA-F]{8}" lib/app/` returns nothing.
- [x] No layout exception at 360px width with the longest label (`Saved Routes`) — test pumps at that width and asserts no `FlutterError` was recorded.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/app/` exits 0.
