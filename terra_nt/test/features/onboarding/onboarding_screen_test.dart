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

    expect(find.text('Step 1 of 15'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('onboarding-progress-fill'))).width,
        greaterThan(0));

    await moveTo(tester, key.currentState!, 14);

    expect(find.text('Step 15 of 15'), findsOneWidget);
    expect(find.text('Generate My Route'), findsOneWidget);
    // The fill drives to its new percentage over the step-card duration now
    // (V13), and `moveTo` pumps a single frame per step, so the last step's
    // drive is still running here.
    await tester.pump(OnboardingMotion.stepSlide);
    expect(tester.getSize(find.byKey(const ValueKey('onboarding-progress-fill'))).width,
        tester.getSize(find.byKey(const ValueKey('onboarding-progress-track'))).width);
  });

  testWidgets('shows the NT-specific badge only on steps 9 to 13', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    for (var step = 0; step < 15; step++) {
      await moveTo(tester, key.currentState!, step);
      expect(
        find.byType(AppPillBadge),
        step >= 9 && step <= 13 ? findsOneWidget : findsNothing,
        reason: 'step $step badge visibility',
      );
    }
  });

  testWidgets('gates the thirteen required answers and leaves two steps enabled', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);
    final gatedSteps = <int>[0, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14];

    for (final step in gatedSteps) {
      await moveTo(tester, key.currentState!, step);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('onboarding-next'))).onPressed,
          isNull, reason: 'step $step must be gated');
      key.currentState!.updateAnswers(answerFor(step));
      await tester.pump();
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('onboarding-next'))).onPressed,
          isNotNull, reason: 'step $step must enable after its answer');
    }

    for (final step in <int>[1, 10]) {
      await moveTo(tester, key.currentState!, step);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('onboarding-next'))).onPressed,
          isNotNull, reason: 'step $step is ungated');
    }
  });

  testWidgets('recording an answer does not advance; Next does', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    // Every step advances on Next only (V12): picking an option records it and
    // nothing else, however long the tree is left to settle.
    key.currentState!.updateAnswers(answerFor(0));
    await tester.pump(OnboardingMotion.stepSlide);
    expect(key.currentState!.currentStep, 0);

    key.currentState!.onNext();
    await tester.pump();
    expect(key.currentState!.currentStep, 1);
  });

  testWidgets('a second pick overwrites the answer without advancing', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    key.currentState!.updateAnswers(answerFor(0));
    key.currentState!.updateAnswers(const OnboardingAnswers(ageRange: '26–35'));
    await tester.pump(OnboardingMotion.stepSlide);
    expect(key.currentState!.currentStep, 0);
    expect(key.currentState!.answers.ageRange, '26–35');
  });

  testWidgets('back at step 0 exits and disposal mid-motion leaks nothing', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    var exited = false;
    await pumpOnboarding(tester, key: key, onExitToWelcome: () => exited = true);

    key.currentState!.updateAnswers(answerFor(0));
    key.currentState!.onBack();
    await tester.pump();
    expect(exited, isTrue);
    expect(key.currentState!.currentStep, 0);

    // Tearing the shell down while the 320 ms step-card motion is still running
    // must not leave a ticker behind.
    key.currentState!.onNext();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(OnboardingMotion.stepSlide);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-select and sliders still require Next', (tester) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    for (final step in <int>[1, 3, 10]) {
      await moveTo(tester, key.currentState!, step);
      key.currentState!.updateAnswers(answerFor(step));
      await tester.pump(OnboardingMotion.stepSlide);
      expect(key.currentState!.currentStep, step);
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
    expect(key.currentState!.answers.ageRange, '18_25');

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

    expect(find.text('Step 15 of 15'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-progress-track')), findsOneWidget);
    // The new last step is not NT-specific, so it carries no pill.
    expect(find.text('NT-specific'), findsNothing);
    expect(find.text('Generate My Route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

OnboardingAnswers answerFor(int step) => switch (step) {
  0 => const OnboardingAnswers(ageRange: '18_25'),
  2 => const OnboardingAnswers(companions: 'solo'),
  3 => const OnboardingAnswers(focus: ['nature']),
  4 => const OnboardingAnswers(vehicle: 'four_wd'),
  5 => const OnboardingAnswers(budget: 'budget'),
  6 => const OnboardingAnswers(accommodation: 'camping'),
  7 => const OnboardingAnswers(activityLevel: 'low'),
  8 => const OnboardingAnswers(region: 'top_end'),
  9 => const OnboardingAnswers(offRoadConfidence: 'low'),
  11 => const OnboardingAnswers(campingPreference: 'camping'),
  12 => const OnboardingAnswers(wildlifeInterest: 'interested'),
  13 => const OnboardingAnswers(offGridComfortable: true),
  14 => const OnboardingAnswers(
    startLocation: 'Darwin',
    endLocation: 'Alice Springs',
  ),
  _ => const OnboardingAnswers(),
};
