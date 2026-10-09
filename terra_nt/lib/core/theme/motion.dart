import 'package:flutter/animation.dart';

/// Motion tokens, transcribed from `design/design-system/tokens/motion.css`.
///
/// The CSS file records that these were *not* captured from the source design doc —
/// they are the system's recommended house defaults. Restrained by design: opacity
/// and colour crossfades, no bounce, no scale-in, no parallax.
///
/// They are the defaults, not the whole story. The app's own timings — the 320ms
/// step slide, the 1.6s pulse, the 1.4s message rotation — come from the prototype
/// and are owned by the tasks that build those screens.
///
/// `--transition-hover` is a CSS shorthand bundling property, duration and easing
/// together; Flutter has no equivalent to transcribe, so it is deliberately absent.
class AppMotion {
  AppMotion._();

  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 160);
  static const slow = Duration(milliseconds: 240);

  // Prototype-owned app motion.
  static const onboardingStepSlide = Duration(milliseconds: 320);
  static const loadingMessageInterval = Duration(milliseconds: 1400);
  static const loadingCompletionDelay = Duration(milliseconds: 7000);
  static const loadingPulse = Duration(milliseconds: 1600);
  static const loadingProgressDriveLoop = Duration(milliseconds: 1800);
  static const resultSheetSnap = Duration(milliseconds: 220);
  static const resultRouteReveal = Duration(milliseconds: 1500);
  static const resultPinReveal = Duration(milliseconds: 120);
  static const resultCameraFit = Duration(milliseconds: 320);
  static const resultRouteRevealCurve = Curves.linear;
  static const resultCameraFitCurve = easeStandard;
  static const savedRouteSwipeSettle = Duration(milliseconds: 200);
  static const mapCarFlip = Duration(milliseconds: 140);
  static const mapCarBob = Duration(milliseconds: 1700);
  static const mapAmbientStartDelay = Duration(milliseconds: 900);
  static const mapAmbientPause = Duration(milliseconds: 1400);

  static const loadingPulseMaxScale = 1.4;
  static const loadingPulseMinOpacity = 0.3;
  static const loadingPulseMaxOpacity = 0.9;
  static const mapTravelBaseMilliseconds = 700.0;
  static const mapTravelSpanMilliseconds = 3500.0;

  /// `cubic-bezier(0.4, 0, 0.2, 1)`. Identical to `Curves.fastOutSlowIn`, but written
  /// out so the control points diff against the CSS.
  static const easeStandard = Cubic(0.4, 0, 0.2, 1);

  /// `cubic-bezier(0, 0, 0.2, 1)`. Flutter's `Curves.decelerate` is a different curve
  /// entirely, so this must be explicit.
  static const easeOut = Cubic(0, 0, 0.2, 1);

  // Polish pass, docs/PRD.md D18 (2026-09-29): content enters instead of popping in.
  // Still restrained — fade and a short rise, no bounce, no overshoot.

  /// One element's fade-and-rise on first build.
  static const entrance = Duration(milliseconds: 280);

  /// Delay between consecutive items of a list entering.
  static const entranceStagger = Duration(milliseconds: 45);

  /// Items after this index enter together, so a long list never waits.
  static const entranceStaggerMaxItems = 8;

  /// How far (logical px) an entering element rises into place.
  static const entranceRise = 12.0;

  /// A pressed button or card settles to this scale while held.
  static const pressScale = 0.97;

  /// `cubic-bezier(0.2, 0, 0, 1)` — the emphasised decelerate used for entrances.
  static const easeEmphasized = Cubic(0.2, 0, 0, 1);
}
