import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/app/app_launch.dart';
import 'package:terra_nt/app/routes.dart';
import 'package:terra_nt/app/screen_routes.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/loading/loading_screen.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';

void main() {
  Future<void> pumpLaunch(
    WidgetTester tester, {
    required bool onboardingDone,
  }) async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.sessionKey: jsonEncode({
        'email': 'returning@example.com',
      }),
      PreferencesStore.onboardingDoneKey: onboardingDone,
    });
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesStore(preferences: () async => preferences);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
        child: MaterialApp(theme: AppTheme.dark, home: const AppLaunch()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('first launch opens onboarding after loading persisted state', (
    tester,
  ) async {
    await pumpLaunch(tester, onboardingDone: false);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('returning user opens Explore from persisted onboarding state', (
    tester,
  ) async {
    await pumpLaunch(tester, onboardingDone: true);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
  });

  testWidgets('loading completion opens Result without AppLaunch taking over', (
    tester,
  ) async {
    await pumpLaunch(tester, onboardingDone: false);

    final onboardingContext = tester.element(find.byType(OnboardingScreen));
    Navigator.of(onboardingContext)
        .pushReplacement(rootScreenRoute(AppRoute.loading));
    await tester.pump();
    expect(find.byType(LoadingScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 7000));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);
  });
}
