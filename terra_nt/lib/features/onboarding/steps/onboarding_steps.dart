import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../data/seed/seed_data.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/app_text_input.dart';
import '../onboarding_screen.dart';

/// Builds the question body for the step machine in [OnboardingScreen].
Widget onboardingStepBuilder(BuildContext context, OnboardingStepData data) {
  switch (data.step) {
    case 0:
      return SingleSelectStep(
        question: 'Which age range are you in?',
        options: const ['18–25', '26–35', '36–50', '50+'],
        selected: data.answers.ageRange,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(ageRange: value),
        ),
      );
    case 1:
      return SliderStep(
        question: 'How many days is your trip?',
        value: data.answers.days,
        min: _daysMin,
        max: _daysMax,
        unit: 'days',
        startLabel: '1 day',
        endLabel: '14 days',
        onChanged: (value) => data.updateAnswers(
          data.answers.copyWith(days: value),
        ),
      );
    case 2:
      return SingleSelectStep(
        question: 'Who are you traveling with?',
        options: const ['Solo', 'Couple', 'Family', 'Friends'],
        selected: data.answers.companions,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(companions: value),
        ),
      );
    case 3:
      return MultiSelectStep(
        question: "What's the main focus of this trip?",
        options: const ['Nature', 'Aboriginal Culture', 'Adventure', 'Relaxation'],
        selected: data.answers.focus,
        onChanged: (value) => data.updateAnswers(
          data.answers.copyWith(focus: value),
        ),
      );
    case 4:
      return SingleSelectStep(
        question: 'What are you traveling in?',
        options: const ['4x4', 'Campervan', 'Standard Car', 'Guided Tour'],
        selected: data.answers.vehicle,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(vehicle: value),
        ),
      );
    case 5:
      return SingleSelectStep(
        question: "What's your budget?",
        options: const ['Budget', 'Mid-range', 'Luxury'],
        selected: data.answers.budget,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(budget: value),
        ),
      );
    case 6:
      return SingleSelectStep(
        question: 'Where do you want to stay?',
        options: const ['Camping', 'Motel/Cabin', 'Hotel'],
        selected: data.answers.accommodation,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(accommodation: value),
        ),
      );
    case 7:
      return SingleSelectStep(
        question: "What's your physical activity level?",
        options: const ['Low', 'Medium', 'High'],
        selected: data.answers.activityLevel,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(activityLevel: value),
        ),
      );
    case 8:
      return SingleSelectStep(
        question: 'Which region do you want to focus on?',
        options: const ['Top End', 'Red Centre', 'Full NT'],
        selected: data.answers.region,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(region: value),
        ),
      );
    case 9:
      return SingleSelectStep(
        question: 'How confident are you driving a 4x4 off-road?',
        options: const ['Low', 'Medium', 'High'],
        selected: data.answers.offRoadConfidence,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(offRoadConfidence: value),
        ),
      );
    case 10:
      final heat = data.answers.heat.clamp(_heatMin, _heatMax).toInt();
      return SliderStep(
        question: 'How well do you handle extreme heat?',
        value: heat,
        min: _heatMin,
        max: _heatMax,
        readout: heatLabels[heat - 1],
        startLabel: 'Prefer cool weather',
        endLabel: 'Thrives in the heat',
        onChanged: (value) => data.updateAnswers(
          data.answers.copyWith(
            heat: value.clamp(_heatMin, _heatMax).toInt(),
          ),
        ),
      );
    case 11:
      return SingleSelectStep(
        question: 'Camping under the stars, or resort comfort?',
        options: const ['Camping all the way', 'Bit of both', 'Resort comfort'],
        selected: data.answers.campingPreference,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(campingPreference: value),
        ),
      );
    case 12:
      return SingleSelectStep(
        question: 'How interested are you in spotting wildlife?',
        options: const ['Not fussed', 'Interested', 'Big draw'],
        selected: data.answers.wildlifeInterest,
        onSelected: (value) => data.updateAnswers(
          data.answers.copyWith(wildlifeInterest: value),
        ),
      );
    case 13:
      return YesNoStep(
        question: 'Comfortable in remote areas with no phone signal?',
        selected: data.answers.offGridComfortable,
        onChanged: (value) => data.updateAnswers(
          data.answers.copyWith(offGridComfortable: value),
        ),
      );
    case 14:
      return LocationPairStep(
        question: 'Where does your trip start and end?',
        startLocation: data.answers.startLocation,
        endLocation: data.answers.endLocation,
        onStartChanged: (value) => data.updateAnswers(
          data.answers.copyWith(startLocation: value),
        ),
        onEndChanged: (value) => data.updateAnswers(
          data.answers.copyWith(endLocation: value),
        ),
      );
    default:
      throw ArgumentError.value(data.step, 'step', 'Expected a step from 0 to 14');
  }
}

const _daysMin = 1;
const _daysMax = 14;
const _heatMin = 1;
const _heatMax = 5;

