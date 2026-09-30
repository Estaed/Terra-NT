# Task-66: Road facts are right and every control speaks
> **Execution:** agent `codex` · effort `high`
> *Why:* Operator approved the 2026-10-01 audit wave and named Codex; the figures are given below and the accessibility rules are testable.

**Lane**
- OWNS: `terra_nt/lib/data/seed/seed_data.dart`, `terra_nt/lib/core/util/itinerary_ops.dart`, `terra_nt/lib/features/itinerary/widgets/result_stop_list.dart`, `terra_nt/lib/features/itinerary/stop_detail/stop_detail_screen.dart`, `terra_nt/lib/features/itinerary/result_screen.dart`, `terra_nt/lib/features/explore/explore_screen.dart`, `terra_nt/lib/shared/map/map_markers.dart`, `terra_nt/lib/app/widgets/bottom_nav.dart`, `terra_nt/test/data/models_seed_test.dart`, `terra_nt/test/core/util/util_test.dart`, `terra_nt/test/features/itinerary/widgets/result_stop_list_test.dart`, `terra_nt/test/features/itinerary/stop_detail/stop_detail_screen_test.dart`, `terra_nt/test/features/itinerary/result_screen_test.dart`, `terra_nt/test/features/explore/explore_screen_test.dart`, `terra_nt/test/app/tab_shell_test.dart`, `terra_nt/test/integration/itinerary_profile_test.dart`
- MUST NOT TOUCH: `terra_nt/lib/features/onboarding/` (Task-67), `terra_nt/lib/features/loading/` (Task-67), `terra_nt/lib/data/seed/onboarding_options.dart` (Task-67), `terra_nt/pubspec.yaml`, `docs/`, `tasks/`, `CLAUDE.md`, `AGENTS.md`
- GATE: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1` (from repository root)
- DEPENDS ON: Task-64

## Goal

**What the app says about the road is true, and every control works for a screen reader and
large text.**

- **Drive figures.** Correct the seeded `driveNext` strings against Tourism NT's published
  driving distances ([key facts](https://internationaltrade.northernterritory.com/en/trade-training/key-facts),
  page updated 2025-01-08):

  | Leg | Official figure |
  |---|---|
  | Darwin – Kakadu (Jabiru) | 254 km, 2h 40m |
  | Kakadu (Jabiru) – Katherine | 305 km, 3h 10m |
  | Katherine – Alice Springs | 1,191 km (276 + 407 + 508), about 12h |
  | Alice Springs – Kings Canyon | 473 km, 4h 50m |
  | Kings Canyon – Uluru | 302 km, 3h 10m |

  Apply these wherever the seed has the leg; it is currently 250, 670, 320 and 300 km. Keep the
  existing string format. A leg not in this table stays as it is. The Nitmiluk → Alice Springs
  `aiNote` should not call a 12-hour drive "the next day" without saying it is long. Adjust its
  sentence to match.
- **Next leg ignores skipped stops.** The drive line under a stop and Stop detail both name the
  next *active* stop, the same sequence Export already uses. Stop detail shows that next leg.
  Where the distance is computed rather than seeded, keep saying so as today.
- **Check the road.** Stop detail offers "Check road conditions", opening the NT Government's
  road report ([nt.gov.au](https://nt.gov.au/driving/safety/check-road-conditions)) with the
  existing `url_launcher`. It says a connection is needed.
- **Every control speaks.** Stop detail Back, the Explore card's Close, delete buttons and every
  place marker (with the place name) get accessible labels.
  - Result's sheet handle gets a 48 px target and Expand/Collapse semantic actions that work
    without dragging.
- **Large text grows instead of shrinking.** The bottom navigation and Stop detail's action labels
  stop using `FittedBox(scaleDown)`. At 2x text they wrap or grow and stay readable, with 48 px targets.
- **Stop detail practical icons.** A Lucide `clock` beside Hours and `ticket` beside the entry
  fee, keeping the current left-aligned values (`reports/research/2026-10-01-visual-audit.md` row 7).
- **Explore empty search.** One muted Lucide `search_x` above "no matches" (visual audit row 8).

## Why

`reports/research/2026-10-01-qol-audit.md` rows 1, 7, 8, 9 and 10, and visual audit rows 7–8.
A trip planner that halves the longest drive in the Territory is dangerous. Controls without
names are unusable with TalkBack.

## Acceptance

- [ ] The Lane GATE passes.
- [ ] Unit tests: each corrected leg string matches the table. The next-leg function skips skipped stops and agrees with the export sequence.
- [ ] Widget tests: the semantics labels exist (Back, Close, delete, each marker's place name). The sheet handle has a 48 px target and Expand/Collapse actions. "Check road conditions" launches the NT URL. The Hours and fee icons render. The empty search shows `search_x`.
- [ ] At 360 px and 2x text: bottom nav, Stop detail actions and Result rows show no overflow and no scale-down (test).
- [ ] Device tour (Blueprint Verification 6, layout and gestures): TalkBack reads Back, a marker and the sheet handle on `emulator-5554`, and 2x font size is set in system settings. Logcat has no Flutter exception.
- [ ] (eye) Stop detail with the new next-leg line, road link and icons still reads calmly (compare `reports/screens/2026-09-30-wave4/t59-detail.png`).

## Out of scope

- Live road status feeds, fuel and water data, location-based distance remaining.
- Legs not in the table, and the Blueprint wording about computed distances (reported separately).
