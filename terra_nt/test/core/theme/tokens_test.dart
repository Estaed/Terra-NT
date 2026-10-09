import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/core/theme/typography.dart';

/// Proves the token transcription matches `design/design-system/tokens/`.
///
/// Asserting that a constant merely *exists* would pass on a mistyped hex, so the
/// colour cases below pin exact ARGB values. And asserting that an alias equals its
/// base would pass just as happily on a duplicated literal — which is the failure
/// this file most needs to catch, because a duplicated hex silently breaks the
/// one-line-correction property the whole token layer exists for. Only counting the
/// literals in the source file catches that, so two tests here read `lib/` off disk.
void main() {
  group('base colours', () {
    test('the DoD-named base tokens carry their exact hexes', () {
      expect(AppColors.canvas.toARGB32(), 0xFF010102);
      expect(AppColors.surface1.toARGB32(), 0xFF0F1011);
      expect(AppColors.primary.toARGB32(), 0xFF5E6AD2);
      expect(AppColors.ink.toARGB32(), 0xFFF7F8F8);
      expect(AppColors.inkTertiary.toARGB32(), 0xFF62666D);
      expect(AppColors.hairline.toARGB32(), 0xFF23252A);
      expect(AppColors.success.toARGB32(), 0xFF27A644);
    });

    test('all six provisional tag colours carry their exact hexes', () {
      expect(AppColors.tagBlue.toARGB32(), 0xFF5E6AD2);
      expect(AppColors.tagPurple.toARGB32(), 0xFF8B5CF0);
      expect(AppColors.tagGreen.toARGB32(), 0xFF27A644);
      expect(AppColors.tagYellow.toARGB32(), 0xFFD4A72C);
      expect(AppColors.tagOrange.toARGB32(), 0xFFD97B34);
      expect(AppColors.tagRed.toARGB32(), 0xFFD1484A);
    });

    test('the scrim is the canvas at 72% rather than a fourth literal', () {
      expect(
        AppColors.bgScrim.toARGB32(),
        AppColors.canvas.withValues(alpha: 0.72).toARGB32(),
      );
      expect(AppColors.bgScrim.a, closeTo(0.72, 0.005));
    });
  });

  group('semantic aliases', () {
    // Value equality only proves the hexes agree; the source-literal count below is
    // what proves they are the same constant and not a copy.
    test('aliases resolve to the base token the CSS points them at', () {
      expect(AppColors.bgPage, AppColors.canvas);
      expect(AppColors.bgCard, AppColors.surface1);
      expect(AppColors.bgMenu, AppColors.surface3);
      expect(AppColors.textBody, AppColors.ink);
      expect(AppColors.textTertiary, AppColors.inkSubtle);
      expect(AppColors.borderCard, AppColors.hairline);
      expect(AppColors.borderFocus, AppColors.primaryFocus);
      expect(AppColors.actionPrimaryBg, AppColors.primary);
      expect(AppColors.actionPrimaryFg, AppColors.onPrimary);
      expect(AppColors.textLink, AppColors.primary);
    });

    test('colors.dart declares no more literals than the CSS has base tokens', () {
      // 23 `--color-*` + 6 `--tag-*` in colors.css. Anything above this means an
      // alias was written as a copied hex instead of a reference.
      const baseTokensInCss = 29;

      final lines = File('lib/core/theme/colors.dart').readAsLinesSync();
      final literals = lines.where((line) => line.contains('0xFF')).length;

      expect(
        literals,
        lessThanOrEqualTo(baseTokensInCss),
        reason: 'an alias is repeating a hex instead of referencing its base',
      );
      // Guards the guard: a mistyped path or an empty read would make the bound
      // above pass trivially.
      expect(
        literals,
        greaterThan(0),
        reason: 'colors.dart was not actually read, so the bound proves nothing',
      );
    });
  });

  group('type roles', () {
    test('all 13 CSS roles are present, keyed by their CSS names', () {
      expect(AppType.roles.length, 13);
      expect(
        AppType.roles.keys,
        containsAll(<String>[
          'display-xl',
          'display-lg',
          'display-md',
          'headline',
          'card-title',
          'subhead',
          'body-lg',
          'body',
          'body-sm',
          'caption',
          'button',
          'eyebrow',
          'mono',
        ]),
      );
    });

    test('every role carries a family, size, weight, leading and tracking', () {
      AppType.roles.forEach((name, style) {
        expect(style.fontFamily, isNotNull, reason: '$name has no family');
        expect(style.fontSize, isNotNull, reason: '$name has no size');
        expect(style.fontWeight, isNotNull, reason: '$name has no weight');
        expect(style.height, isNotNull, reason: '$name has no leading');
        expect(style.letterSpacing, isNotNull, reason: '$name has no tracking');
      });
    });

    test('eyebrow is the one positively tracked role, display is negative', () {
      expect(AppType.roles['eyebrow']!.letterSpacing, greaterThan(0));
      expect(AppType.roles['display-xl']!.letterSpacing, lessThan(0));

      final positive = AppType.roles.entries
          .where((role) => role.value.letterSpacing! > 0)
          .map((role) => role.key);
      expect(positive, ['eyebrow']);
    });

    test('roles resolve to the families pubspec.yaml declares', () {
      expect(AppType.roles['display-xl']!.fontFamily, 'Inter');
      expect(AppType.roles['body']!.fontFamily, 'Inter');
      expect(AppType.roles['mono']!.fontFamily, 'JetBrainsMono');
    });

    test('displayApp continues the ramp at the app size, outside roles', () {
      expect(AppType.displayApp.fontSize, 44);
      expect(AppType.displayApp.fontWeight, AppType.displayMd.fontWeight);
      expect(AppType.displayApp.fontFamily, AppType.displayMd.fontFamily);
      // Both interpolated between display-md and display-lg at t = 0.25:
      // tracking -1.0 -> -1.8 gives -1.2, leading 1.15 -> 1.1 gives 1.1375.
      expect(AppType.displayApp.letterSpacing, -1.2);
      expect(AppType.displayApp.height, closeTo(1.1375, 0.005));
      expect(AppType.roles.values, isNot(contains(AppType.displayApp)));
    });
  });

  group('motion', () {
    test('the Result reveal and camera timings are named and restrained', () {
      expect(AppMotion.resultRouteReveal.inMilliseconds, 1500);
      expect(AppMotion.resultPinReveal.inMilliseconds, 120);
      expect(AppMotion.resultCameraFit.inMilliseconds, 320);
      expect(AppMotion.resultRouteRevealCurve, Curves.linear);
      expect(AppMotion.resultCameraFitCurve, AppMotion.easeStandard);
    });
    test('the four durations are exact', () {
      expect(AppMotion.instant.inMilliseconds, 80);
      expect(AppMotion.fast.inMilliseconds, 120);
      expect(AppMotion.base.inMilliseconds, 160);
      expect(AppMotion.slow.inMilliseconds, 240);
    });

    test('both easings carry the CSS control points', () {
      expect(AppMotion.easeStandard, const Cubic(0.4, 0, 0.2, 1));
      expect(AppMotion.easeOut, const Cubic(0, 0, 0.2, 1));
    });
  });

  group('theme', () {
    test('the theme is dark and painted on the canvas token', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.canvas);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.surface1);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    });

    test('no light theme is defined anywhere under lib/', () {
      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      final offenders = sources
          .where((file) => file.readAsStringSync().contains('Brightness.light'))
          .map((file) => file.path);
      expect(offenders, isEmpty, reason: 'a light theme was introduced');

      // Guards the guard: if the walk found nothing, `isEmpty` above is vacuous.
      final dark = sources
          .where((file) => file.readAsStringSync().contains('Brightness.dark'));
      expect(
        dark,
        isNotEmpty,
        reason: 'lib/ was not actually walked, so the check proves nothing',
      );
    });
  });
}
