import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/features/profile/language/language_screen.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/settings_row.dart';

void main() {
  Future<void> pumpLanguage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const LanguageScreen()),
    );
  }

  testWidgets('lists only English and renders it as selected', (tester) async {
    await pumpLanguage(tester);

    expect(find.byType(SettingsRow), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byKey(const ValueKey('language-selected')), findsOneWidget);
    expect(
      tester.widget<SettingsRow>(find.byType(SettingsRow)).trailing,
      isA<AppIcon>(),
    );
  });

  testWidgets('tapping English is a no-op', (tester) async {
    await pumpLanguage(tester);
    final before = tester.widget<SettingsRow>(find.byType(SettingsRow));

    await tester.tap(find.text('English'));
    await tester.pump();

    final after = tester.widget<SettingsRow>(find.byType(SettingsRow));
    expect(after.label, before.label);
    expect(after.trailing, isNotNull);
    expect(find.byKey(const ValueKey('language-screen')), findsOneWidget);
  });

  testWidgets('back button returns to Profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (_) => settings.name == '/language'
                ? const LanguageScreen()
                : const Scaffold(body: Text('Profile')),
            settings: settings,
          ),
          initialRoute: '/',
        ),
      ),
    );
    Navigator.of(tester.element(find.text('Profile'))).push<void>(
      MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('language-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('language-screen')), findsNothing);
  });

  testWidgets('fits at 360px without a layout exception', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpLanguage(tester);
    expect(tester.takeException(), isNull);
  });
}
