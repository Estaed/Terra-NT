import 'package:flutter/painting.dart';

/// Colour tokens, transcribed from `design/design-system/tokens/colors.css`.
///
/// The sections and order below mirror that file so the two can be diffed by eye.
///
/// Only *base* tokens carry a literal. Every semantic alias references the base
/// constant it points at, exactly as the CSS uses `var(--color-…)`: duplicating a
/// hex would mean a correction had to be made in two places, which is the whole
/// reason this file exists.
class AppColors {
  AppColors._();

  // ---------- Brand & accent ----------
  static const primary = Color(0xFF5E6AD2);
  static const primaryHover = Color(0xFF828FFF);
  static const primaryFocus = Color(0xFF5E69D1);
  static const onPrimary = Color(0xFFFFFFFF);
  static const brandSecure = Color(0xFF7A7FAD);

  // ---------- Surface ladder ----------
  static const canvas = Color(0xFF010102);
  static const surface1 = Color(0xFF0F1011);
  static const surface2 = Color(0xFF141516);
  static const surface3 = Color(0xFF18191A);
  static const surface4 = Color(0xFF191A1B);

  // ---------- Hairlines ----------
  static const hairline = Color(0xFF23252A);
  static const hairlineStrong = Color(0xFF34343A);
  static const hairlineTertiary = Color(0xFF3E3E44);

  // ---------- Ink ----------
  static const ink = Color(0xFFF7F8F8);
  static const inkMuted = Color(0xFFD0D6E0);
  static const inkSubtle = Color(0xFF8A8F98);
  static const inkTertiary = Color(0xFF62666D);

  // ---------- Inverse ----------
  static const inverseCanvas = Color(0xFFFFFFFF);
  static const inverseSurface1 = Color(0xFFF5F6F6);
  static const inverseSurface2 = Color(0xFFF6F7F7);
  static const inverseInk = Color(0xFF000000);

  // ---------- Semantic ----------
  static const success = Color(0xFF27A644);
  static const overlay = Color(0xFF000000);

  // ---------- Semantic aliases ----------
  static const bgPage = canvas;
  static const bgCard = surface1;
  static const bgCardFeatured = surface2;
  static const bgCardHover = surface2;
  static const bgMenu = surface3;
  static const bgLifted = surface4;
  static const bgInverse = inverseCanvas;

  /// `--bg-scrim: rgb(1 1 2 / 0.72)`. That rgb triplet is `--color-canvas`, so this
  /// stays an alias rather than a fourth literal. Not `const`: `withValues` is not.
  static final bgScrim = canvas.withValues(alpha: 0.72);

  static const textHeading = ink;
  static const textBody = ink;
  static const textSecondary = inkMuted;
  static const textTertiary = inkSubtle;
  static const textDisabled = inkTertiary;
  static const textInverse = inverseInk;
  static const textLink = primary;
  static const textLinkHover = primaryHover;

  static const borderCard = hairline;
  static const borderCardFeatured = hairlineStrong;
  static const borderNested = hairlineTertiary;
  static const borderFocus = primaryFocus;

  static const actionPrimaryBg = primary;
  static const actionPrimaryBgHover = primaryHover;
  static const actionPrimaryBgPressed = primaryFocus;
  static const actionPrimaryFg = onPrimary;
  static const actionSecondaryBg = surface1;
  static const actionSecondaryBgHover = surface2;
  static const actionSecondaryFg = ink;

  /// `--action-tertiary-bg: transparent`. Written as a fully transparent literal
  /// rather than `Colors.transparent` so this file needs no material import.
  static const actionTertiaryBg = Color(0x00000000);
  static const actionTertiaryBgHover = surface1;
  static const actionInverseBg = inverseCanvas;
  static const actionInverseBgHover = inverseSurface1;
  static const actionInverseFg = inverseInk;

  // ---------- Product-UI accent tags ----------
  //
  // Provisional (`docs/PRD.md` Q7): derived from the accent hue family, never
  // sampled from the real product. They keep their own literals even though
  // `tagBlue` currently equals `primary` and `tagGreen` equals `success` — a
  // correction to a tag must not drag a brand colour with it.
  static const tagBlue = Color(0xFF5E6AD2);
  static const tagPurple = Color(0xFF8B5CF0);
  static const tagGreen = Color(0xFF27A644);
  static const tagYellow = Color(0xFFD4A72C);
  static const tagOrange = Color(0xFFD97B34);
  static const tagRed = Color(0xFFD1484A);

  // ---------- App scrims and translucent surfaces ----------
  static final loginScrimStart = canvas.withValues(alpha: 0.5);
  static final loginScrimMid = canvas.withValues(alpha: 0.72);
  static final welcomeScrim = canvas.withValues(alpha: 0.42);
  static final onboardingScrim = canvas.withValues(alpha: 0.18);
  static final onboardingChrome = surface2.withValues(alpha: 0.7);
  static final stopDetailHeroScrim = surface1.withValues(alpha: 0.8);
}
