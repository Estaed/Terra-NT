import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';
import 'package:terra_nt/shared/widgets/app_chip.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/app_pill_badge.dart';
import 'package:terra_nt/shared/widgets/app_text_input.dart';
import 'package:terra_nt/shared/widgets/placeholder_tile.dart';
import 'package:terra_nt/shared/widgets/settings_row.dart';
import 'package:terra_nt/shared/widgets/tag_dot.dart';

/// No layout exception at 360px width — every widget variant, at its longest
/// supported label, must pump clean (Part 2 verification rule 5).
void main() {
  Future<void> pumpAt360(WidgetTester tester, Widget child) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  final variants = <String, Widget>{
    'AppButton primary lg fullWidth': AppButton(
      onPressed: () {},
      fullWidth: true,
      iconLeft: LucideIcons.map,
      child: const Text('Save this route'),
    ),
    'AppButton secondary md': AppButton(
      onPressed: () {},
      variant: AppButtonVariant.secondary,
      size: AppButtonSize.md,
      child: const Text('Cancel'),
    ),
    'AppButton disabled': const AppButton(onPressed: null, child: Text('Disabled')),
    'AppTextInput with error': const AppTextInput(
      label: 'Email address',
      placeholder: 'you@example.com',
      errorText: 'This field could not be validated',
    ),
    'AppIcon': const AppIcon(LucideIcons.grip_vertical),
    'AppChip selected with icon': const AppChip(
      label: 'Aboriginal culture',
      selected: true,
      icon: LucideIcons.check,
    ),
    'AppChip unselected': const AppChip(label: 'History', selected: false),
    'AppPillBadge': const AppPillBadge(label: 'NT-specific highlight'),
    'TagDot bare': const TagDot(color: Colors.teal, label: 'Waterfalls and gorges'),
    'TagDot bordered': const TagDot(
      color: Colors.teal,
      label: 'Waterfalls and gorges',
      bordered: true,
    ),
    'PlaceholderTile.square': const PlaceholderTile.square(size: 76),
    'PlaceholderTile.hero': const PlaceholderTile.hero(),
    'SettingsRow full': SettingsRow(
      leading: const AppIcon(LucideIcons.map),
      label: 'Offline maps for the whole Northern Territory region',
      subtitle: 'Downloaded 2 days ago and ready for offline use',
      value: 'English',
      showChevron: true,
      onTap: () {},
    ),
    'SettingsRow non-interactive': const SettingsRow(label: 'Language'),
  };

  for (final entry in variants.entries) {
    testWidgets('${entry.key} renders at 360px without a layout exception',
        (tester) async {
      await pumpAt360(tester, entry.value);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
