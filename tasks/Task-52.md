# Task-52 — Visible motion and endpoint pickers
**Status: DONE** — verified by the main loop on 2026-09-30: analyze clean, 582 tests, release APK built and installed, Samsung SM-S921B tour.

> **Execution:** main loop · effort `high`
> *Why:* An attended polish fix with a product decision delegated by the operator on 2026-09-30; the existing architecture and tokens stay.

**Lane**
- OWNS: onboarding screen and step bodies, onboarding option data, tab shell, their tests, `docs/PRD.md`, `docs/PHASE-3-CONTRACT.md`, `docs/TASKS_INDEX.md`, this task's report.
- MUST NOT TOUCH: auth, map rendering, RAG, iOS, packages, persisted data, server implementation, Blueprint.
- GATE: from `terra_nt/`, `flutter analyze` and `flutter test`; Android device tour of tabs, questions, location menus and Back.
- DEPENDS ON: Task-50.

## Goal

Tab changes visibly ease in even after the hidden screens' initial entrances finished. Question cards fade into place and resize smoothly; selected answers change without moving the text. Question 15 selects two endpoints from a short list instead of requiring typing.

## Decision

Keep both endpoints: removing them would make the planner guess the route's start and finish. An extra-comments field is a different feature and stays out of this change. Offer Darwin, Jabiru, Katherine, Alice Springs and Uluru, already represented in the project's seed itinerary. Send the same location strings in the existing `startLocation` and `endLocation` fields. Preserve an existing non-list answer if encountered; allow a round trip with equal endpoints. No default silently answers the question.

## Acceptance

- A tab activation animates after its child was already mounted; nested navigation survives switching tabs. Re-tapping the active tab does not restart the transition.
- A changed question fades/slides in and its card height eases; selecting an answer neither advances nor replays the card entrance.
- Selected rows keep a fixed checkmark slot and animate their border/fill. New motion respects reduced-motion settings and disposes cleanly.
- Both location menus set only their corresponding answer, retain choices when revisited, permit equal endpoints and open without a keyboard. The existing request contract is unchanged.
- Analyze and the full widget/unit suite pass. The changed UI is checked on Android, including Back from an open location menu and text scaling.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 582 tests passed. Regression coverage measures visible tab activation without replacing the Navigator, unchanged navigation stacks, a card's intermediate opacity/height, stable option text, endpoint preservation/round trips/custom old answers, no keyboard, menu Back and 360 px with doubled text. Disposal and reduced-motion behavior are also covered.
- `flutter build apk --release --no-pub --dart-define-from-file=.env`: succeeded. Installed with `adb install -r` on Samsung SM-S921B, Android 16; existing sign-in and saved routes remained.
- Phone tour through all 15 questions: selection remains manual, transitions complete, the car reverses on Back, and both menus open without a keyboard. Android Back closes a menu without leaving question 15. Darwin/Katherine choices survive Back to question 14 and Next. Generate stays disabled until both endpoints are selected. The tour did not generate/overwrite a route.
- Phone evidence: [`endpoints.png`](../reports/screens/2026-09-30-task52/endpoints.png). A short native screen recording of tab activation was inspected frame by frame; the transition eases in without a layout jump. These captures are advisory, not golden tests.
- A logcat read filtered to the new app process after the tour found no Flutter errors, fatal exceptions, overflows or unbounded-constraint errors.
- Known build notice: Firebase plugins still emit the existing future KGP migration warning; the release build succeeds. Dependencies were not changed.
- Decisions and deviations: D19, V31 and V32 in `docs/PRD.md`; the server still accepts the same location strings. RAG, iOS and Blueprint were not changed.
