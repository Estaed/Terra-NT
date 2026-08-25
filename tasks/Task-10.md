# Task-10 — Onboarding shell: progress, step machine, auto-advance

## Objective

Build the onboarding container — top bar, progress, the 15-step machine, gating and the
auto-advance timer — with the step bodies stubbed. Task-11 fills the bodies in. Splitting
here is deliberate: the timing behaviour is the risky part and deserves its own test suite
without 15 widgets in the way.

## ⛔ Blocked on `docs/PRD.md` Q4

Back from step 0 goes to **Login**, skipping Welcome (L938). It is plausibly intended and
plausibly an oversight — it was left out of the deviation list because, unlike V1–V6, it is
not self-contradictory. **Answer before wiring the back handler at step 0.** All other back
behaviour proceeds.

## Execution Guide

**Files:** `terra_nt/lib/features/onboarding/`.

**Backdrop:** `RouteCarBackdrop` in **progress** mode, fed `mapFraction(step)` from
Task-04 — i.e. `step / 14`, not `step / 15`.

**Top bar:** back button (`ArrowLeft`), pill progress bar filling to
`progressPercent(step)`, and an `"n/15"` counter where n is `step + 1`. Note again that the
counter divides by 15 while the map fraction divides by 14; both are correct.

**Step card:** slides in from `translateX(18px)` to 0 over **320 ms** on each step change.

**"NT-specific" badge** (`AppPillBadge` from Task-02) sits above the question on **steps
10–14 — the last five.** Verified against the prototype at L279, 296, 311, 328, 345.

**The step machine:**

- `onNext` refuses when `canNext(step, answers)` is false (Task-04), advances otherwise,
  and at step 14 navigates to Loading.
- `onBack` cancels any pending auto-advance, then decrements — except at step 0 (⛔ Q4).
- **Answers survive back-navigation.** Going back and forward again preserves what was
  picked; do not clear on back.
- The footer button reads `"Next"`, except at step 14 where it reads
  **`"Generate My Route"`**. It is disabled whenever `canNext` is false.

**Auto-advance — the part that needs care.** Source L902–910.

- Single-select and two-card steps schedule an advance **380 ms** after a pick.
- A second pick inside that window must **cancel and restart** the pending advance, not
  queue a second one. Getting this wrong double-advances and skips a question.
- Any back navigation, or leaving the screen, cancels it.
- Step 14 never schedules one.
- **Multi-select (step 3) and both sliders (steps 1, 11) never auto-advance.**

Use `fakeAsync` / `tester.pump(Duration)` to test this — never a real delay.

## Acceptance Criteria (DoD)

- [ ] Counter renders `"1/15"` at step 0 and `"15/15"` at step 14.
- [ ] Progress bar width reflects `progressPercent(step)`; asserted at steps 0 and 14.
- [ ] The `NT-specific` badge is present on steps 10, 11, 12, 13, 14 and **absent on steps 0–9** — all fifteen asserted.
- [ ] The footer button reads `"Next"` on steps 0–13 and `"Generate My Route"` on step 14.
- [ ] The footer button is disabled on each of the 12 gated steps until its answer is set, and enabled on steps 1, 9 and 11 unconditionally.
- [ ] Timer test: a single-select pick advances after exactly 380 ms — asserted still-on-step at 379 ms and advanced at 380 ms.
- [ ] Timer test: two picks 100 ms apart result in **exactly one** advance, 380 ms after the *second* pick.
- [ ] Timer test: navigating back with an advance pending cancels it — no advance fires afterwards.
- [ ] Timer test: step 3 (multi-select) and steps 1 and 11 (sliders) schedule **no** timer.
- [ ] Answers survive back-navigation: set step 0's answer, go forward, go back — the answer is still selected.
- [ ] Disposal test: leaving onboarding with a pending advance leaves no active timer and fires no navigation.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/onboarding/` returns nothing.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/onboarding/` exits 0.
