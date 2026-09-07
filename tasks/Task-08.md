# Task-08 — Car-follows-route animated backdrop

> **Execution:** agent main loop (Claude) · effort `medium` · plan mode no
> *Why:* An animation judged by watching it; no plan text substitutes for running it.

## Objective

Build the animated map backdrop shared by Login (ambient loop) and Onboarding (progress
driven by step). This is the app's one genuinely tricky animation, which is why Task-04
already unit-tested the sampler it depends on.

## Execution Guide

**Files:** `terra_nt/lib/shared/map/route_car_backdrop.dart` and a `CarGlyph` widget.

**Composition:** `TerraMap` (Task-07, `interactive: false`) + the 7 backdrop route points
+ dashed polyline + `RouteDotMarker` per point + one moving `CarGlyph` marker.

**Driving the animation.** Source: `terra-nt-bg-map.html` L112–165.

- One `AnimationController` drives a single `0..1` progress value.
- On each tick, sample lat/lng via Task-04's `pointAtFraction` — **never lerp raw lat/lng
  between two arbitrary points.** A chord skips every waypoint in between whenever the
  fraction jump is large, and the jump from step 0 to step 14 is exactly that case.
- Travel duration is `700 + span × 3500` ms where `span` is the absolute fraction change,
  eased `1 - (1-t)³` (ease-out cubic).

**Two modes, one widget:**

| Mode | Behaviour |
|---|---|
| `ambient` (Login) | Drives to fraction 1, pauses **1400 ms**, reverses to 0, repeats forever. Starts after a 900 ms delay. |
| `progress(fraction)` (Onboarding) | Animates to the given fraction whenever it changes. Caller passes `mapFraction(step)` from Task-04. |

**`CarGlyph`:** a side-view car that **flips horizontally** to face its direction of
travel — it does not rotate. The prototype's comment explains why: a side-view glyph
rotated off-axis reads as broken, while flipping reads as facing the right way at any
bearing. Flip on the sign of the longitude delta between successive samples, over a 140 ms
transition. It also carries a soft ground shadow and a 1.7 s vertical bob.

> The bob and shadow are the one place the design system's "no animation beyond
> crossfades" rule is knowingly departed from, because the prototype specifies them
> directly. This is prototype-wins, consistent with `docs/PRD.md` §2.

**Disposal is a hard requirement.** Part 2 Verification Rule 4: anything started in
`initState` is cancelled in `dispose`, and the test asserts it. The ambient loop is
infinite, so a leaked controller here would run forever.

## Acceptance Criteria (DoD)

- [ ] The widget uses `pointAtFraction` from `lib/core/util/route_sampler.dart` — `grep -n "pointAtFraction" lib/shared/map/route_car_backdrop.dart` matches.
- [ ] `grep -rn "lerp" lib/shared/map/route_car_backdrop.dart` returns nothing (no raw coordinate interpolation).
- [ ] Widget test: sampling the car's position at 20 points across a full 0→1 sweep yields a sequence that passes within a small epsilon of **every one of the 7 route points**, proving it follows the polyline.
- [ ] Widget test: in `progress` mode, changing the fraction from 0 to 1 moves the marker; the intermediate positions are not a straight line between the endpoints (assert at least one sampled point is off the endpoint-to-endpoint chord by more than epsilon).
- [ ] Widget test: `CarGlyph` flips its horizontal scale when the longitude delta changes sign.
- [ ] Disposal test: pumping the widget then removing it leaves **no active timers or tickers** — the test fails if a ticker survives (`tester.binding.transientCallbackCount == 0` after disposal, and no pending timers).
- [ ] Ambient mode reverses direction rather than jumping: after reaching fraction 1 and the pause elapsing, the next sampled fraction is decreasing.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/shared/map/route_car_backdrop.dart` returns nothing.
- [ ] No layout exception at 360px width: the backdrop renders full-bleed at that width in both ambient and progress modes — the test pumps each and asserts no `FlutterError` was recorded.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/shared/map/` exits 0.
