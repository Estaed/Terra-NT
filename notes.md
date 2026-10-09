# Terra NT working notes

## Current scope — 30 September 2026

Blueprint D21: the running app is the reference, and `docs/PRD.md` is history. The
2026-09-30 run (Task-53…62, `reports/otopilot-2026-09-30-plan.md`) builds the motion,
illustration, logic and quality-of-life items of `reports/reviews/2026-09-30/report.md`.
The code is written by Codex.

## Previously tried

- Tasks 48–52 added entrances, press feedback, a rendered car, road progress, the
  Loading treatment and tab/question transitions. The 2026-09-30 reviews still found the
  app static where things change and short of artwork. Do not answer that with more
  entrance motion.
- Auto-advance on single-choice answers was built and removed on 2026-09-11: the screen
  moved under a user still reading the options.

## After v1

- Merge the two accommodation questions (report Q8), once the planning server's prompt
  shows whether both answers are used.
- Explore marker clustering and a tile style with readable labels (a CARTO decision).
- A middle-height route panel that shows more of the trip summary (report, Codex row).
- Fuel stops: tell the traveller where to fill up before long empty stretches. Waits on fuel
  station data from the teammates (2026-10-10); nothing to build without it.

## Public repo

Since 2026-10-10 this repo is `Estaed/Terra-NT-dev` (private). `Estaed/Terra-NT` is a clean
public copy (local clone `D:/Projects/terra-nt-public`): app, plan server, design, PRD,
contract and iOS setup, no history; MIT licence. A change reaches it by copying the files
over and committing there; `tasks/`, `reports/`, agent files and `start-demo.bat` stay here.
