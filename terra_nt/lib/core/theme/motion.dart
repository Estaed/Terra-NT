import 'package:flutter/animation.dart';

/// Motion tokens, transcribed from `design/design-system/tokens/motion.css`.
///
/// The CSS file records that these were *not* captured from the source design doc —
/// they are the system's recommended house defaults. Restrained by design: opacity
/// and colour crossfades, no bounce, no scale-in, no parallax.
///
/// They are the defaults, not the whole story. The app's own timings — the 380ms
/// auto-advance, the 320ms step slide, the 1.6s pulse, the 1.4s message rotation —
/// come from the prototype and are owned by the tasks that build those screens.
///
/// `--transition-hover` is a CSS shorthand bundling property, duration and easing
/// together; Flutter has no equivalent to transcribe, so it is deliberately absent.
class AppMotion {
  AppMotion._();

  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 160);
  static const slow = Duration(milliseconds: 240);

  /// `cubic-bezier(0.4, 0, 0.2, 1)`. Identical to `Curves.fastOutSlowIn`, but written
  /// out so the control points diff against the CSS.
  static const easeStandard = Cubic(0.4, 0, 0.2, 1);

  /// `cubic-bezier(0, 0, 0.2, 1)`. Flutter's `Curves.decelerate` is a different curve
  /// entirely, so this must be explicit.
  static const easeOut = Cubic(0, 0, 0.2, 1);
}
