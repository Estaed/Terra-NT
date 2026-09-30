# otopilot plan — 2026-09-30, motion, illustration and truth

Approved by the operator in chat on 2026-09-30 at about 14:50 ACST, before leaving:

- Image bees may run with `danger-full-access`; code bees may not.
- "Planı yaz ve başlat" (write the plan and start).
- Scope: all waves of `reports/reviews/2026-09-30/report.md`.

The operator is away, so no further approval is possible. Everything below runs as
written.

## Direction and seats

| | |
|---|---|
| Direction | Claude main loop (orchestrator) → **Codex bees** (`--orchestrator claude --delegate codex`) |
| Fallback | **None.** The operator's instruction is to wait out the Codex 5-hour wall, not to switch pools |
| Orchestrator seat | This interactive Claude Code session (`claude-opus-5-5`), left open |
| Code bees | `gpt-6.1-sol`, effort `high`, `--sandbox workspace-write`, one git worktree each (probe OK on codex-cli 0.159.2, 2026-09-30) |
| Image bees | `gpt-6-luna` / `high` driving `image_gen` (`gpt-image-2`), `danger-full-access` (operator OK) |
| Eye | Main loop only, on `emulator-5554`, holding the device lock (`cihaz_kilidi.py`). The physical phone is not used |

## Shape

- **SOURCE:** `tasks`: Task-53 … Task-62 (10 tasks, 5 waves).
- **UNTIL:** `done`. At most two 5-hour resets per the skill's ceiling. If more resets are
  needed, the run checkpoints and closes with `Run closed: quota`, and the report lists
  every remaining wave.
- **BASE_SHA:** the commit that adds this plan (recorded in the report after the second
  preflight).
- **Per-bee timebox:** 120 min of wall clock. Past that the bee is killed and the attempt fails.
- **Gate (every task):** `powershell -NoProfile -ExecutionPolicy Bypass -File tools/flutter_gate.ps1`
  from the repository root: `flutter analyze`, `flutter test`, release APK build. Each
  lane runs `flutter pub get` in `terra_nt/` first.
- **Lanes** live outside the repo at `%TEMP%\terra-lanes\t<NN>` (short paths for the
  Flutter build). Briefs and logs go to `%TEMP%\terra-lanes\`.

## Waves

| Task | Wave | Agent | Model / effort | OWNS (summary) | Depends on | Est. attempts |
|---|---:|---|---|---|---|---:|
| 53 Route draws itself, camera follows sheet | 1 | codex | gpt-6.1-sol / high | result_screen, terra_map, dashed polyline, route_reveal, motion/metrics tokens | — | 1–2 |
| 54 Explore comes alive | 1 | codex | gpt-6.1-sol / high | explore_screen, map_markers, poi_filter | — | 1–2 |
| 55 Back goes where the user came from | 2 | codex | gpt-6.1-sol / high | tab_shell, routes, screen_routes | — | 1 |
| 56 Route facts are true | 2 | codex | gpt-6.1-sol / high | saved_route/itinerary models, stop_json, seed, notifiers, prefs, loading save, result header, map fit | 53 | 1–2 |
| — Scene artwork (orchestrator step) | before 3 | image bees | gpt-6-luna / high → gpt-image-2 | `terra_nt/assets/images/scenes/` + pubspec asset line | — | 1 per image |
| 57 Welcome and empty Plan AI scene | 3 | codex | gpt-6.1-sol / high | welcome_screen, result_empty_state, journey_scene, tab_shell, result_screen | 53, 55, 56 | 1–2 |
| 58 Onboarding shows the trip | 3 | codex | gpt-6.1-sol / high | onboarding_screen, progress_drive, onboarding_steps, onboarding_options | — | 1–2 |
| 59 Stop list motion, Hero, hours | 4 | codex | gpt-6.1-sol / high | result_stop_list, plan_entry_list, stop_detail | — | 1–2 |
| 60 Loading truth, offline fallback | 4 | codex | gpt-6.1-sol / high | loading_screen, route_car_backdrop, plan_failure_copy, notifiers, itinerary_repository, seed | 56 | 1–2 |
| 61 Onboarding without friction | 5 | codex | gpt-6.1-sol / high | onboarding files, onboarding_rules, plan_request, trip_summary, answers model | 56, 58 | 1–2 |
| 62 Honest settings, labels, Saved covers | 5 | codex | gpt-6.1-sol / high | profile, notifiers, bottom_nav, saved_routes_screen, place_images | 56, 57, 60 | 1 |

OWNS sets are pairwise disjoint inside each wave. Overlaps across waves are covered by
the dependencies (preflight `owns_disjoint` OK).

**Scene artwork step (before wave 3).** Five images, one per image bee:

- `start_trip`: a painted NT road trip with the white 4x4, road into the landscape.
- `top_end`: waterfall, tropical greenery.
- `red_centre`: red rock, dry country.
- `full_nt`: a road running from tropics to desert.
- `no_signal`: a quiet outback road at dusk, the car pulled over, no phone signal implied without text.

Style is anchored on the existing destination paintings in
`terra_nt/assets/images/places/`. No text and no logos. Landscape `1536x1024`, then
converted to JPEG next to the place pictures at a comparable file size. The orchestrator
looks at every image before committing it, re-runs any that miss, and adds
`assets/images/scenes/` to `pubspec.yaml` in the same commit. If image generation fails
twice for an image, Task-57, 58, 60 and 62 are briefed to use the closest existing place
picture instead, and the report says so.

## Checks after each integration

- Per `references/check.md`: the exact GATE in the lane, cherry-pick, the GATE on main,
  then DONE with `, eye check pending: N`.
- **Screen check:** a main-loop tour on `emulator-5554` (release build with `.env`),
  with captures in `reports/screens/2026-09-30-wave<n>/`. It reports gaps; the operator
  closes every `(eye)` box.
- **Device tour** for Task-55, 59 and 61, per Blueprint Verification 6: the journeys
  named in each task, with logcat checked for Flutter exceptions.

## Quota

At plan time (14:55 ACST):

| Pool | 5-hour | Weekly | Other |
|---|---|---|---|
| Codex | 81% (resets 17:01 ACST) | 53% | banked resets exist; **not used** without the operator |
| Claude | 3% | 43% | — |

Measure with `onkontrol.py --quota-only --orchestrator claude --delegate codex` before
every wave and after every bee while `NARROW`. At a 5-hour wall: spawn nothing new,
integrate what is running, and wake at reset + 2 min. A weekly wall closes the run.

There is no measured cost for a `gpt-6.1-sol`/`high` Flutter feature bee on this Plus
plan. Wave 1 records it, and later waves are estimated from that number in the report.

## Excluded

- **Q8** (merging the two accommodation questions): needs the planning server's prompt
  checked with its owner. Goes to `notes.md` → *After v1*.
- **The Task-53/54 drafts in `.claude/worktrees/codex-visual-prep`** (uncommitted, written
  for `ultracode`) are superseded by these task files and are not run. That worktree is
  left untouched.
