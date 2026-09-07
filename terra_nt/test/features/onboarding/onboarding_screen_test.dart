import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';
import 'package:terra_nt/shared/widgets/app_pill_badge.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    GlobalKey<OnboardingScreenState>? key,
    VoidCallback? onExitToWelcome,
    VoidCallback? onComplete,
  }) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: OnboardingScreen(
          key: key,
          onExitToWelcome: onExitToWelcome,
          onComplete: onComplete,
        ),
      ),
    ),
  );

  Future<void> moveTo(
    WidgetTester tester,
    OnboardingScreenState state,
    int target,
  ) async {
    while (state.currentStep > target) {
      state.onBack();
      await tester.pump();
    }
    while (state.currentStep < target) {
      state.updateAnswers(answerFor(state.currentStep));
      state.onNext();
      await tester.pump();
    }
  }

  testWidgets('renders the endpoints of counter, progress, and footer copy', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    expect(find.text('1/15'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('onboarding-progress-fill'))).width,
        greaterThan(0));

    await moveTo(tester, key.currentState!, 14);

    expect(find.text('15/15'), findsOneWidget);
    expect(find.text('Generate My Route'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('onboarding-progress-fill'))).width,
        tester.getSize(find.byKey(const ValueKey('onboarding-progress-track'))).width);
  });

  testWidgets('shows the NT-specific badge only on the final five steps', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    for (var step = 0; step < 15; step++) {
      await moveTo(tester, key.currentState!, step);
      expect(find.byType(AppPillBadge), step >= 10 ? findsOneWidget : findsNothing);
    }
  });

  testWidgets('gates the twelve required answers and leaves three steps enabled', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);
    final gatedSteps = <int>[0, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14];

    for (final step in gatedSteps) {
      await moveTo(tester, key.currentState!, step);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('onboarding-next'))).onPressed,
          isNull, reason: 'step $step must be gated');
      key.currentState!.updateAnswers(answerFor(step));
      await tester.pump();
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('onboarding-next'))).onPressed,
          isNotNull, reason: 'step $step must enable after its answer');
    }

    for (final step in <int>[1, 9, 11]) {
      await moveTo(tester, key.currentState!, step);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('onboarding-next'))).onPressed,
          isNotNull, reason: 'step $step is ungated');
    }
  });

  testWidgets('single-select advances at exactly 380ms', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    key.currentState!.selectAndAdvance(answerFor(0));
    await tester.pump(const Duration(milliseconds: 379));
    expect(key.currentState!.currentStep, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(key.currentState!.currentStep, 1);
  });

  testWidgets('a second pick restarts rather than queues auto-advance', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    key.currentState!.selectAndAdvance(answerFor(0));
    await tester.pump(const Duration(milliseconds: 100));
    key.currentState!.selectAndAdvance(const OnboardingAnswers(ageRange: '26–35'));
    await tester.pump(const Duration(milliseconds: 379));
    expect(key.currentState!.currentStep, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(key.currentState!.currentStep, 1);
    await tester.pump(OnboardingMotion.autoAdvance);
    expect(key.currentState!.currentStep, 1);
  });

  testWidgets('back and disposal cancel a pending advance', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    var exited = false;
    await pumpOnboarding(tester, key: key, onExitToWelcome: () => exited = true);

    key.currentState!.selectAndAdvance(answerFor(0));
    key.currentState!.onBack();
    await tester.pump(OnboardingMotion.autoAdvance);
    expect(exited, isTrue);
    expect(key.currentState!.currentStep, 0);

    key.currentState!.selectAndAdvance(answerFor(0));
    expect(key.currentState!.hasPendingAutoAdvance, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(OnboardingMotion.autoAdvance);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-select and sliders do not schedule auto-advance', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    for (final step in <int>[1, 3, 11]) {
      await moveTo(tester, key.currentState!, step);
      key.currentState!.selectAndAdvance(answerFor(step));
      await tester.pump(OnboardingMotion.autoAdvance);
      expect(key.currentState!.currentStep, step);
      expect(key.currentState!.hasPendingAutoAdvance, isFalse);
    }
  });

  testWidgets('answers survive back navigation and final next completes', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    var completed = false;
    await pumpOnboarding(tester, key: key, onComplete: () => completed = true);

    key.currentState!.updateAnswers(answerFor(0));
    key.currentState!.onNext();
    await tester.pump();
    key.currentState!.onBack();
    await tester.pump();
    expect(key.currentState!.answers.ageRange, '18–25');

    await moveTo(tester, key.currentState!, 14);
    key.currentState!.updateAnswers(answerFor(14));
    key.currentState!.onNext();
    expect(completed, isTrue);
  });

  testWidgets('renders shell chrome at 360px without layout exceptions', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpOnboarding(tester, key: key);
    await moveTo(tester, key.currentState!, 14);

    expect(find.text('15/15'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-progress-track')), findsOneWidget);
    expect(find.text('NT-specific'), findsOneWidget);
    expect(find.text('Generate My Route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

OnboardingAnswers answerFor(int step) => switch (step) {
  0 => const OnboardingAnswers(ageRange: '18–25'),
  2 => const OnboardingAnswers(companions: 'Solo'),
  3 => const OnboardingAnswers(focus: ['Nature']),
  4 => const OnboardingAnswers(vehicle: '4x4'),
  5 => const OnboardingAnswers(budget: 'Budget'),
  6 => const OnboardingAnswers(accommodation: 'Camping'),
  7 => const OnboardingAnswers(activityLevel: 'Low'),
  8 => const OnboardingAnswers(region: 'Top End'),
  10 => const OnboardingAnswers(offRoadConfidence: 'Low'),
  12 => const OnboardingAnswers(campingPreference: 'Camping all the way'),
  13 => const OnboardingAnswers(wildlifeInterest: 'Interested'),
  14 => const OnboardingAnswers(offGridComfortable: true),
  _ => const OnboardingAnswers(),
};
