import 'package:flutter/material.dart';

import 'colors.dart';
import 'motion.dart';
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
        pageTransitionsTheme: _pageTransitionsTheme,
      );

  /// One quiet transition for every pushed screen on both platforms, in place
  /// of Android's sideways slide-and-fade and iOS's edge slide (`docs/PRD.md`
  /// D18).
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
    },
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

/// A fade through the page colour: how every pushed screen arrives and leaves.
///
/// The screen being left is covered with [AppColors.bgPage] over
/// [AppMotion.base]; the arriving one then enters exactly as `Entrance` brings
/// content in: a fade and an [AppMotion.entranceRise] px rise over
/// [AppMotion.entrance] on [AppMotion.easeEmphasized]. Popping runs the same
/// path backwards. Nothing slides sideways or scales, and a half-faded page is
/// only ever seen over the app's own page colour, never over the bare window.
///
/// It takes iOS's edge-swipe back with the slide it belongs to; system Back
/// and the on-screen back controls behave exactly as before.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  static const _cover = AppMotion.base;
  static const _arrive = AppMotion.entrance;

  @override
  Duration get transitionDuration => _cover + _arrive;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final split = _cover.inMicroseconds / transitionDuration.inMicroseconds;
    final cover = animation.drive(
      CurveTween(curve: Interval(0, split, curve: AppMotion.easeOut)),
    );
    final arrive = animation.drive(
      CurveTween(curve: Interval(split, 1, curve: AppMotion.easeEmphasized)),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: cover,
          child: const ColoredBox(color: AppColors.bgPage),
        ),
        AnimatedBuilder(
          animation: arrive,
          builder: (context, page) => Transform.translate(
            offset: Offset(0, (1 - arrive.value) * AppMotion.entranceRise),
            child: page,
          ),
          child: FadeTransition(opacity: arrive, child: child),
        ),
      ],
    );
  }
}
