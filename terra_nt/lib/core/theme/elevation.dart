import 'package:flutter/painting.dart';

import 'colors.dart';

/// Elevation tokens, transcribed from `design/design-system/tokens/elevation.css`.
///
/// Depth here is a surface step plus a 1px hairline, not a shadow: the CSS levels are
/// surface/border recipes. Each level is therefore a background colour and a border
/// colour, both aliases of [AppColors].
class AppElevation {
  AppElevation._();

  /// Every level's border is `1px solid` in the CSS.
  static const hairlineWidth = 1.0;

  /// `--elev-0-bg: transparent`, `--elev-0-border: none`.
  static const level0Bg = Color(0x00000000);
  static const Color? level0Border = null;

  static const level1Bg = AppColors.surface1;
  static const level1Border = AppColors.hairline;

  static const level2Bg = AppColors.surface2;
  static const level2Border = AppColors.hairlineStrong;

  static const level3Bg = AppColors.surface3;

  /// Transcribed as written: `--elev-3-border` is the plain hairline in the CSS, the
  /// same as level 1, while the ladder around it steps up. Not a slip to correct here.
  static const level3Border = AppColors.hairline;

  static const level4Bg = AppColors.surface4;
  static const level4Border = AppColors.hairlineTertiary;

  /// Focus ring — 2px primary-focus at 50% opacity. The CSS `rgb(94 105 209 / 0.5)`
  /// is `--color-primary-focus`, so this stays an alias.
  ///
  /// `--ring-focus` itself is a `box-shadow` shorthand bundling both values; Flutter
  /// draws a focus ring as a border, so only its two parts transcribe.
  static final ringFocusColor = AppColors.primaryFocus.withValues(alpha: 0.5);
  static const ringFocusWidth = 2.0;

  /// A faint white highlight on the top edge of lifted panels, giving dark surfaces a
  /// pixel-rendered feel.
  ///
  /// The CSS expresses these as `inset` box-shadows. Flutter has no inset shadow, so
  /// they are exported as colours: a caller paints one as a 1px top border or a short
  /// top-edge gradient. Do not approximate them with an outer shadow.
  static final edgeHighlight = AppColors.inverseCanvas.withValues(alpha: 0.06);
  static final edgeHighlightStrong =
      AppColors.inverseCanvas.withValues(alpha: 0.1);

  /// `--shadow-overlay: 0 8px 32px rgb(0 0 0 / 0.6)` — the only real shadow in the
  /// system, and reserved for surfaces lifted off the page (menus, dialogs) only.
  static final shadowOverlay = <BoxShadow>[
    BoxShadow(
      color: AppColors.overlay.withValues(alpha: 0.6),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
}
