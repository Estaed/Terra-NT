# Task-11 — Onboarding step bodies (15 questions, 5 types)

## Objective

Fill in the fifteen step bodies inside Task-10's shell. Fifteen questions, but only **five
widget types** — build the five, then configure them. Building fifteen bespoke widgets
would be a Part 1 rule 2 violation.

## Execution Guide

**Files:** `terra_nt/lib/features/onboarding/steps/`.

Source of truth: `Terra NT.dc.html` L105–377 for markup, L1226–1249 for option labels.
Copy is character-for-character, **including the en-dashes in `"18–25"`** and the
apostrophe in `"What's your budget?"`.

### The five types

| Type | Steps | Behaviour |
|---|---|---|
| `SingleSelectStep` | 0, 2, 4, 5, 6, 7, 8, 10, 12, 13 | Radio-style rows using `AppChip`; auto-advances |
| `MultiSelectStep` | 3 | Toggle rows; **never auto-advances**; sub-label "Select all that apply" |
| `SliderStep` | 1, 11 | Big number readout; never auto-advances |
| `TwoCardStep` | 9 | Two cards with title + description; auto-advances on either |
| `YesNoStep` | 14 | Two cards with title + description; **manual** button |

### Per-step configuration

| # | Question | Options |
|---|---|---|
| 0 | Which age range are you in? | 18–25 / 26–35 / 36–50 / 50+ |
| 1 | How many days is your trip? | slider 1–14, default 7, unit "days", ends "1 day" / "14 days" |
| 2 | Who are you traveling with? | Solo / Couple / Family / Friends |
| 3 | What's the main focus of this trip? | Nature / Aboriginal Culture / Adventure / Relaxation |
| 4 | What are you traveling in? | 4x4 / Campervan / Standard Car / Guided Tour |
| 5 | What's your budget? | Budget / Mid-range / Luxury |
| 6 | Where do you want to stay? | Camping / Motel/Cabin / Hotel |
| 7 | What's your physical activity level? | Low / Medium / High |
| 8 | Which region do you want to focus on? | Top End / Red Centre / Full NT |
| 9 | How detailed should your itinerary be? | "Just the highlights" / "A short list of must-see stops per day" — "Detailed hourly plan" / "Hour-by-hour schedule with timing" |
| 10 | How confident are you driving a 4x4 off-road? | Low / Medium / High |
| 11 | How well do you handle extreme heat? | slider 1–5, default 3, ends "Prefer cool weather" / "Thrives in the heat" |
| 12 | Camping under the stars, or resort comfort? | Camping all the way / Bit of both / Resort comfort |
| 13 | How interested are you in spotting wildlife? | Not fussed / Interested / Big draw |
| 14 | Comfortable in remote areas with no phone signal? | "Yes, I'm prepared to go off-grid" / "Comfortable with long stretches out of range" — "I'd prefer to stay connected" / "Would rather stick to areas with signal" |

**Step 11's readout shows a label per notch** from Task-03's `heatLabels`, indexed
`heat - 1`. Clamp the value to 1–5.

**Step 9 writes the same answer the Result screen's segmented control reads.** It is one
value (`answers.detailed`), not two — `docs/PRD.md` §3.6. Do not add a second field.

## Acceptance Criteria (DoD)

- [ ] `lib/features/onboarding/steps/` contains exactly five step-type widgets.
- [ ] All 15 question strings render character-for-character, asserted with `find.text`.
- [ ] All option labels across all steps render character-for-character, including `"18–25"` with an en-dash and `"Motel/Cabin"`.
- [ ] Selecting an option on any single-select step writes the matching field on `OnboardingAnswers`.
- [ ] Step 3: tapping an option toggles it in `focus`; tapping again removes it; the footer button re-disables when the last one is deselected.
- [ ] Step 1: the slider spans 1–14, starts at 7, and updates the readout.
- [ ] Step 11: the slider spans 1–5, starts at 3, and the readout label matches `heatLabels[heat - 1]` for **all five** notches.
- [ ] Step 9: tapping either card sets `answers.detailed` and applies the selected chip styling to the tapped card only.
- [ ] Step 9 writes **`answers.detailed` and no other field** — a test snapshots `OnboardingAnswers` before and after, asserting `detailed` is the only change. (This is what lets Task-13's segmented control share the value rather than duplicate it; the Result screen does not exist yet.)
- [ ] Step 14: tapping yes or no enables the button; neither triggers an auto-advance.
- [ ] No layout exception at 360px width on the tallest step card (step 14, two multi-line cards).
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/onboarding/steps/` returns nothing.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/onboarding/` exits 0.
