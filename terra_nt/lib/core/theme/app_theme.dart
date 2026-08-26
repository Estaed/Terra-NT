import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Assembles the app's [ThemeData] from the token files in this directory.
///
/// There is exactly one theme and it is dark. No light theme is defined anywhere —
/// `CLAUDE.md` Part 2 forbids adding one.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgPage,
        fontFamily: AppFonts.text,
        colorScheme: _colorScheme,
        textTheme: _textTheme,
      );

  /// Built explicitly, never with `ColorScheme.fromSeed`: seeding generates a whole
  /// tonal palette of colours that are not in the token set, which is precisely what
  /// the "no colour outside `design/design-system/tokens/`" rule exists to prevent.
  static const _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.brandSecure,
    onSecondary: AppColors.ink,
    surface: AppColors.surface1,
    onSurface: AppColors.ink,
    // The token set has no error or danger colour. `tag-red` is the nearest hue and
    // is itself provisional (`docs/PRD.md` Q7); referencing it by name keeps a later
    // correction a one-line change, which inlining a hex here would not.
    error: AppColors.tagRed,
    onError: AppColors.onPrimary,
  );

  /// Maps Material's text slots onto the type roles.
  ///
  /// The `mono` role has no Material slot — it is used by name, via [AppType.mono].
  static const _textTheme = TextTheme(
    displayLarge: AppType.displayXl,
    displayMedium: AppType.displayLg,
    displaySmall: AppType.displayMd,
    headlineLarge: AppType.displayApp,
    headlineMedium: AppType.headline,
    headlineSmall: AppType.cardTitle,
    titleLarge: AppType.subhead,
    titleMedium: AppType.bodyLg,
    titleSmall: AppType.button,
    bodyLarge: AppType.body,
    bodyMedium: AppType.bodySm,
    bodySmall: AppType.caption,
    labelLarge: AppType.button,
    labelMedium: AppType.eyebrow,
    labelSmall: AppType.caption,
  );
}
