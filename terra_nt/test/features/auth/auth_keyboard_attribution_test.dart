import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/auth/create_account_screen.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/shared/map/terra_map.dart';

/// The emulator the defect was found on: 1080x2400 at 2.625, with the soft
/// keyboard covering the bottom 383 logical px.
const _phone = Size(411, 914);
const _keyboard = 383.0;

Future<void> _pump(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final view = tester.view;
  view.devicePixelRatio = 1;
  view.physicalSize = _phone;
  view.padding = const FakeViewPadding(top: 24, bottom: 24);
  view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          PreferencesStore(preferences: () async => preferences),
        ),
        authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: screen),
    ),
  );
  await tester.pump();

  // The keyboard opens after the screen is built, as on a device.
  view.viewInsets = const FakeViewPadding(bottom: _keyboard);
  await tester.pump();
}

/// The attribution may sit behind the keyboard; it must not sit on a control.
void _expectAttributionClearOf(WidgetTester tester, List<String> keys) {
  final attribution = find.text(cartoAttribution);
  final visibleTop = _phone.height - _keyboard;
  for (final element in attribution.evaluate()) {
    final rect = tester.getRect(find.byElementPredicate((e) => e == element));
    if (rect.top >= visibleTop) continue;
    for (final key in keys) {
      final control = tester.getRect(find.byKey(ValueKey(key)));
      expect(
        rect.overlaps(control),
        isFalse,
        reason: 'attribution $rect overlaps $key $control',
      );
    }
  }
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Create account: attribution stays off the form with the '
      'keyboard open', (tester) async {
    await _pump(tester, const CreateAccountScreen());

    _expectAttributionClearOf(tester, const [
      'create-account-sign-in',
      'create-account-submit',
    ]);
  });

  testWidgets('Login: attribution stays off the form with the keyboard open', (
    tester,
  ) async {
    await _pump(tester, const LoginScreen());

    _expectAttributionClearOf(tester, const [
      'login-submit',
      'login-google',
      'login-sign-up',
      'login-forgot-password',
    ]);
  });
}
