---
name: idea-arena
description: Takes a problem and the user's candidate solution, generates the genuinely different alternatives, has each one researched independently and attacked once with sources, then adjudicates them against criteria fixed in advance. Use before create-prd, when the problem is clear but the right approach is not. Produces a recommendation and the reasons — the user decides.
---

# idea-arena

## Objective

Find the best available answer to a **problem**, not the best defence of the first idea.

The input is a problem plus whatever solution the user already has in mind. The output is a
scored comparison of genuinely different approaches, each backed by its own sources, plus
what would have to be true for each to be the wrong choice. **The user decides.**

Runs **before `create-prd`**: its verdict is what the PRD then describes. It writes no
document itself.

## Why it is built this way

Two personas arguing inside one context share every blind spot, drift from evidence to
wording within a round or two, and hand a judge drawn from the same context a choice
between two writing styles. Three things make the contest real, and each step below exists
to protect one of them:

- **Evidence asymmetry** — each candidate is researched separately, so each side has read
  something the others have not.
- **Criteria fixed before any case is read** — criteria chosen afterwards get chosen to fit
  a winner.
- **A bounded attack** — one rebuttal round, and an attack with no source does not count.

## Workflow

1. **Write the problem without naming a solution.** Who has it, what it costs them today,
   what they do instead right now. Then apply the reframe test: **if only one solution
   could possibly fit the problem as written, it is a spec, not a problem** — rewrite it
   until more than one answer fits. This is the single step that stops the user's existing
   idea from winning before the contest starts.

   Ask the user to confirm the restatement before going further. Getting this wrong wastes
   every round after it.

2. **Fix the criteria now, with the user, before any candidate is examined.** What must the
   answer do, what must it not cost, what constraints are real (time, skill, platform,
   budget). Four to six of them, each phrased so two people would score it the same way.
   **Ask up to 4 questions at a time** and wait — the ceiling the question tool accepts,
   not a target.

   **Finding facts is your job; only decisions are the user's.** This holds for every
   question this skill asks, here and while expanding the user's idea in step 3. Whether an
   approach is technically possible, what it costs, whether anyone has done it — those are
   researched, never asked. Ask the user what they want, what they will not accept, and
   which constraint is real; asking them to defend their own idea's feasibility turns the
   arena into an interrogation and produces an answer no better than what they walked in
   with.

3. **Diverge.** Generate the candidate approaches that **differ in mechanism**, not in
   wording — a different way of getting the result, not a renamed version of the same way.
   The user's own idea enters here as one ordinary candidate.

   **A one-line idea still competes — but not as one line.** The user's sketch usually
   arrives as a sentence; before it can be compared it has to be stated as a *mechanism*:
   what the thing does, in what order, using what. Interview them until their idea sits at
   the same level of detail as the ones you generated — **up to 4 questions at a time**,
   waiting for answers. A short idea is not a weak idea, but an unstated one is simply not
   comparable, and scoring it as written would punish brevity instead of substance. If,
   once stated, it turns out to be the same mechanism as one you generated, say so and
   merge the two rather than letting it compete against itself.

   **Two to four candidates**, and the reason is not cost. Each one has to earn a real
   case — its own agent, its own sources, and a place in the scoring where the differences
   are larger than the noise. Ten candidates buy ten shallow cases and a comparison nobody
   can act on, and the rebuttal round pairs them off, so it grows faster than the field
   does. Where genuinely more mechanisms exist, **name them all**, carry the strongest few
   forward, and say which were dropped and why — silently truncating the field is how the
   option that would have won disappears without anyone seeing it.

   **If no genuinely different alternative exists, say so and stop.** A fabricated opponent
   produces a rigged contest whose verdict means nothing. "Your idea is the only mechanism
   that fits, and here is why" is a real and useful answer.

4. **Research each candidate independently.** One agent per candidate, each with its own
   brief, each capped at roughly six sources, each returning **notes with sources and no
   conclusion**. Agents do not see each other's notes.

   Notes, not conclusions, on purpose: an agent that has reached a verdict stops gathering
   evidence and starts defending, and what comes back is advocacy wearing a citation.

   The sourcing rules are the ones in `research` — primary sources first, two independent
   sources for anything load-bearing, everything dated, gaps written as
   **"TBD — needs validation"** rather than filled in.

5. **Build each case from its own notes only**, steelmanned — the strongest honest version
   of that approach. A claim with no note behind it does not enter the case.

6. **One rebuttal round.** Each candidate gets to attack the others' strongest claim, and
   **an attack that cites no source is discarded, not scored.** One round only: past that,
   the same model on both sides converges on rhetoric, and rounds three and four cost
   real time to produce heat.

7. **Adjudicate on the criteria, citing notes.** Score every candidate on every criterion
   and name the note behind each score. Rules that make the verdict worth reading:

   - Confidence is not evidence — the better-written case does not win.
   - **Whose idea a candidate was is never a tiebreaker.** Score it as one of the
     candidates and do not mention the user's authorship until the verdict is delivered.
   - **"No winner" is a real verdict.** Where the criteria do not separate the candidates,
     say what *would* — the single fact to look up, or the smallest experiment to run.
     That beats a coin flip dressed as a conclusion.

8. **A kill criterion per candidate:** what would have to be true for this to be the wrong
   choice, and how you would find out cheaply. An approach nobody can state a falsifier for
   has not been examined yet.

9. **Report and hand over.** The problem as restated, the criteria, the candidates, the
   scored table with citations, the rebuttals that survived, the verdict (including
   "undecided" and what settles it), every kill criterion, and everything still
   **TBD — needs validation**. Recommending is allowed; deciding is not.

   Then name the next step: the chosen approach goes into `create-prd` as the thing being
   built, and every remaining TBD goes in as an open question rather than as a settled fact.

10. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands not
    covered in this skill, DO NOT make assumptions or guess. Immediately halt execution,
    consult `CLAUDE.md` Part 1 for operational principles, and explicitly ask the user for
    clarification.

## Cost

This runs several researched passes over one question, so spend it where the answer is
expensive to get wrong: the shape of the product, a decision that later work will be built
on top of. A cheap, reversible call does not earn an arena — decide it out loud and move on.

## Done when

The problem is stated so that more than one solution fits it, the criteria were fixed
before the cases were read, every candidate carries its own dated sources, every surviving
attack cites one, the verdict names either a winner or what would decide it, each candidate
has a kill criterion, and the user has been asked to choose rather than told what was
chosen.
