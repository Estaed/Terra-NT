# Terra NT

🚧 **Work in progress.** Not yet functional.

A Flutter road-trip planning app for the Northern Territory, Australia — log in,
answer a short onboarding, get an AI-generated multi-stop itinerary on a map,
edit and reorder stops, explore points of interest, and manage saved routes.

Built natively in Flutter (no WebView). Design spec and reference prototype
live in [`design/`](design/).

---

# Building this — the PIV loop

Work is sliced into 14 tickets in [`docs/tickets/terra-nt-route-planner.md`](docs/tickets/terra-nt-route-planner.md).
Each ticket goes through the same five-command loop. **One ticket per loop, one branch per ticket** — don't start
T-02 while T-01 is half-done.

## Repo layout

The Flutter project is **not** the repo root — it lives in `terra_nt/` and holds only the app:

```
Terra NT/            ← repo root: this README, CLAUDE.md, .claude/, design/, docs/
└── terra_nt/        ← Flutter project — lib/, test/, pubspec.yaml, android/, ios/
```

`design/`, `docs/`, `.claude/` and this README stay at the root and never move under `terra_nt/`. Run every
Flutter and Dart command from `terra_nt/`; Claude Code still picks up the root `CLAUDE.md` from there, since it
reads parent directories. **T-00 creates all of this** — until it has run there is no `pubspec.yaml` and no `lib/`.

## One-time setup

```bash
git status                      # already a repo — main, first commit bdeb783
flutter --version               # expect Flutter 3.47.1 · Dart 3.13.1 (per design/CLAUDE.md)
```

Then run **T-00** before anything else. It is the shortest loop in the project and every other ticket is blocked
on it.

## The loop

| # | Command | What it produces |
|---|---|---|
| 1 | `/piv-plan-implementation <ticket>` | Asks you 3–6 questions, **stops**, then writes `.claude/plans/<name>.md` |
| 2 | *(you read the plan)* | Your gate — cheapest place to catch a wrong turn |
| 3 | `/piv-implement .claude/plans/<name>.md` | Cuts a branch, writes the code + tests, runs validation |
| 4 | `/piv-validate` | Full suite: `dart analyze`, tests, goldens |
| 5 | `/piv-review-changes` | Review report at `.claude/code-reviews/<name>.md` |
| 6 | `/piv-commit` | One atomic, conventionally-tagged commit |

Steps 4–6 are quick. The two that decide whether the ticket succeeds are **1** and **2**.

---

## Worked example — T-01 (tokens, core widgets, test harness)

**Run T-00 first.** It is the same six steps, just shorter — `flutter create` at `terra_nt/`, the dependency
pins, the analyzer config, the fonts decision, and the `.gitignore` fix. Its two gate questions are the org /
bundle id and `google_fonts` vs bundled font files; both are cheap to answer now and expensive to change after
the first golden is checked in. Everything below assumes T-00 has landed.

### Step 1 — Plan

Paste this:

```
/piv-plan-implementation T-01 from docs/tickets/terra-nt-route-planner.md — design tokens,
core widgets, test harness. Treat design/CLAUDE.md (Architecture, Stack / conventions, Design
tokens, Definition of done) and design/PRD.md → Design tokens as already decided — inherit
them, don't reopen them. The project, deps and analyzer config already exist from T-00; don't
touch pubspec.yaml.
```

Why it's shaped that way: the ticket is a local markdown file, not a Jira key, so it's a *free-form* input —
you have to point at the file **and** the section. The second sentence matters: without it the planner may
re-litigate settled calls (Riverpod vs Provider, which map package), burning the loop on decisions
`design/CLAUDE.md` already made.

**What happens next: it stops and asks you 3–6 numbered questions.** This is a deliberate gate, not a stall.
For T-01 expect roughly these — with a ready answer for each:

> **1. Tag colors.** `PRD.md` calls the six tag hues "provisional". Exact hexes?
> **→** *"Use `design/design-system/tokens/colors.css` — all six are there. They're still provisional
> (derived from the accent hue family, not sampled from the real product), so define them as named tokens and
> note in the plan that a correction should be a one-line change."*
>
> **2. The display type roles top out at 80px, but the app's largest is 44px. Which sizes?**
> **→** *"The app's. Inherit the family, weight and negative-tracking ramp from the type roles; the 80/56/40px
> sizes belong to the marketing site, not this app — `design/design-system/README.md` says so."*
>
> **3. How many core widgets in this first pass?**
> **→** *"Exactly the seven in the ticket. Nothing speculative — `design/CLAUDE.md` rule 2."*
>
> **4. Which environment pins the goldens?**
> **→** *"This machine (Windows). Record it in the test README; goldens are font-rendering-sensitive
> and must be regenerated, not fought, if we ever move to CI."*

