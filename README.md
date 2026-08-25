# Terra NT

🚧 **Work in progress.** Not yet functional.

A Flutter road-trip planning app for the Northern Territory, Australia — log in,
answer a short onboarding, get an AI-generated multi-stop itinerary on a map,
edit and reorder stops, explore points of interest, and manage saved routes.

Built natively in Flutter (no WebView). Design spec and reference prototype
live in [`design/`](design/).

---

# Building this — the PIV loop

Work is sliced into 13 tickets in [`docs/tickets/terra-nt-route-planner.md`](docs/tickets/terra-nt-route-planner.md).
Each ticket goes through the same five-command loop. **One ticket per loop, one branch per ticket** — don't start
T-02 while T-01 is half-done.

## One-time setup

```bash
git init                        # required — /piv-implement branches, /piv-commit commits
git add -A
git commit -m "chore: design handoff bundle + ticket breakdown"

flutter --version               # expect Flutter 3.47.1 · Dart 3.13.1 (per design/CLAUDE.md)
```

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

## Worked example — T-01 (scaffold, tokens, core widgets, test harness)

### Step 1 — Plan

Paste this:

```
/piv-plan-implementation T-01 from docs/tickets/terra-nt-route-planner.md — project scaffold,
design tokens, core widgets, test harness. Treat design/CLAUDE.md (Architecture, Stack /
conventions, Design tokens, Definition of done) and design/PRD.md → Design tokens as already
decided — inherit them, don't reopen them.
```

Why it's shaped that way: the ticket is a local markdown file, not a Jira key, so it's a *free-form* input —
you have to point at the file **and** the section. The second sentence matters: without it the planner may
re-litigate settled calls (Riverpod vs Provider, which map package), burning the loop on decisions
`design/CLAUDE.md` already made.

**What happens next: it stops and asks you 3–6 numbered questions.** This is a deliberate gate, not a stall.
For T-01 expect roughly these — with a ready answer for each:

> **1. Tag colors.** `PRD.md` calls the six tag hues "provisional". Exact hexes?
> **→** *"Not available — the design-system bundle they live in wasn't handed off. Sample them from
> `design/screenshots/05-explore.png` and `06-plan-ai-result.png` (the category dots), define them as named
> tokens, and flag in the plan that they're sampled, not authoritative."*
>
> **2. Which platforms should `flutter create` target?**
> **→** *"Android + iOS only. No web, no desktop — the design is phone-only."*
>
> **3. Riverpod code-gen now, or wire it when the first notifier lands in T-03?**
> **→** *"Now — add the deps and `build_runner` config in T-01 so T-03 doesn't have to touch `pubspec.yaml`."*
>
> **4. How many core widgets in this first pass?**
> **→** *"Exactly the seven in the ticket. Nothing speculative — `design/CLAUDE.md` rule 2."*
>
> **5. Which environment pins the goldens?**
> **→** *"This machine (Windows). Record it in the test README; goldens are font-rendering-sensitive
> and must be regenerated, not fought, if we ever move to CI."*

Answer them in one message, numbered. If you don't care about one, say "your call" — it'll pick the recommended
default and record it as an assumption rather than guessing silently.

Then it writes `.claude/plans/terra-nt-scaffold-tokens.md` (or similar).

### Step 2 — Read the plan before implementing

Don't skip this. Open the file and check three things:

- **CONTEXT REFERENCES** — does it point at `design/PRD.md` → Design tokens and the screenshots?
- **STEP-BY-STEP TASKS** — is every token from the PRD represented (4 surfaces, 4 inks, 3 hairlines, 6 tags,
  3 type roles, the 8-value spacing scale, 5 radii, 3 motion durations)? Missing tokens here become hardcoded
  hexes in every later ticket.
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
no hex or magic number exists outside `lib/ui/core/theme/`. That last one is worth grepping for yourself —
it's the invariant every later ticket depends on.

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

- **Sonnet end-to-end is fine:** T-01, T-02, T-11, T-12, T-13 — well-specified, low cross-cutting state.
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
