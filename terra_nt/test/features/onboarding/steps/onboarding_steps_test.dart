import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/features/onboarding/steps/onboarding_steps.dart';

void main() {
  testWidgets('renders every onboarding question and option label', (
    tester,
  ) async {
    const questions = <String>[
      'Which age range are you in?',
      'How many days is your trip?',
      'Who are you traveling with?',
      "What's the main focus of this trip?",
      'What are you traveling in?',
      "What's your budget?",
      'Where do you want to stay?',
      "What's your physical activity level?",
      'Which region do you want to focus on?',
      'How detailed should your itinerary be?',
      'How confident are you driving a 4x4 off-road?',
      'How well do you handle extreme heat?',
      'Camping under the stars, or resort comfort?',
      'How interested are you in spotting wildlife?',
      'Comfortable in remote areas with no phone signal?',
    ];
    const optionsByStep = <int, List<String>>{
      0: ['18–25', '26–35', '36–50', '50+'],
      2: ['Solo', 'Couple', 'Family', 'Friends'],
      3: ['Nature', 'Aboriginal Culture', 'Adventure', 'Relaxation'],
      4: ['4x4', 'Campervan', 'Standard Car', 'Guided Tour'],
      5: ['Budget', 'Mid-range', 'Luxury'],
      6: ['Camping', 'Motel/Cabin', 'Hotel'],
      7: ['Low', 'Medium', 'High'],
      8: ['Top End', 'Red Centre', 'Full NT'],
      9: [
        'Just the highlights',
        'A short list of must-see stops per day',
        'Detailed hourly plan',
        'Hour-by-hour schedule with timing',
      ],
      10: ['Low', 'Medium', 'High'],
      12: ['Camping all the way', 'Bit of both', 'Resort comfort'],
      13: ['Not fussed', 'Interested', 'Big draw'],
      14: [
        "Yes, I'm prepared to go off-grid",
        'Comfortable with long stretches out of range',
        "I'd prefer to stay connected",
        'Would rather stick to areas with signal',
      ],
    };

    for (var step = 0; step < questions.length; step++) {
      await pumpStep(tester, step);
      expect(find.text(questions[step]), findsOneWidget);
    }

    for (final entry in optionsByStep.entries) {
      await pumpStep(tester, entry.key);
      for (final option in entry.value) {
        expect(find.text(option), findsOneWidget, reason: option);
      }
    }
  });

  testWidgets('single-select writes its configured answer', (tester) async {
    final answers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(tester, 6, onChanged: (value) => answers.add(value));

    await tester.tap(find.text('Motel/Cabin'));
    expect(answers.last.accommodation, 'Motel/Cabin');
  });

  testWidgets('multi-select toggles focus and removes the final selection', (
    tester,
  ) async {
    final answers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(tester, 3, onChanged: (value) => answers.add(value));

    await tester.tap(find.text('Nature'));
    expect(answers.last.focus, ['Nature']);
    await pumpStep(
      tester,
      3,
      initial: answers.last,
      onChanged: (value) => answers.add(value),
    );
    await tester.tap(find.text('Nature'));
    expect(answers.last.focus, isEmpty);
  });

  testWidgets('sliders use their configured ranges and update readout', (
    tester,
  ) async {
    final answers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(tester, 1, onChanged: (value) => answers.add(value));
    expect(find.text('7 days'), findsOneWidget);
    final slider = find.byKey(const ValueKey('onboarding-slider'));
    expect(tester.widget<Slider>(slider).min, 1);
    expect(tester.widget<Slider>(slider).max, 14);
    await tester.drag(slider, const Offset(-1000, 0));
    expect(answers.last.days, 1);

    await pumpStep(tester, 11, onChanged: (value) => answers.add(value));
    expect(find.text("It's fine either way"), findsOneWidget);
    expect(tester.widget<Slider>(slider).min, 1);
    expect(tester.widget<Slider>(slider).max, 5);
  });

  testWidgets('detail and remote choices update only their intended values', (
    tester,
  ) async {
    final initial = const OnboardingAnswers(ageRange: '18–25', days: 4);
    final answers = <OnboardingAnswers>[initial];
    await pumpStep(
      tester,
      9,
      initial: initial,
      onChanged: (value) => answers.add(value),
    );
    await tester.tap(find.text('Detailed hourly plan'));
    expect(answers.last.detailed, isTrue);
    expect(answers.last.ageRange, initial.ageRange);
    expect(answers.last.days, initial.days);

    await pumpStep(
      tester,
      14,
      initial: answers.last,
      onChanged: (value) => answers.add(value),
    );
    await tester.tap(find.text("I'd prefer to stay connected"));
    expect(answers.last.offGridComfortable, isFalse);
  });

  testWidgets('the tallest step fits at 360px without an exception', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpStep(tester, 14);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpStep(
  WidgetTester tester,
  int step, {
  OnboardingAnswers initial = const OnboardingAnswers(),
  ValueChanged<OnboardingAnswers>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => onboardingStepBuilder(
            context,
            OnboardingStepData(
              step: step,
              answers: initial,
              updateAnswers: onChanged ?? (_) {},
              selectAndAdvance: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