Answer them in one message, numbered. If you don't care about one, say "your call" — it'll pick the recommended
default and record it as an assumption rather than guessing silently.

Then it writes `.claude/plans/terra-nt-scaffold-tokens.md` (or similar).

### Step 2 — Read the plan before implementing

Don't skip this. Open the file and check three things:

- **CONTEXT REFERENCES** — does it point at `design/PRD.md` → Design tokens, `design/design-system/tokens/`,
  and the screenshots?
- **STEP-BY-STEP TASKS** — is every token from the PRD represented (4 surfaces, 4 inks, 3 hairlines, 6 tags,
  3 type roles, the 8-value spacing scale, 5 radii, 4 motion durations, the overlay shadow and edge highlight)?
  Missing tokens here become hardcoded hexes in every later ticket.
- **OPEN QUESTIONS / ASSUMPTIONS** — anything you'd answer differently?

If something's off, say so in plain language — `"the plan skips the motion tokens, add them"` — and it amends
the file. Cheap now, expensive after 900 lines exist.

### Step 3 — Implement

```
/piv-implement .claude/plans/terra-nt-scaffold-tokens.md
```

It cuts `feature/terra-nt-scaffold-tokens`, works task by task, and runs the plan's own validation commands as
it goes. Let it run. Don't interrupt to add scope — new ideas go in the ticket file for a later loop.

### Steps 4–6 — Prove it, review it, commit it

```
/piv-validate
/piv-review-changes
/piv-commit
```

**T-01 is done when:** `dart analyze` is clean, one core widget has a checked-in golden that re-runs green, and
no hex or magic number exists outside `terra_nt/lib/ui/core/theme/`. That last one is worth grepping for
yourself — it's the invariant every later ticket depends on.

### Then

T-02 is independent of T-01, so it can run in a second worktree in parallel, or right after. Same six steps,
same shape of prompt.

---

## Model & reasoning per phase

The split that matters: **planning is where reasoning pays, execution is where it mostly doesn't** — by then
the plan file *is* the reasoning, and the job is to follow it with tests as the gate.

| Phase | Model | Reasoning | Why |
|---|---|---|---|
| `/piv-plan-implementation` | **Opus** | **High** | Catching a bad decision here costs one message; catching it in review costs the ticket. |
| Reading/amending the plan | Opus | High | Same conversation, same context — no reason to downshift. |
| `/piv-implement` | **Sonnet** | **Medium / default** | Mechanical: follow tasks, match goldens. `dart analyze` + tests are an objective gate that doesn't need extra thinking to pass. |
| `/piv-validate`, `/piv-commit` | Sonnet | **Low / default** | Running commands and summarising output. |
| `/piv-review-changes` | Sonnet | **High** | Adversarial reading benefits from depth — bump to Opus for T-07/T-08/T-09. |

### Per-ticket

- **Sonnet end-to-end is fine:** T-00, T-01, T-02, T-11, T-12, T-13 — well-specified, low cross-cutting state.
  T-00 is mostly `flutter create` and config; the two decisions in it are yours to make, not the model's.
- **Plan with Opus, implement with Sonnet:** T-04 (arc-length sampling), T-06 (15 gated steps), T-07 (the state
  seam everything else consumes), T-08/T-09 (sheet snapping + the revert/restore split). These are the tickets
  where a subtly wrong plan produces code that passes its tests and is still wrong.

### Forcing more thinking

Adding `think hard` (or `ultrathink`) to a prompt raises the thinking budget for that turn regardless of model —
useful on a planning turn if the ticket feels underspecified. *Note: whether this build's `/model` exposes an
explicit reasoning-effort selector, and what it's called, I haven't verified — the keyword approach works either
way.*

---

## Rules of thumb

- **Answer the gate questions properly.** "Just do it" is allowed, but every skipped answer becomes a recorded
  assumption, and assumptions are where rework comes from.
- **One ticket, one branch, one commit.** Parallel work goes in separate worktrees, never in one branch.
- **Don't let scope leak mid-loop.** New idea → add it to the ticket file → next loop.
- **Blocked decisions are listed per ticket** in the breakdown's *Decisions needed* table. Resolve the ones
  marked for a ticket *before* planning it, not during implementation.
- **A visual difference from the screenshot is a bug, not a preference** (`design/CLAUDE.md` → Fidelity). The
  golden test is what enforces this — don't disable it to make a run go green.
