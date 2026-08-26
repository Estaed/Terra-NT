# Reference screenshots — advisory only

Ten captures of the prototype, taken by the product owner on 2026-08-26 so that a build
can be eyeballed against the intended design. They exist because the prototype cannot be
run in this repo (`docs/PRD.md` §2, gap 2).

**These are not the deleted set.** The nine PNGs that used to sit at `design/screenshots/`
were removed deliberately because they were flawed, and that decision stands — see
`docs/PRD.md` §9 Q1. This is a separate, newer capture at a different path. Do not conflate
the two, and do not restore the old ones.

## What these are for

Looking. A human — or Claude, reading the image — compares a built screen against the
matching file and says *same / better / worse*. That conversation is the whole purpose.

## What these are not

**Not a specification, and never an acceptance criterion.** No `Task-XX.md` may add a
checkbox that cites a file in this directory. Every criterion stays a command to run or a
value to assert in code (`docs/TASKS_INDEX.md` → Q1).

Two reasons, both real:

1. **The prototype has known defects.** The product owner has already named some: the
   "Continue with Google" button carries no Google mark, and the car on the map is an
   outdated revision. Treating these images as ground truth would mean faithfully
   reproducing bugs. Where the build *should* differ, `docs/PRD.md` §7 records it as a
   numbered deviation — that list, not this directory, is what a task follows.
2. **Coverage is partial by design.** These are the main screens in their default states.
   Route deletion, dialogs and overlays, the remaining onboarding questions, and every
   error or edge state are absent. A screen not shown here is not a screen without a spec —
   `docs/PRD.md` §3 is the spec.

## Files

Numbered to match `docs/PRD.md` §3.

| File | Screen |
|---|---|
| `01-login.png` | Login |
| `02-welcome.png` | Welcome |
| `03-onboarding.png` | Onboarding, question 1 of 15 |
| `04-loading.png` | Loading |
| `05-explore.png` | Explore, map at rest |
| `06-plan_ai.png` | Result / Plan AI, sheet at mid detent |
| `07-stop_detail.png` | Stop detail |
| `08-saved_empty.png` | Saved Routes, empty state |
| `09-saved_populated.png` | Saved Routes, two rows |
| `10-profile.png` | Profile |