/// A radio-style option list used by the single-answer questions.
class SingleSelectStep extends StatelessWidget {
  const SingleSelectStep({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String question;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    children: [
      for (final option in options)
        _OptionRow(
          label: option,
          selected: option == selected,
          onTap: () => onSelected(option),
        ),
    ],
  );
}

/// A multi-answer option list. It deliberately leaves advancing to the shell footer.
class MultiSelectStep extends StatelessWidget {
  const MultiSelectStep({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String question;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    subtitle: 'Select all that apply',
    children: [
      for (final option in options)
        _OptionRow(
          label: option,
          selected: selected.contains(option),
          onTap: () {
            final next = [...selected];
            if (next.contains(option)) {
              next.remove(option);
            } else {
              next.add(option);
            }
            onChanged(List<String>.unmodifiable(next));
          },
        ),
    ],
  );
}

/// A bounded integer slider used for trip length and heat tolerance.
class SliderStep extends StatelessWidget {
  const SliderStep({
    super.key,
    required this.question,
    required this.value,
    required this.min,
    required this.max,
    required this.startLabel,
    required this.endLabel,
    required this.onChanged,
    this.unit,
    this.readout,
  });

  final String question;
  final int value;
  final int min;
  final int max;
  final String? unit;
  final String? readout;
  final String startLabel;
  final String endLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max).toInt();
    final display = readout ?? '$clampedValue ${unit ?? ''}'.trim();
    return _StepColumn(
      question: question,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.hairline,
              width: AppElevation.hairlineWidth,
            ),
          ),
          child: Column(
            children: [
              Text(
                display,
                key: const ValueKey('onboarding-slider-readout'),
                textAlign: TextAlign.center,
                style: AppType.displayMd.copyWith(color: AppColors.ink),
              ),
              Slider(
                key: const ValueKey('onboarding-slider'),
                value: clampedValue.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: (next) => onChanged(
                  next.round().clamp(min, max).toInt(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(startLabel, style: AppType.caption.copyWith(color: AppColors.inkTertiary)),
                  Text(endLabel, style: AppType.caption.copyWith(color: AppColors.inkTertiary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The last question's two free-text fields for where the trip starts and ends.
///
/// The controllers are seeded from the answers once and then own the text, so a
/// rebuild driven by another field's keystroke cannot move the caret.
class LocationPairStep extends StatefulWidget {
  const LocationPairStep({
    super.key,
    required this.question,
    required this.startLocation,
    required this.endLocation,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final String question;
  final String? startLocation;
  final String? endLocation;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  @override
  State<LocationPairStep> createState() => _LocationPairStepState();
}

class _LocationPairStepState extends State<LocationPairStep> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.startLocation ?? '');
    _endController = TextEditingController(text: widget.endLocation ?? '');
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: widget.question,
    children: [
      AppTextInput(
        key: const ValueKey('onboarding-start-input'),
        label: 'Start',
        placeholder: 'e.g. Darwin',
        controller: _startController,
        onChanged: widget.onStartChanged,
      ),
      AppTextInput(
        key: const ValueKey('onboarding-end-input'),
        label: 'End',
        placeholder: 'e.g. Alice Springs',
        controller: _endController,
        onChanged: widget.onEndChanged,
      ),
    ],
  );
}

/// The final yes/no choice. Selection is manual; the shell footer advances it.
class YesNoStep extends StatelessWidget {
  const YesNoStep({
    super.key,
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final String question;
  final bool? selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    children: [
      _DetailCard(
        title: "Yes, I'm prepared to go off-grid",
        description: 'Comfortable with long stretches out of range',
        selected: selected == true,
        onTap: () => onChanged(true),
      ),
      _DetailCard(
        title: "I'd prefer to stay connected",
        description: 'Would rather stick to areas with signal',
        selected: selected == false,
        onTap: () => onChanged(false),
      ),
    ],
  );
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({required this.question, required this.children, this.subtitle});

  final String question;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(question, style: AppType.cardTitle.copyWith(color: AppColors.ink)),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle!, style: AppType.caption.copyWith(color: AppColors.inkTertiary)),
      ],
      SizedBox(height: subtitle == null ? AppSpacing.lg : AppSpacing.md),
      ..._withGaps(children, AppMetrics.gapRow),
    ],
  );

  List<Widget> _withGaps(List<Widget> items, double gap) {
    final result = <Widget>[];
    for (var index = 0; index < items.length; index++) {
      if (index > 0) result.add(SizedBox(height: gap));
      result.add(items[index]);
    }
    return result;
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.padRowX,
        vertical: AppMetrics.padRowY,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface2 : AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? AppColors.hairlineStrong : AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: AppChip(label: label, selected: selected)),
          if (selected)
            const AppIcon(LucideIcons.check, color: AppColors.primary),
        ],
      ),
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface2 : AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? AppColors.hairlineStrong : AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.titleApp.copyWith(color: AppColors.ink)),
                const SizedBox(height: AppSpacing.xxs),
                Text(description, style: AppType.bodyApp.copyWith(color: AppColors.inkSubtle)),
              ],
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: AppIcon(LucideIcons.check, color: AppColors.primary),
            ),
        ],
      ),
    ),
  );
}
