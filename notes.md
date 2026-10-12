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

## Repo

One public repo, `Estaed/Terra-NT`, with the whole history, tasks, reports and agent files:
the course staff read it as it is. From 2026-10-10 to 2026-10-13 it was split into a private
`Terra-NT-dev` and a history-free public copy; on 2026-10-13 the public commits were replayed
on top of the dev history and the split ended (`Terra-NT-dev` is archived on GitHub).
