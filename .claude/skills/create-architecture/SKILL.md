---
name: create-architecture
description: Turns docs/PRD.md into CLAUDE.md → Part 2 — the stack, folder layout, layer rule, seams and verification rules that every task is then written against. Use once per project, after the PRD exists and before generate-tasks. Second of the once-per-project sequence in CLAUDE.md Part 1.
---

# create-architecture

## Objective

Decide *how* this project is built, and write the decision into `CLAUDE.md` → **Part 2**.

`docs/PRD.md` answers **what** and **why** and deliberately decides no engineering. Part 2
answers **how**: the stack with real versions, where code lives, which direction imports
run, which seams exist, and what "verified" means. It is the one section loaded into every
session, so it is the only place a technical invariant is always present.

This is a **decision session, not a document generator.** The conversation is most of the
work; the file is what is left over at the end.

## Workflow

0. **Check what already exists, and stop if the answer is "Part 2".** If `CLAUDE.md` no
   longer contains the literal marker `PART-2-PLACEHOLDER`, Part 2 is already written for
   this project: **stop and ask** before touching it. Say what it currently decides and
   what the user seems to want changed, then offer the real choices — **amend** the parts
   that are genuinely wrong, or **leave it alone**. Never rewrite it wholesale: tasks were
   written against it, so a changed stack or folder layout invalidates work already on
   disk, and Part 1 rule 1 makes that the user's call.

   If `docs/PRD.md` does not exist, stop too. Run `create-prd` first — deciding a stack for
   a product nobody has described yet is guessing with extra steps.

1. **Read the PRD and whatever it points at.** Every screen, the out-of-scope list, the
   open questions, the phases if it has them, and the design or prototype files it names.
   Note what the material *already decides for you*: a prototype that uses a specific map
   provider, a token bundle, an existing API contract. Those are constraints, not options,
   and pretending otherwise wastes a round of discussion.

   **Where the PRD names no material at all, say so.** Then everything below is genuinely
   open, and the questions matter more, not less.

2. **Separate the real decisions from the obvious ones.** Most of a stack is not a
   decision — it follows from one or two choices the user has already made or from what
   the PRD forces. Name those in a sentence and move on.

   A **real** decision is one where two defensible answers exist and they lead to
   different code. For each of those, and only those, put **2–3 options with their
   trade-offs** to the user, recommend one with the reason, and wait. **Ask up to 4
   questions at a time** — the ceiling the question tool accepts, not a target. Optimise
   for, in this order: what the PRD's v1 actually needs; what the user already knows; and
   reversibility — spend the deliberation on the calls that are expensive to undo, and
   just decide the cheap ones out loud.

   **Finding facts is your job; only decisions are the user's.** Whether a package is
   maintained, what version resolves, whether an API still exists, what a platform's limit
   is — none of these are questions for the user. Look them up: the lockfile, the docs,
   `research`. Put to the user only what the evidence cannot settle: what they want, what
   they will not accept, and which constraint is real. A question spent on a lookup is a
   question the user has to answer twice — once to you, and once to whatever you got wrong.

   **Where a decision is both uncertain and expensive to undo, do not guess — spike it.**
   Three lines, then run the smallest thing that answers it:

   > **Question:** what is not known · **Spike:** the smallest build or test that answers
   > it, timeboxed · **Decision rule:** X if <signal>, Y if <counter-signal>

   Record the answer *and the spike that produced it* next to the decision in Part 2. A
   cheap, reversible call does not earn this ceremony — decide it out loud and move on.

3. **Resolve versions against the machine, never against memory.** Create the project
   scaffold and let the package manager resolve the graph, then read every version back
   out of the real lockfile. A version recalled from memory is a guess wearing the costume
   of a fact, and it is the single most expensive kind of error in this file: every task
   afterwards is written against it.

   Where the resolver's answer surprises you — a major version older than expected, a pin
   that forces a downgrade elsewhere — **record what happened and why**, in the table,
   next to the version. Without the reason, a later session bumps it "helpfully" and the
   graph breaks again.

   If creating the scaffold belongs to the first task rather than to this session, that is
   fine — but then mark the table **provisional** in place, and make writing the resolved
   versions back into it part of that task's Acceptance Criteria. What is not acceptable
   is a table that looks resolved and never was.

   **What a lockfile cannot tell you, the web can.** Whether a package is still maintained,
   whether the API you are about to build on still exists, whether an approach has a known
   trap — none of that lives in a version number, and none of it is safe to recall from
   memory. Run `research` in fact mode for those, and carry its dated sources into the
   reason column of the table. Where the web contradicts what you expected, the web wins.

4. **Decide the seams, and no more than the seams.** Name only the interfaces a *later
   phase named in the PRD* actually needs, and say what sits behind each one today. Every
   other abstraction "for later" is speculative generality — Part 1 rule 2 forbids it, and
   one implementation means one concrete class.

5. **Write the verification rules as commands, not intentions.** This is the section
   `verify-task` executes literally, so every item is a command with **the directory it
   runs from**, and every command in it has been **run once, here, successfully** before
   it is written down. Two failures make a checker silently lie: a tool that only finds
   its config from the current directory, and a POSIX-only idiom on a Windows machine.

   State what "clean" means with no room to negotiate ("zero errors and zero warnings",
   never "only the pre-existing ones"). Name the *actual* functions that must carry a unit
   test rather than "the logic". And say explicitly what is **not** in the Definition of
   Done — the omission that is deliberate is the one that gets argued about in every
   review until it is written down.

6. **Fill the Part 2 skeleton and delete the placeholder block**, marker line included.
   Keep the headings; delete a section only if the project truly has no such surface, and
   say that you deleted it. Apply one test to every line: **would removing it cause a
   mistake?** If not, cut it — Part 2 is loaded into every session, and a rule that steers
   no decision is paying no rent.

   **None of the skeleton's own instruction text stays in the file**, wherever it sits —
   the warning block, the marker line, "the headings below are the skeleton to fill",
   "apply one test to every line", "why this section exists". They describe how to write
   Part 2, not this project, and every one of them is loaded into every session forever.
   And **put the project's name in the file's title** while you are there.

   State choices, not slogans. "Tokens are named constants in `core/theme/`; no component
   hardcodes a hex" steers a decision; "styling should be consistent" does not.

   **Record what was rejected, not only what won.** Every option seriously considered and
   turned down gets one line with its reason — a package, an approach, a layout. A Part 2
   listing only winners reads as though there was never a choice, and the same rejected
   option comes back in three weeks, proposed by a session that cannot see why it lost.

7. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands not
   covered in this skill, DO NOT make assumptions or guess. Immediately halt execution,
   consult `CLAUDE.md` Part 1 for operational principles, and explicitly ask the user for
   clarification.

## Done when

`CLAUDE.md` → Part 2 is written and the `PART-2-PLACEHOLDER` marker is gone; every package
version in it is traceable to a lockfile on this machine; every verification command has
been run once and names the directory it runs from; every seam names what is behind it
today; every option that was seriously considered and rejected is written down with its
reason; and anything still undecided is written down as undecided rather than guessed.
Next step is `generate-tasks`.
