import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/itinerary/widgets/result_empty_state.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/shared/widgets/journey_scene.dart';

void main() {
  testWidgets(
    'a fresh container shows the empty state and Plan My Route starts onboarding',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: ResultScreen(launcher: (_) async => true),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No route yet'), findsOneWidget);
      expect(
        find.text(
          "Answer a few questions and we'll plan a route across the "
          'Territory.',
        ),
        findsOneWidget,
      );
      expect(find.text('Plan My Route'), findsOneWidget);
      expect(find.byType(JourneyScene), findsOneWidget);
      expect(find.byKey(const ValueKey('result-map')), findsNothing);
      expect(find.byKey(const ValueKey('result-sheet')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('result-empty-plan-my-route')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Step 1 of 15'), findsOneWidget);
    },
  );

  testWidgets('the saved trip action follows the saved routes state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          PreferencesStore(preferences: () async => preferences),
        ),
        authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    var opened = 0;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: ResultScreen(onOpenSavedRoutes: () => opened++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('result-empty-open-saved-routes'));
    expect(find.text('Open a saved route'), findsOneWidget);
    await tester.ensureVisible(action);
    await tester.tap(action);
    expect(opened, 1);
    await container
        .read(savedRoutesNotifierProvider.notifier)
        .clearForDeleteAccount();
    await tester.pumpAndSettle();
    expect(action, findsNothing);
    expect(find.text('No route yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final height in [640.0, 400.0]) {
    testWidgets('empty Plan actions are reachable at 360x$height and 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(360, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var planned = 0;
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              padding: EdgeInsets.only(top: 24, bottom: 34),
            ),
            child: Scaffold(
              body: ResultEmptyState(
                onPlanMyRoute: () => planned++,
                onOpenSavedRoutes: () => opened++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(JourneyScene)).bottom,
        lessThan(tester.getRect(find.text('No route yet')).top),
      );
      for (final key in [
        'result-empty-plan-my-route',
        'result-empty-open-saved-routes',
      ]) {
        final action = find.byKey(ValueKey(key));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(height - 34));
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(planned, 1);
      expect(opened, 1);
    });
  }
}
