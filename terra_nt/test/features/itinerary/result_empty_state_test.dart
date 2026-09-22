import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';

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
      expect(find.byKey(const ValueKey('result-map')), findsNothing);
      expect(find.byKey(const ValueKey('result-sheet')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('result-empty-plan-my-route')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('1/15'), findsOneWidget);
    },
  );
}
