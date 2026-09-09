import 'package:flutter/painting.dart';

/// Font families, transcribed from `design/design-system/tokens/fonts.css`.
///
/// The CSS names full fallback stacks (`"Inter", system-ui, …`). Flutter resolves a
/// single family per `TextStyle` and falls back on its own, so only the head of each
/// stack transfers. The names are the ones `pubspec.yaml` declares for the bundled
/// `.ttf` files — `JetBrainsMono`, not `JetBrains Mono`.
///
/// The CSS pulls both families from Google Fonts via `@import`. Task-00 replaced that
/// with bundled assets deliberately: an app about places with no phone signal must not
/// have network-dependent typography (`CLAUDE.md` Part 2 → Stack).
class AppFonts {
  AppFonts._();

  // Base families — substitutes standing in for the proprietary Terra NT cuts.
  static const display = 'Inter';
  static const text = 'Inter';
  static const mono = 'JetBrainsMono';

  // Semantic aliases
  static const heading = display;
  static const body = text;
  static const ui = text;
  static const code = mono;
}

/// The weight scale from `typography.css`. Terra NT resists 700+ on display.
class AppWeights {
  AppWeights._();

  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
}

/// The 13 type roles, transcribed from `design/design-system/tokens/typography.css`.
///
/// The CSS models a role as five custom properties (`family`, `size`, `weight`,
/// `leading`, `tracking`); here one role is one [TextStyle]. The mapping is direct:
/// CSS `leading` is a unitless multiple of font size, which is exactly what Flutter's
/// [TextStyle.height] means, and CSS `tracking` is in px, which is what
/// [TextStyle.letterSpacing] takes.
///
/// Tracking is aggressively negative across the display ramp and positive on exactly
/// one role, `eyebrow`.
class AppType {
  AppType._();

  /// Tracking measured from the app's Login title in the prototype.
  static const loginHeadlineTracking = -1.4;

  /// display-xl — largest hero headline
  static const displayXl = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 80,
    fontWeight: AppWeights.semibold,
    height: 1.05,
    letterSpacing: -3,
  );

  /// display-lg — section opener headlines
  static const displayLg = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 56,
    fontWeight: AppWeights.semibold,
    height: 1.1,
    letterSpacing: -1.8,
  );

  /// display-md — sub-section headlines
  static const displayMd = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 40,
    fontWeight: AppWeights.semibold,
    height: 1.15,
    letterSpacing: -1,
  );

  /// headline — pricing tier titles, CTA banner heading
  static const headline = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 28,
    fontWeight: AppWeights.semibold,
    height: 1.2,
    letterSpacing: -0.6,
  );

  /// card-title — feature card title
  static const cardTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    fontWeight: AppWeights.medium,
    height: 1.25,
    letterSpacing: -0.4,
  );

  /// subhead — lead body, intro paragraphs
  static const subhead = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 20,
    fontWeight: AppWeights.regular,
    height: 1.4,
    letterSpacing: -0.2,
  );

  /// body-lg — hero subhead, lead paragraphs
  static const bodyLg = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 18,
    fontWeight: AppWeights.regular,
    height: 1.5,
    letterSpacing: -0.1,
  );

  /// body — default body
  static const body = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 16,
    fontWeight: AppWeights.regular,
    height: 1.5,
    letterSpacing: -0.05,
  );

  /// body-sm — card body, footer columns
  static const bodySm = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 14,
    fontWeight: AppWeights.regular,
    height: 1.5,
    letterSpacing: 0,
  );

  /// caption — captions, meta, status
  static const caption = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 12,
    fontWeight: AppWeights.regular,
    height: 1.4,
    letterSpacing: 0,
  );

  /// button — all button labels
  static const button = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 14,
    fontWeight: AppWeights.medium,
    height: 1.2,
    letterSpacing: 0,
  );

  /// eyebrow — section eyebrow, the one positive-tracked role
  static const eyebrow = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    fontWeight: AppWeights.medium,
    height: 1.3,
    letterSpacing: 0.4,
  );

  /// mono — code in product screenshots, IDs and status tokens
  static const mono = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    fontWeight: AppWeights.regular,
    height: 1.5,
    letterSpacing: 0,
  );

  /// The app's largest type — the 44px "Terra NT" Login headline
  /// (`docs/PRD.md` §3.1).
  ///
  /// The three display roles above are the marketing site's (80/56/40px); nothing in
  /// this app is that large. Rather than rescale them and lose the line-for-line diff
  /// against the CSS, this one extra role continues the same ramp at the app's size.
  /// Its leading and tracking are linearly interpolated between the two neighbouring
  /// CSS roles, `display-md` (40px) and `display-lg` (56px), at t = (44-40)/16 = 0.25:
  ///
  ///   tracking: -1.0 + 0.25 * (-1.8 - -1.0)  = -1.2px
  ///   leading:   1.15 + 0.25 * (1.1  - 1.15) =  1.1375 -> 1.14
  ///
  /// Family and weight are constant across the ramp, so they are carried unchanged.
  static const displayApp = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 44,
    fontWeight: AppWeights.semibold,
    height: 1.14,
    letterSpacing: -1.2,
  );

  /// title-app — row and option labels (L111, L618, L638).
  ///
  /// Tracking interpolates `body-sm` (14px, 0) -> `body` (16px, -0.05) at t = 0.5:
  /// `0 + 0.5 * (-0.05 - 0) = -0.025`. Weight is a deliberate w600 override — every
  /// one of those call sites hardcodes `font-weight:600` — not the ramp's own value.
  static const titleApp = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 15,
    fontWeight: AppWeights.semibold,
    height: 1.4,
    letterSpacing: -0.025,
  );

  /// button-app — segmented and toggle pills (L435-441).
  static const buttonApp = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    fontWeight: AppWeights.medium,
    height: 1.2,
    letterSpacing: 0,
  );

  /// body-app — Language value, subtitles (L646).
  static const bodyApp = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 13,
    fontWeight: AppWeights.regular,
    height: 1.5,
    letterSpacing: 0,
  );

  /// caption-app — pill badges and tag labels (L279, L485).
  static const captionApp = TextStyle(
    fontFamily: AppFonts.text,
    fontSize: 11,
    fontWeight: AppWeights.regular,
    height: 1.4,
    letterSpacing: 0,
  );

  /// The 13 CSS roles, keyed by their CSS names.
  ///
  /// This is the transcription of `typography.css` and nothing else, which is why
  /// [displayApp], [titleApp], [buttonApp], [bodyApp] and [captionApp] — additions of
  /// this app's, not of the token bundle — are absent.
  static const Map<String, TextStyle> roles = {
    'display-xl': displayXl,
    'display-lg': displayLg,
    'display-md': displayMd,
    'headline': headline,
    'card-title': cardTitle,
    'subhead': subhead,
    'body-lg': bodyLg,
    'body': body,
    'body-sm': bodySm,
    'caption': caption,
    'button': button,
    'eyebrow': eyebrow,
    'mono': mono,
  };
}
