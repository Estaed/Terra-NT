# Device tour — the defect class widget tests cannot see

Written 2026-09-11 from four defects this project actually paid for. Every claim below
was re-checked against the tree at `3552f9d` before it was written down; where the record
and the code disagreed, the code won and the record is corrected here.

## Why this file exists

Three separate Task-20 defects were found on a physical device and **none** of them was
caught by a green widget suite:

| Defect | Why the widget test missed it |
| --- | --- |
| System Back closed the app instead of popping the tab route | The inner `AppShell` Navigator's route-level `PopScope` shadowed the root one. Only reproduced with a real Back gesture, keyboard open. |
| Bottom inset counted twice, ~48 px of drift | A fixed test viewport reports zero device insets, so the double count sums to zero in tests. |
| `EdgeDraggingAutoScroller` asserted 12× per drag | Needs a real drag gesture against a 160 dp viewport holding a 300+ dp card. |

The pattern is one sentence: **a fixed test viewport has no notch, no gesture bar and no
real gesture stream, so a whole class of defect is invisible to it and silent in CI.**

## The rule

A task that changes **layout, safe-area handling, navigation/Back behaviour, or a drag
gesture** is not done when the suite is green. It is done after a device tour. Green tests
are necessary and not sufficient for those four categories; for everything else the
Verification Rules in `CLAUDE.md` Part 2 stand alone.

The tour is cheap and specific. Run the app on a physical device and exercise only what
the task touched:

- **Back** from every route the task can reach, including with the keyboard open.
- **Rotate / resize** if the task touched layout, and watch the bottom edge against the
  gesture bar.
- **Drag** the affected list to its boundary if the task touched reordering, and read
  logcat while you do it.

## Acceptance is two conditions, never one

The reorder fix is the standing proof. The first attempt disabled auto-scroll entirely.
Logcat went clean and the assertion disappeared — and reordering to an off-screen
neighbour became impossible inside the 190 px sheet anchor. A silenced log looked
identical to a fixed bug.

So the criterion is always **"no exception AND the behaviour still works"**. Write the
regression test to assert both halves. A test that only asserts the absence of an
exception will pass for the wrong fix.

The shipped fix reads the live `shouldAcceptUserOffset` flag
(`lib/features/itinerary/widgets/result_stop_list.dart`) and refuses the scroll during the
drag rather than removing the scroller.

## When a test and the product disagree, find out which is wrong

The Result map height case: the test expected 600 px and the product produced 664. The
instinct is to change the product. The product was right — the test had not accounted for
the shell's 64 px bottom navigation, and 664 − 64 = 600 was the correct reconciliation.

Before editing either side, state which one you believe and why. If the answer is "the
test is easier to change", that is not a reason.

## Mutant control before you call a test meaningful

A passing test proves nothing until you have seen it fail. Invert the condition it guards,
confirm the suite goes red, then revert. This caught a real gap in the `AppLaunch` routing
work — inverting the condition broke exactly 3 tests, which is what made the green
meaningful.

## Corrections to the written record

- **The safe-area double count is fixed.** Commit `3552f9d` ("stop double-counting the
  bottom inset and rebuild the result toolbar as one row") closed it. `BottomNav` does sit
  in the `Scaffold.bottomNavigationBar` slot and its `SafeArea(top: false)` is deliberate —
  the bar keeps its 64 px of content and pushes the device inset below it. Treat any older
  note calling this an open defect as stale.
- **There is no single 360×640 test viewport.** The suite sets `view.physicalSize`
  per-test and uses at least 360×640, 360×800, 393×852 and 320×800. The lesson survives in
  general form — none of them carries real device insets — but do not quote one number as
  if it were the project's viewport.
