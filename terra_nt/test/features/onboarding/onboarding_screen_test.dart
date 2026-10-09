import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/onboarding_rules.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/features/onboarding/steps/onboarding_steps.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';
import 'package:terra_nt/shared/widgets/app_pill_badge.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    GlobalKey<OnboardingScreenState>? key,
    VoidCallback? onExitToWelcome,
    VoidCallback? onComplete,
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: OnboardingScreen(
          key: key,
          onExitToWelcome: onExitToWelcome,
          onComplete: onComplete,
        ),
      ),
    ),
  );

  OnboardingRoutePainter routePainter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byKey(const ValueKey('onboarding-route-reveal')),
              )
              .painter!
          as OnboardingRoutePainter;

  double revealedLength(WidgetTester tester) =>
      routePainter(tester).revealedPath
          .computeMetrics()
          .fold(0.0, (length, metric) => length + metric.length);

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

  testWidgets(
    'the map route and progress road reveal all steps forward and backward',
    (tester) async {
      final key = GlobalKey<OnboardingScreenState>();
      await pumpOnboarding(tester, key: key);
      await tester.pump(OnboardingMotion.stepSlide);
      final fullLength = const OnboardingRoutePainter(fraction: 1).revealedPath
          .computeMetrics()
          .single
          .length;

      for (final step in [
        ...List.generate(15, (i) => i),
        ...List.generate(14, (i) => 13 - i),
      ]) {
        await moveTo(tester, key.currentState!, step);
        await tester.pump(OnboardingMotion.stepSlide ~/ 2);
        final fraction = routePainter(tester).fraction;
        final fillWidth = tester
            .getSize(find.byKey(const ValueKey('onboarding-progress-fill')))
            .width;
        final trackWidth = tester
            .getSize(find.byKey(const ValueKey('onboarding-progress-track')))
            .width;
        expect(fraction, closeTo(fillWidth / trackWidth, 0.0001));
        await tester.pump(OnboardingMotion.stepSlide);
        expect(routePainter(tester).fraction, progressPercent(step) / 100);
        expect(
          revealedLength(tester),
          closeTo(fullLength * progressPercent(step) / 100, 0.1),
          reason: 'the painted path must follow step $step in both directions',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion paints each route state without a drive', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key, reduceMotion: true);
    await tester.pump();
    expect(routePainter(tester).fraction, 0.07);
    await moveTo(tester, key.currentState!, 14);
    expect(routePainter(tester).fraction, 1);
    await moveTo(tester, key.currentState!, 8);
    expect(routePainter(tester).fraction, 0.6);
    final length = revealedLength(tester);
    await tester.pump(const Duration(milliseconds: 1));
    expect(revealedLength(tester), length);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a new question fades above a fixed footer; a pick does not replay it',
    (tester) async {
      final key = GlobalKey<OnboardingScreenState>();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(
              key: key,
              stepBuilder: (context, data) =>
                  SizedBox(height: data.step == 0 ? 200 : 80),
            ),
          ),
        ),
      );
      // The progress car has a repeating bob; wait for the finite card motion,
      // rather than waiting for every animation on the page to stop forever.
      await tester.pump(OnboardingMotion.stepSlide);
      final card = find.byKey(const ValueKey('onboarding-step-card'));
      final footer = find.byKey(const ValueKey('onboarding-next'));
      final before = tester.getSize(card).height;
      final footerRect = tester.getRect(footer);
      double opacity() => tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byKey(
                    ValueKey(
                      'onboarding-step-${key.currentState!.currentStep}',
                    ),
                  ),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      key.currentState!.updateAnswers(answerFor(0));
      await tester.pump();
      expect(opacity(), 1, reason: 'selection stays on the current question');
      key.currentState!.onNext();
      await tester.pump();
      expect(opacity(), 0);
      await tester.pump(OnboardingMotion.stepSlide ~/ 4);
      expect(tester.getRect(footer), footerRect);
      expect(opacity(), greaterThan(0));
      expect(opacity(), lessThan(1));
      await tester.pump(OnboardingMotion.stepSlide);
      final after = tester.getSize(card).height;
      expect(after, lessThan(before));
      expect(tester.getRect(footer), footerRect);
      expect(opacity(), 1);
      key.currentState!.onBack();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('renders the endpoints of counter, progress, and footer copy', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await pumpOnboarding(tester, key: key);

    expect(find.text('Step 1 of 15'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('onboarding-progress-fill')))
          .width,
      greaterThan(0),
    );

    await moveTo(tester, key.currentState!, 14);

    expect(find.text('Step 15 of 15'), findsOneWidget);
    expect(find.text('Generate My Route'), findsOneWidget);
    // The fill drives to its new percentage over the step-card duration now
    // (V13), and `moveTo` pumps a single frame per step, so the last step's
    // drive is still running here.
    await tester.pump(OnboardingMotion.stepSlide);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('onboarding-progress-fill')))
          .width,
      tester
          .getSize(find.byKey(const ValueKey('onboarding-progress-track')))
          .width,
    );
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

  testWidgets(
    'gates the thirteen required answers and leaves two steps enabled',
    (tester) async {
      final key = GlobalKey<OnboardingScreenState>();
      await pumpOnboarding(tester, key: key);
      final gatedSteps = <int>[0, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14];

      for (final step in gatedSteps) {
        await moveTo(tester, key.currentState!, step);
        expect(
          tester
              .widget<AppButton>(find.byKey(const ValueKey('onboarding-next')))
              .onPressed,
          isNull,
          reason: 'step $step must be gated',
        );
        key.currentState!.updateAnswers(answerFor(step));
        await tester.pump();
        expect(
          tester
              .widget<AppButton>(find.byKey(const ValueKey('onboarding-next')))
              .onPressed,
          isNotNull,
          reason: 'step $step must enable after its answer',
        );
      }

      for (final step in <int>[1, 10]) {
        await moveTo(tester, key.currentState!, step);
        expect(
          tester
              .widget<AppButton>(find.byKey(const ValueKey('onboarding-next')))
              .onPressed,
          isNotNull,
          reason: 'step $step is ungated',
        );
      }
    },
  );

  testWidgets('recording an answer does not advance; Next does', (
    tester,
  ) async {
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
    await pumpOnboarding(
      tester,
      key: key,
      onExitToWelcome: () => exited = true,
    );

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

  testWidgets('answers survive back navigation and final next completes', (
    tester,
  ) async {
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

  testWidgets('renders shell chrome at 360px without layout exceptions', (
    tester,
  ) async {
    final key = GlobalKey<OnboardingScreenState>();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpOnboarding(tester, key: key);
    await moveTo(tester, key.currentState!, 14);

    expect(find.text('Step 15 of 15'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-progress-track')),
      findsOneWidget,
    );
    // The new last step is not NT-specific, so it carries no pill.
    expect(find.text('NT-specific'), findsNothing);
    expect(find.text('Generate My Route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'all 15 questions keep the button fixed at 360px and ${scale}x text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 640);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container
            .read(onboardingNotifierProvider.notifier)
            .setAnswers(
              const OnboardingAnswers(
                ageRange: '26_35',
                companions: 'couple',
                focus: ['nature'],
                vehicle: 'four_wd',
                budget: 'mid_range',
                accommodation: 'hotel',
                activityLevel: 'medium',
                region: 'full_nt',
                offRoadConfidence: 'medium',
                campingPreference: 'mixed',
                wildlifeInterest: 'interested',
                offGridComfortable: false,
                startLocation: 'Darwin',
                endLocation: 'Alice Springs',
              ),
            );
        var completed = false;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: OnboardingScreen(
                stepBuilder: onboardingStepBuilder,
                onComplete: () => completed = true,
              ),
            ),
          ),
        );
        final next = find.byKey(const ValueKey('onboarding-next'));
        final rect = tester.getRect(next);
        expect(rect.bottom, lessThan(640 - 48));
        for (var step = 0; step < 15; step++) {
          expect(container.read(onboardingNotifierProvider).currentStep, step);
          expect(tester.getRect(next), rect, reason: 'step $step arrival');
          await tester.pump(OnboardingMotion.stepSlide ~/ 2);
          expect(tester.getRect(next), rect, reason: 'step $step transition');
          await tester.pump(const Duration(seconds: 1));
          expect(tester.getRect(next), rect, reason: 'step $step settled');
          // Every last answer remains reachable when the question scrolls.
          final scroll = find.byKey(ValueKey('onboarding-scroll-$step'));
          final scrollable = find.descendant(
            of: scroll,
            matching: find.byType(Scrollable),
          );
          final position = tester.state<ScrollableState>(scrollable).position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();
          expect(tester.getRect(next), rect, reason: 'step $step scrolled');
          expect(tester.takeException(), isNull, reason: 'step $step');
          await tester.tap(next);
          await tester.pump();
        }
        expect(completed, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.binding.transientCallbackCount, 0);
      },
    );
  }

  for (final vehicle in ['standard_car', 'four_wd']) {
    testWidgets('Next and both Back controls follow the $vehicle steps', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setAnswers(
        OnboardingAnswers(vehicle: vehicle, region: 'top_end'),
      );
      notifier.setStep(8);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(stepBuilder: onboardingStepBuilder),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pump(const Duration(seconds: 1));
      final expectedStep = vehicle == 'four_wd' ? 9 : 10;
      expect(
        container.read(onboardingNotifierProvider).currentStep,
        expectedStep,
      );
      expect(
        find.text('How confident are you driving a 4x4 off-road?'),
        vehicle == 'four_wd' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(vehicle == 'four_wd' ? 'Step 10 of 15' : 'Step 10 of 14'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-back')));
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(onboardingNotifierProvider).currentStep, 8);
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pump(const Duration(seconds: 1));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(onboardingNotifierProvider).currentStep, 8);
      expect(tester.takeException(), isNull);
    });
  }
}

OnboardingAnswers answerFor(int step) => (switch (step) {
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
}).copyWith(vehicle: step >= 4 ? 'four_wd' : null);
