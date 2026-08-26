---
name: research
description: Answers a factual question against the live web with dated, sourced findings — whether a package is maintained, what version is current, whether an API still exists, what an approach's known traps are. Reports; never edits the PRD, CLAUDE.md Part 2 or a task file. Cross-cutting — callable from any phase. For choosing between competing approaches, use idea-arena instead.
---

# research

## Objective

Bring back what is **true right now**, with sources and dates, and hand the decision back.

One job: a checkable claim, checked. Choosing between competing approaches is a different
job — that is `idea-arena`.

**This skill never writes to `docs/PRD.md`, `CLAUDE.md` → Part 2, or a task file.** It
reports; the user decides, and the skill that owns that document records it. A finding that
edits the spec on its own is how a sentence off the web silently becomes a requirement
nobody approved.

## Workflow

1. **State the question as a claim that can be false.** "This library renders raster tiles
   with no API key" is checkable. "Which map library is best" is not — that is `idea-arena`.

2. **Search, then read the primary source.** Official documentation, the repository, the
   changelog, the package registry — in that order. A blog post is evidence that something
   *was* true on its date; it is never evidence that it is true now.

3. **Two independent sources for anything a decision rests on.** Independent means a
   different origin, not two pages of the same site. One source is a lead, not a fact.

4. **Date everything** — the source's date and the date you checked. Your own knowledge
   cutoff is not a source. Where memory and the web disagree the web wins, and you say
   plainly that the memory was wrong rather than splitting the difference.

5. **Report contradictions; do not resolve them.** When two credible sources disagree, that
   disagreement *is* the finding. Quietly picking one and presenting it as settled destroys
   the only signal that mattered.

6. **Say what is unknown.** Anything you could not establish is written as
   **"TBD — needs validation"**, with what would settle it. Never fill a gap with a
   plausible sentence, however reasonable it sounds.

7. **Report**, one short block per claim: *claim · verdict (confirmed / contradicted /
   unknown) · sources with dates · what it changes for the decision at hand*. End with
   **where this belongs** — the reason column of Part 2's stack table, a new PRD open
   question, or nowhere. Naming the destination is part of the job; writing it there is not.

8. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands not
   covered in this skill, DO NOT make assumptions or guess. Immediately halt execution,
   consult `CLAUDE.md` Part 1 for operational principles, and explicitly ask the user for
   clarification.

## Done when

Every claim carries a dated source or is marked unknown, no contradiction was quietly
reconciled, nothing was written into `docs/PRD.md`, Part 2 or a task file, and the user has
what they need to decide.
