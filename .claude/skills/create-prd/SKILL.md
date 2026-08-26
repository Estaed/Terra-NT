---
name: create-prd
description: Acts as an /init for project requirements — turns the user's initial prompt, idea, or design/prototype files into a lean PRD.md. Use at the very start of a project, or when the product spec is missing, stale, or has never been written down. Phase 1 of the workflow in CLAUDE.md Part 1.
---

# create-prd

## Objective

Act as an `/init` command for project requirements. Take the user's initial prompt,
idea, or provided design files and create a lean Product Requirements Document
at `docs/PRD.md`.

`docs/PRD.md` answers **what** and **why**. It does not answer *how* — no stack choices,
no folder layout, no package names. Those belong in `CLAUDE.md` → Part 2, which is
written from this PRD afterwards.

**If the approach itself is still open** — the problem is clear but which solution is right
is not — that question belongs to `idea-arena`, and it runs *before* this skill. Settling it
silently inside a PRD interview means the first plausible answer wins by default, and the
PRD then reads as though there was never a choice.

## Workflow

0. **If `docs/PRD.md` already exists, stop and ask before writing anything.** Read
   it first, then say concretely what you found — which sections still match the
   code and the user's description, which have gone stale, and what is missing —
   and offer the three real choices: **update** the stale parts in place, **rewrite**
   it from scratch, or **leave it alone**. Wait for the answer.

   Never overwrite a PRD silently. It is the document every task and every
   architecture decision was derived from, so replacing it invalidates work that
   already exists downstream, and the parts that are still correct are usually most
   of the file. Answered open questions and recorded decisions are the easiest
   things to destroy this way and the hardest to reconstruct — preserve them
   verbatim unless the user says otherwise. On **update**, treat this whole workflow
   as editing rather than generating: keep the existing structure and touch only
   what is genuinely out of date.

   When the user rules out an option the PRD had recorded, **strike it and write down
   why**, rather than quietly deleting the line. An option that was reasonable enough
   to write down will look reasonable again to the next reader, especially when the
   repository still supports it — a deleted file that is one command away in history,
   a dependency that is still installed. Without the reason attached, the correction
   gets re-proposed.

1. **Analyze the input.** Read the user's initial prompt and every design or
   prototype file they point at. Find out what this project actually has before
   assuming a layout: prototypes or mockups (often under `design/`), a token or
   style bundle (read its own `README.md` first if it has one — it says which parts
   transfer), reference captures, and `docs/` for prior notes. Read them before
   asking anything, so your questions are about real gaps rather than things
   already on disk.

   **If a `design/` folder exists, that is where the UI lives.** Read it first and
   treat what is in it as the source of truth for every screen — a prototype, a token
   or style bundle, reference captures. A `README.md` inside it outranks any assumption
   you would otherwise make about which parts of it transfer.

   **A project may have none of this, and that is a valid start** — an idea and a
   conversation are enough to write a PRD from. Say plainly that there is no visual
   source of truth yet. Do not invent one, and never name a file that is not on
   disk: step 5 writes those paths into the PRD and task files are later written
   against them. The user has a real choice here, so ask which way they want it:
   specify the product in prose alone, or produce the design first — the built-in
   `design` skill generates one — and point the PRD at what it creates. It changes
   what step 5 can write, and it changes whether visual fidelity is a quality bar
   at all (step 4).

   On a large or unfamiliar repo this initial survey may be delegated to a
   read-only `Explore` agent, which keeps a pile of file dumps out of the main
   context. Delegate the *looking* only: the questions, the decisions and the
   writing stay here, because they depend on the conversation with the user.

2. **Interrogate the user to fill gaps.** Ask questions focused on the **What**
   and **Why**: core purpose, target user, main features, explicit out-of-scope
   items, success criteria. **Ask up to 4 questions at a time and wait for answers**
   before asking the next batch — 4 is the hard ceiling the question tool accepts,
   not a target. Do not batch a questionnaire: a later question whose wording
   depends on an earlier answer belongs in the next round, not this one.

   **Finding facts is your job; only decisions are the user's.** Before asking anything,
   check whether the answer is already on disk, in the repository, or on the web — if it
   is, go and get it (`research` for the web, a read-only `Explore` agent for a large
   codebase) instead of spending a question on it. Questions are scarce: every one spent
   on something you could have looked up is one fewer the user will still be patient for
   when you reach a question only they can answer — what they want, what they will not
   accept, and which constraint is real.

2b. **A requirement resting on a factual claim gets the claim checked, not assumed.**
   "The platform allows this", "that service is free at our volume", "this format is still
   supported", "users can't do X today" — run `research` and write the dated answer in, or
   write the open question. A PRD is where an unchecked assumption does the most damage:
   everything downstream inherits it as settled, and by the time it is contradicted the
   tasks built on it already exist.

3. **Align with MVP principles.** Push back on over-engineered feature requests.
   Keep the initial scope minimal. If a requested feature is not needed for the
   first working version, propose moving it to an explicit "Out of scope (v1)"
   list rather than silently dropping or silently including it.

4. **Every quality bar names how it gets verified.** For each standard the PRD
   sets — "matches the design", "fast enough", "accurate enough", "handles bad
   input" — ask the user the same question: *what would we run, or look at, to
   settle whether this holds?* Record the answer beside the bar.

   A bar with no answer is not a bar; it is a wish, and it stays an open question
   until someone decides. Say so plainly rather than writing it down as though it
   were settled. This matters because everything downstream inherits it:
   `generate-tasks` can only write criteria that are checkable, so a quality bar
   nobody knows how to verify silently becomes a task checklist that cannot mention
   it — and the gap surfaces at the end, after the tasks are written, instead of
   here where it is cheap.

   Be especially wary of bars that read as objective but hide a human judgement:
   "pixel-perfect", "natural-sounding", "feels responsive". Either they resolve to
   something machine-checkable, or they resolve to a named person looking at a
   named artifact — both are answers; "we'll know it when we see it" is not.

5. **Generate `docs/PRD.md`.** It must clearly explain what needs to be built (e.g.
   "Homepage", screen by screen) and **name the source of truth for every screen's
   UI/UX**. Where a prototype or design file specifies it, reference that file **by
   path, per screen**, and never re-describe in prose what it already specifies
   exactly — point at it. Where no design exists, this PRD's own description *is*
   the source of truth: say so in that sentence, so a task written from it later
   knows there is nothing else to consult. Suggested sections:
   - Purpose & target user
   - Screens / features, each naming its source of truth — a design file on disk,
     or this document itself, stated explicitly
   - Data model in plain terms (what the user sees, not the schema)
   - Out of scope (v1)
   - Open questions still awaiting a decision
   - **Deferred decisions, if the project has later phases** — one list of what each
     later phase still has to decide, gathered from wherever those decisions are
     already described in context. Keep it numbered **separately** from the open
     questions above: those get referenced by number from task files and the index,
     so that list must never be renumbered. Say explicitly that the deferred ones are
     unanswered on purpose and block nothing today — otherwise the list reads as a
     backlog and invites someone to start answering it early.

6. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands
   not covered in this skill, DO NOT make assumptions or guess. Immediately halt
   execution, consult `CLAUDE.md` Part 1 for operational principles, and explicitly
   ask the user for clarification.

## Done when

`docs/PRD.md` exists, every screen/feature names its source of truth — a file that
is really on disk, or this PRD itself — the out-of-scope list is explicit, and no
open question is silently answered by a guess. **Next step is `create-architecture`,
which writes `CLAUDE.md` → Part 2 from this PRD; `generate-tasks` comes after that
and refuses to run before it.** Skip it only if Part 2 is already written for this
project.
