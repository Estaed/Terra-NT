/// Spacing tokens, transcribed from `design/design-system/tokens/spacing.css`.
///
/// Pure Dart — spacing is numbers, and nothing here needs Flutter.
class AppSpacing {
  AppSpacing._();

  // 4px base unit
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const section = 96.0;

  // Semantic aliases
  static const padCard = lg;
  static const padCardTestimonial = xl;
  static const padBanner = xxl;
  static const gapContent = lg;
  static const gapSection = section;
  static const padButtonY = 8.0;
  static const padButtonX = 14.0;
  static const padInputY = 8.0;
  static const padInputX = 12.0;
  static const padTabY = 6.0;
  static const padTabX = 14.0;

  /// `--pad-footer: 64px 32px` — a two-value CSS shorthand, split into its axes.
  static const padFooterY = 64.0;
  static const padFooterX = 32.0;

  // Container.
  //
  // These two are the marketing site's, not this app's: a phone never reaches a
  // 1280px container, and the tab shell's chrome is specified by the prototype, not
  // by `--nav-height`. They are transcribed anyway so this file diffs line-for-line
  // against the CSS; expect them to go unused.
  static const containerMax = 1280.0;
  static const navHeight = 56.0;
}
