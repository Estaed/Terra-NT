# Task-06 — App shell: routing, tab shell, bottom nav

## Objective

Stand up navigation for all eleven destinations with placeholder screen bodies, so every
screen task after this one only fills in a body that is already routable. Establishes the
per-tab navigation stacks and the bottom nav.

## ⛔ Blocked on `docs/PRD.md` Q2

D3 persists the session, so a returning user does **not** land on Login — but the prototype
has no design for a launch state, and no route back to Login except Log Out. **Where a
returning user lands must be answered before the launch route is written.** The rest of
this task (tab shell, per-tab stacks, bottom nav, cold-start-signed-out path) proceeds.

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

- [ ] All eleven routes resolve and render without throwing.
- [ ] Navigation test: the bar is present on explore/result/saved/profile and **absent** on login, welcome, onboarding, loading, stopDetail, account and language.
- [ ] Navigation test: with `onboardingDone == false`, tapping Plan AI lands on Login; with `true`, it lands on Result. Both directions asserted.
- [ ] Navigation test: push Stop detail on the Plan AI stack, switch to Profile, switch back — **Stop detail is still on top**, proving per-tab stacks.
- [ ] Navigation test: push Account on the Profile stack, switch tabs and back — Account is still on top.
- [ ] The bottom nav renders exactly four tabs with the labels `Explore`, `Plan AI`, `Saved Routes`, `Profile`.
- [ ] A test asserts the active tab's icon and label resolve to `AppColors.ink` and the inactive ones to `AppColors.inkTertiary`.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/app/` returns nothing.
- [ ] No layout exception at 360px width with the longest label (`Saved Routes`) — test pumps at that width and asserts no `FlutterError` was recorded.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/app/` exits 0.
