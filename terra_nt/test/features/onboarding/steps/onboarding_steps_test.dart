import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/typography.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/seed/onboarding_options.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/features/onboarding/steps/onboarding_steps.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:terra_nt/shared/widgets/entrance.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';

void main() {
  testWidgets('concrete options have one neutral leading recognition icon', (
    tester,
  ) async {
    const iconsByStep = {
      3: {
        'Nature': LucideIcons.tree_pine,
        'Aboriginal Culture': LucideIcons.landmark,
        'Adventure': LucideIcons.mountain,
        'Relaxation': LucideIcons.waves_horizontal,
      },
      4: {
        '4x4': LucideIcons.car_front,
        'Campervan': LucideIcons.caravan,
        'Standard Car': LucideIcons.car,
        'Guided Tour': LucideIcons.bus_front,
      },
      6: {
        'Camping': LucideIcons.tent,
        'Motel/Cabin': LucideIcons.house,
        'Hotel': LucideIcons.hotel,
      },
      11: {
        'Camping all the way': LucideIcons.tent,
        'Bit of both': LucideIcons.bed_double,
        'Resort comfort': LucideIcons.hotel,
      },
    };
    for (final step in iconsByStep.entries) {
      await pumpStep(tester, step.key);
      for (final option in step.value.entries) {
        final label = find.text(option.key);
        final row = find
            .ancestor(of: label, matching: find.byType(GestureDetector))
            .first;
        final cue = find.descendant(
          of: row,
          matching: find.byWidgetPredicate(
            (widget) => widget is AppIcon && widget.icon == option.value,
          ),
        );
        expect(cue, findsOneWidget, reason: option.key);
        expect(tester.widget<AppIcon>(cue).color, AppColors.inkMuted);
        expect(tester.getRect(cue).right, lessThan(tester.getRect(label).left));
        expect(
          find.descendant(of: row, matching: find.byType(AppIcon)),
          findsNWidgets(2),
          reason: 'one recognition cue plus the existing selection check',
        );
      }
    }
  });

  testWidgets('abstract questions keep only their selection checks', (
    tester,
  ) async {
    for (final step in [0, 1, 2, 5, 7, 9, 10, 12, 13]) {
      await pumpStep(tester, step);
      final icons = tester.widgetList<AppIcon>(find.byType(AppIcon));
      expect(
        icons.where((icon) => icon.icon != LucideIcons.check),
        isEmpty,
        reason: 'step $step stays text-only',
      );
    }
  });

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
      'How confident are you driving a 4x4 off-road?',
      'How well do you handle extreme heat?',
      'Camping under the stars, or resort comfort?',
      'How interested are you in spotting wildlife?',
      'Comfortable in remote areas with no phone signal?',
      'Where does your trip start and end?',
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
      9: ['Low', 'Medium', 'High'],
      11: ['Camping all the way', 'Bit of both', 'Resort comfort'],
      12: ['Not fussed', 'Interested', 'Big draw'],
      13: [
        "Yes, I'm prepared to go off-grid",
        'Comfortable with long stretches out of range',
        "I'd prefer to stay connected",
        'Would rather stick to areas with signal',
      ],
      14: ['Start', 'End', 'Choose a starting point', 'Choose an end point'],
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
    expect(answers.last.accommodation, 'motel_cabin');
  });

  testWidgets(
    'region pictures and examples keep keys and accessible selection',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var answers = const OnboardingAnswers(days: 4, vehicle: 'four_wd');

      for (final option in regionOptions) {
        await pumpStep(
          tester,
          8,
          initial: answers,
          onChanged: (next) => answers = next,
        );
        final card = find.byKey(ValueKey('onboarding-region-${option.key}'));
        final image = tester.widget<Image>(
          find.descendant(of: card, matching: find.byType(Image)),
        );
        expect((image.image as AssetImage).assetName, option.imageAsset);
        expect(find.text(option.description!), findsOneWidget);
        await tester.ensureVisible(card);
        await tester.tap(card);
        expect(answers.region, option.key);
        expect(answers.days, 4);
        expect(answers.vehicle, 'four_wd');
        await pumpStep(tester, 8, initial: answers);

        for (final other in regionOptions) {
          final node = tester.getSemantics(
            find.byKey(ValueKey('onboarding-region-${other.key}')),
          );
          expect(node.label, '${other.label} — ${other.description}');
          expect(node.flagsCollection.isChecked, isNot(CheckedState.none));
          expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
          expect(
            node.flagsCollection.isChecked,
            other.key == option.key
                ? CheckedState.isTrue
                : CheckedState.isFalse,
          );
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
        }
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('multi-select toggles focus and removes the final selection', (
    tester,
  ) async {
    final answers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(tester, 3, onChanged: (value) => answers.add(value));

    await tester.tap(find.text('Nature'));
    expect(answers.last.focus, ['nature']);
    await pumpStep(
      tester,
      3,
      initial: answers.last,
      onChanged: (value) => answers.add(value),
    );
    await tester.tap(find.text('Nature'));
    expect(answers.last.focus, isEmpty);
  });

  testWidgets('picking Couple stores couple; Nature and Adventure store keys', (
    tester,
  ) async {
    final companionAnswers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(
      tester,
      2,
      onChanged: (value) => companionAnswers.add(value),
    );
    await tester.tap(find.text('Couple'));
    expect(companionAnswers.last.companions, 'couple');

    final focusAnswers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(tester, 3, onChanged: (value) => focusAnswers.add(value));
    await tester.tap(find.text('Nature'));
    await pumpStep(
      tester,
      3,
      initial: focusAnswers.last,
      onChanged: (value) => focusAnswers.add(value),
    );
    await tester.tap(find.text('Adventure'));
    expect(focusAnswers.last.focus, ['nature', 'adventure']);
  });

  testWidgets('going back and forward re-shows picked labels as selected', (
    tester,
  ) async {
    final answers = <OnboardingAnswers>[const OnboardingAnswers()];
    await pumpStep(tester, 6, onChanged: (value) => answers.add(value));
    await tester.tap(find.text('Hotel'));
    expect(answers.last.accommodation, 'hotel');

    await pumpStep(tester, 6, initial: answers.last);
    final row = find
        .ancestor(
          of: find.text('Hotel'),
          matching: find.byType(GestureDetector),
        )
        .first;
    expect(
      find.descendant(of: row, matching: find.byIcon(LucideIcons.check)),
      findsOneWidget,
    );
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
    // The value bubble is gone (22a item 3); the readout above the track is the
    // only place the number is shown.
    expect(tester.widget<Slider>(slider).label, isNull);
    await tester.drag(slider, const Offset(-1000, 0));
    expect(answers.last.days, 1);

    await pumpStep(tester, 10, onChanged: (value) => answers.add(value));
    expect(find.text("It's fine either way"), findsOneWidget);
    expect(tester.widget<Slider>(slider).min, 1);
    expect(tester.widget<Slider>(slider).max, 5);
  });

  testWidgets('slider semantics speak each days and heat readout', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    SemanticsData sliderData() => find.semantics
        .byFlag(SemanticsFlag.isSlider)
        .evaluate()
        .single
        .getSemanticsData();
    for (var days = 1; days <= 14; days++) {
      await pumpStep(tester, 1, initial: OnboardingAnswers(days: days));
      final node = sliderData();
      expect(node.value, '$days days');
      if (days < 14) expect(node.increasedValue, '${days + 1} days');
      if (days > 1) expect(node.decreasedValue, '${days - 1} days');
    }
    for (var heat = 1; heat <= 5; heat++) {
      await pumpStep(tester, 10, initial: OnboardingAnswers(heat: heat));
      final node = sliderData();
      final display = tester.widget<Text>(
        find.byKey(const ValueKey('onboarding-slider-readout')),
      );
      expect(node.value, display.data);
      expect(node.value, heatLabels[heat - 1]);
      if (heat < 5) expect(node.increasedValue, heatLabels[heat]);
      if (heat > 1) expect(node.decreasedValue, heatLabels[heat - 2]);
    }
    semantics.dispose();
  });

  testWidgets(
    'heat sentences stay below the question and days readout in size',
    (tester) async {
      final readout = find.byKey(const ValueKey('onboarding-slider-readout'));
      await pumpStep(tester, 1);
      final daysStyle = tester.widget<Text>(readout).style!;
      expect(daysStyle.fontSize, AppType.displayMd.fontSize);
      await pumpStep(tester, 10);
      final heatStyle = tester.widget<Text>(readout).style!;
      final questionStyle = tester
          .widget<Text>(find.text('How well do you handle extreme heat?'))
          .style!;
      expect(heatStyle.fontSize, AppType.body.fontSize);
      expect(heatStyle.fontSize, lessThan(daysStyle.fontSize!));
      expect(heatStyle.fontSize, lessThan(questionStyle.fontSize!));
      for (final label in ['Prefer cool weather', 'Thrives in the heat']) {
        expect(
          tester.widget<Text>(find.text(label)).style!.color,
          AppColors.inkMuted,
        );
      }
      await pumpStep(tester, 3);
      expect(
        tester.widget<Text>(find.text('Select all that apply')).style!.color,
        AppColors.inkMuted,
      );
    },
  );

  testWidgets('remote and location steps update only their intended values', (
    tester,
  ) async {
    const initial = OnboardingAnswers(ageRange: '18–25', days: 4);
    final answers = <OnboardingAnswers>[initial];
    await pumpStep(
      tester,
      13,
      initial: initial,
      onChanged: (value) => answers.add(value),
    );
    await tester.tap(find.text("I'd prefer to stay connected"));
    expect(answers.last.offGridComfortable, isFalse);
    expect(answers.last.ageRange, initial.ageRange);
    expect(answers.last.days, initial.days);

    await pumpStep(
      tester,
      14,
      initial: answers.last,
      onChanged: (value) => answers.add(value),
    );
    await chooseLocation(tester, 'onboarding-start-picker', 'Darwin');
    expect(answers.last.startLocation, 'Darwin');
    await pumpStep(
      tester,
      14,
      initial: answers.last,
      onChanged: (value) => answers.add(value),
    );
    await chooseLocation(tester, 'onboarding-end-picker', 'Alice Springs');
    expect(answers.last.endLocation, 'Alice Springs');
    expect(answers.last.startLocation, 'Darwin');
    expect(answers.last.offGridComfortable, isFalse);
  });

  testWidgets(
    'endpoint menus retain choices and allow a round trip without typing',
    (tester) async {
      var answers = const OnboardingAnswers();
      await pumpStep(tester, 14, onChanged: (next) => answers = next);
      expect(find.byType(TextField), findsNothing);
      await chooseLocation(tester, 'onboarding-start-picker', 'Darwin');
      await pumpStep(
        tester,
        14,
        initial: answers,
        onChanged: (next) => answers = next,
      );
      await chooseLocation(tester, 'onboarding-end-picker', 'Darwin');
      await pumpStep(tester, 14, initial: answers);
      expect(answers.startLocation, 'Darwin');
      expect(answers.endLocation, 'Darwin');
      expect(find.text('Darwin'), findsNWidgets(2));
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );

  testWidgets('a previous custom endpoint survives the new picker', (
    tester,
  ) async {
    await pumpStep(
      tester,
      14,
      initial: const OnboardingAnswers(startLocation: 'Mataranka'),
    );
    expect(find.text('Mataranka'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding-start-picker')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mataranka'), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Mataranka'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a selection does not shift a long option label', (tester) async {
    const label = 'Aboriginal Culture';
    await pumpStep(tester, 3);
    final before = tester.getRect(find.text(label));
    await pumpStep(
      tester,
      3,
      initial: const OnboardingAnswers(focus: ['aboriginal_culture']),
    );
    expect(tester.getRect(find.text(label)), before);
  });

  testWidgets('endpoint menus fit a narrow phone with doubled text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
                builder: (context) => onboardingStepBuilder(
                  context,
                  OnboardingStepData(
                    step: 14,
                    answers: const OnboardingAnswers(),
                    updateAnswers: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await chooseLocation(tester, 'onboarding-start-picker', 'Alice Springs');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tallest steps fit at 360px without an exception', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpStep(tester, 13);
    expect(tester.takeException(), isNull);
    await pumpStep(tester, 14);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answers enter in turn; picking one does not replay them', (
    tester,
  ) async {
    var answers = const OnboardingAnswers();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => onboardingStepBuilder(
              context,
              OnboardingStepData(
                step: 0,
                answers: answers,
                updateAnswers: (next) => setState(() => answers = next),
              ),
            ),
          ),
        ),
      ),
    );

    double opacityOf(String label) {
      final entrance = find.ancestor(
        of: find.text(label),
        matching: find.byType(Entrance),
      );
      return tester
          .widget<Opacity>(
            find.descendant(of: entrance, matching: find.byType(Opacity)).first,
          )
          .opacity;
    }

    expect(opacityOf('18–25'), lessThan(1));
    await tester.pump(AppMotion.entrance ~/ 2);
    expect(
      opacityOf('50+'),
      lessThan(opacityOf('18–25')),
      reason: 'the last answer is staggered behind the first',
    );

    await tester.pumpAndSettle();
    expect(opacityOf('50+'), 1);

    await tester.tap(find.text('26–35'));
    await tester.pump();
    expect(answers.ageRange, isNotNull);
    expect(opacityOf('18–25'), 1, reason: 'a pick is not an arrival');
  });
}

Future<void> chooseLocation(
  WidgetTester tester,
  String key,
  String location,
) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(DropdownButton<String>),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(location).last);
  await tester.pumpAndSettle();
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
        body: SingleChildScrollView(
          child: Builder(
            builder: (context) => onboardingStepBuilder(
              context,
              OnboardingStepData(
                step: step,
                answers: initial,
                updateAnswers: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
