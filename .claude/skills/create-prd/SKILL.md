---
name: create-prd
description: Acts as an /init for project requirements — turns the user's initial prompt, idea, or design/prototype files into a lean PRD.md. Use at the very start of a project, or when the product spec is missing, stale, or has never been written down. Phase 1 of the workflow in CLAUDE.md Part 1.
---

# create-prd

## Objective

Act as an `/init` command for project requirements. Take the user's initial prompt,
idea, or provided design files and create a lean Product Requirements Document
(`PRD.md`) at the repo root.

`PRD.md` answers **what** and **why**. It does not answer *how* — no stack choices,
no folder layout, no package names. Those belong in `CLAUDE.md` → Part 2, which is
written from this PRD afterwards.

## Workflow

1. **Analyze the input.** Read the user's initial prompt and every design or
   prototype file they point at. In this repo that means `design/design-reference/`
   (HTML/React prototypes), `design/design-system/` (token bundle — read its
   `README.md` first, it says which parts transfer), any `screenshots/`, and
   `docs/` for prior notes. Read them before asking anything, so your questions
   are about real gaps rather than things already on disk.

2. **Interrogate the user to fill gaps.** Ask questions focused on the **What**
   and **Why**: core purpose, target user, main features, explicit out-of-scope
   items, success criteria. **Ask 1–2 questions at a time and wait for answers**
   before asking the next pair. Do not batch a questionnaire.

3. **Align with MVP principles.** Push back on over-engineered feature requests.
   Keep the initial scope minimal. If a requested feature is not needed for the
   first working version, propose moving it to an explicit "Out of scope (v1)"
   list rather than silently dropping or silently including it.

4. **Generate `PRD.md`.** It must clearly explain what needs to be built (e.g.
   "Homepage", screen by screen) and **explicitly reference the provided
   prototype/design files as the source of truth for UI/UX** — by path, per
   screen. Never re-describe in prose what a prototype file already specifies
   exactly; point at it. Suggested sections:
   - Purpose & target user
   - Screens / features (each one naming its design source-of-truth file)
   - Data model in plain terms (what the user sees, not the schema)
   - Out of scope (v1)
   - Open questions still awaiting a decision

5. **Fallback Rule:** If you encounter ambiguity, edge cases, or missing commands
   not covered in this skill, DO NOT make assumptions or guess. Immediately halt
   execution, consult `CLAUDE.md` Part 1 for operational principles, and explicitly
   ask the user for clarification.

## Done when

`PRD.md` exists at the repo root, every screen/feature names its design source of
truth, the out-of-scope list is explicit, and no open question is silently answered
by a guess. Next step is normally `generate-tasks` — but if `CLAUDE.md` → Part 2 is
still the placeholder, write Part 2 from this PRD first.
