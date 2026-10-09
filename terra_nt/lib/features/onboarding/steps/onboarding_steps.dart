import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/elevation.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../data/seed/onboarding_options.dart';
import '../../../data/seed/seed_data.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/entrance.dart';
import '../onboarding_screen.dart';

/// Builds the question body for the step machine in [OnboardingScreen].
Widget onboardingStepBuilder(BuildContext context, OnboardingStepData data) {
  switch (data.step) {
    case 0:
      return SingleSelectStep(
        question: 'Which age range are you in?',
        options: ageRangeOptions,
        selected: data.answers.ageRange,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(ageRange: value)),
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
        onChanged: (value) =>
            data.updateAnswers(data.answers.copyWith(days: value)),
      );
    case 2:
      return SingleSelectStep(
        question: 'Who are you traveling with?',
        options: companionsOptions,
        selected: data.answers.companions,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(companions: value)),
      );
    case 3:
      return MultiSelectStep(
        question: "What's the main focus of this trip?",
        options: focusOptions,
        icons: const {
          'nature': LucideIcons.tree_pine,
          'aboriginal_culture': LucideIcons.landmark,
          'adventure': LucideIcons.mountain,
          'relaxation': LucideIcons.waves_horizontal,
        },
        selected: data.answers.focus,
        onChanged: (value) =>
            data.updateAnswers(data.answers.copyWith(focus: value)),
      );
    case 4:
      return SingleSelectStep(
        question: 'What are you traveling in?',
        options: vehicleOptions,
        icons: const {
          'four_wd': LucideIcons.car_front,
          'campervan': LucideIcons.caravan,
          'standard_car': LucideIcons.car,
          'guided_tour': LucideIcons.bus_front,
        },
        selected: data.answers.vehicle,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(vehicle: value)),
      );
    case 5:
      return SingleSelectStep(
        question: "What's your budget?",
        options: budgetOptions,
        selected: data.answers.budget,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(budget: value)),
      );
    case 6:
      return SingleSelectStep(
        question: 'Where do you want to stay?',
        options: accommodationOptions,
        icons: const {
          'camping': LucideIcons.tent,
          'motel_cabin': LucideIcons.house,
          'hotel': LucideIcons.hotel,
        },
        selected: data.answers.accommodation,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(accommodation: value)),
      );
    case 7:
      return SingleSelectStep(
        question: "What's your physical activity level?",
        options: activityLevelOptions,
        selected: data.answers.activityLevel,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(activityLevel: value)),
      );
    case 8:
      return RegionSelectStep(
        question: 'Which region do you want to focus on?',
        selected: data.answers.region,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(region: value)),
      );
    case 9:
      return SingleSelectStep(
        question: 'How confident are you driving a 4x4 off-road?',
        options: offRoadConfidenceOptions,
        selected: data.answers.offRoadConfidence,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(offRoadConfidence: value)),
      );
    case 10:
      final heat = data.answers.heat.clamp(_heatMin, _heatMax).toInt();
      return SliderStep(
        question: 'How well do you handle extreme heat?',
        value: heat,
        min: _heatMin,
        max: _heatMax,
        readout: (value) => heatLabels[value - _heatMin],
        startLabel: 'Prefer cool weather',
        endLabel: 'Thrives in the heat',
        onChanged: (value) => data.updateAnswers(
          data.answers.copyWith(heat: value.clamp(_heatMin, _heatMax).toInt()),
        ),
      );
    case 11:
      return SingleSelectStep(
        question: 'Camping under the stars, or resort comfort?',
        options: campingPreferenceOptions,
        icons: const {
          'camping': LucideIcons.tent,
          'mixed': LucideIcons.bed_double,
          'resort': LucideIcons.hotel,
        },
        selected: data.answers.campingPreference,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(campingPreference: value)),
      );
    case 12:
      return SingleSelectStep(
        question: 'How interested are you in spotting wildlife?',
        options: wildlifeInterestOptions,
        selected: data.answers.wildlifeInterest,
        onSelected: (value) =>
            data.updateAnswers(data.answers.copyWith(wildlifeInterest: value)),
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
        onStartChanged: (value) =>
            data.updateAnswers(data.answers.copyWith(startLocation: value)),
        onEndChanged: (value) =>
            data.updateAnswers(data.answers.copyWith(endLocation: value)),
      );
    default:
      throw ArgumentError.value(
        data.step,
        'step',
        'Expected a step from 0 to 14',
      );
  }
}

const _daysMin = 1;
const _daysMax = 14;
const _heatMin = 1;
const _heatMax = 5;

/// Illustrated regions retain the same wire keys and manual Next behaviour.
class RegionSelectStep extends StatelessWidget {
  const RegionSelectStep({
    super.key,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  final String question;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    children: [
      for (final option in regionOptions)
        _RegionCard(
          option: option,
          selected: selected == option.key,
          onTap: () => onSelected(option.key),
        ),
    ],
  );
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AnswerOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('onboarding-region-${option.key}'),
    label: '${option.label} — ${option.description}',
    checked: selected,
    inMutuallyExclusiveGroup: true,
    onTap: onTap,
    child: ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.fast,
          curve: AppMotion.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface2 : AppColors.surface1,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.hairline,
              width: AppElevation.hairlineWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                option.imageAsset!,
                height: AppMetrics.resultStopImageHeight,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: AppType.titleApp.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            option.description!,
                            style: AppType.bodyApp.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Opacity(
                      opacity: selected ? 1 : 0,
                      child: const AppIcon(
                        LucideIcons.check,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A radio-style option list used by the single-answer questions.
class SingleSelectStep extends StatelessWidget {
  const SingleSelectStep({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.icons = const {},
  });

  final String question;
  final List<AnswerOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Map<String, IconData> icons;

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    children: [
      for (final option in options)
        _OptionRow(
          label: option.label,
          icon: icons[option.key],
          selected: option.key == selected,
          onTap: () => onSelected(option.key),
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
    this.icons = const {},
  });

  final String question;
  final List<AnswerOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final Map<String, IconData> icons;

  @override
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    subtitle: 'Select all that apply',
    children: [
      for (final option in options)
        _OptionRow(
          label: option.label,
          icon: icons[option.key],
          selected: selected.contains(option.key),
          onTap: () {
            final next = [...selected];
            if (next.contains(option.key)) {
              next.remove(option.key);
            } else {
              next.add(option.key);
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
  final String Function(int)? readout;
  final String startLabel;
  final String endLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max).toInt();
    String formatValue(int next) =>
        readout?.call(next) ?? '$next ${unit ?? ''}'.trim();
    final display = formatValue(clampedValue);
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
                style: (readout == null ? AppType.displayMd : AppType.body)
                    .copyWith(color: AppColors.ink),
              ),
              Slider(
                key: const ValueKey('onboarding-slider'),
                value: clampedValue.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                semanticFormatterCallback: (next) {
                  final semanticValue = next.round().clamp(min, max).toInt();
                  return formatValue(semanticValue);
                },
                onChanged: (next) =>
                    onChanged(next.round().clamp(min, max).toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      startLabel,
                      style: AppType.caption.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      endLabel,
                      textAlign: TextAlign.end,
                      style: AppType.caption.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Two endpoint menus, retaining the planning contract's location strings.
class LocationPairStep extends StatelessWidget {
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
  Widget build(BuildContext context) => _StepColumn(
    question: question,
    children: [
      _LocationPicker(
        key: const ValueKey('onboarding-start-picker'),
        label: 'Start',
        hint: 'Choose a starting point',
        value: startLocation,
        onChanged: onStartChanged,
      ),
      _LocationPicker(
        key: const ValueKey('onboarding-end-picker'),
        label: 'End',
        hint: 'Choose an end point',
        value: endLocation,
        onChanged: onEndChanged,
      ),
    ],
  );
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == null || value!.trim().isEmpty ? null : value;
    // Going back must also retain an answer entered before the picker existed.
    final locations = [
      ...tripLocationOptions,
      if (selected != null && !tripLocationOptions.contains(selected)) selected,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.titleApp.copyWith(color: AppColors.ink)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppMetrics.padRowX),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.hairlineStrong,
              width: AppElevation.hairlineWidth,
            ),
          ),
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            itemHeight: null,
            dropdownColor: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.card),
            underline: const SizedBox.shrink(),
            icon: const AppIcon(LucideIcons.chevron_down),
            hint: Text(
              hint,
              style: AppType.bodyApp.copyWith(color: AppColors.inkMuted),
            ),
            style: AppType.bodyApp.copyWith(color: AppColors.ink),
            items: [
              for (final location in locations)
                DropdownMenuItem(
                  value: location,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppMetrics.minTouchTarget,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(location),
                    ),
                  ),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ],
    );
  }
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
  const _StepColumn({
    required this.question,
    required this.children,
    this.subtitle,
  });

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
        Text(
          subtitle!,
          style: AppType.caption.copyWith(color: AppColors.inkMuted),
        ),
      ],
      SizedBox(height: subtitle == null ? AppSpacing.lg : AppSpacing.md),
      ..._withGaps(children, AppMetrics.gapRow),
    ],
  );

  /// Each answer enters in turn as its step arrives (`docs/PRD.md` D18). The
  /// step card is rebuilt from scratch per step, so the entrance plays once
  /// per arrival; picking an answer only rebuilds it in place.
  List<Widget> _withGaps(List<Widget> items, double gap) {
    final result = <Widget>[];
    for (var index = 0; index < items.length; index++) {
      if (index > 0) result.add(SizedBox(height: gap));
      result.add(Entrance(index: index, child: items[index]));
    }
    return result;
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.fast,
      curve: AppMotion.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.padRowX,
        vertical: AppMetrics.padRowY,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface2 : AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        // D18: the row is the choice — plain label, the primary edge and a check
        // mark it selected (a bordered chip inside a bordered row read as clutter).
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.hairline,
          width: AppElevation.hairlineWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: AppMetrics.iconXl, color: AppColors.inkMuted),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: AppType.titleApp.copyWith(
                color: selected ? AppColors.ink : AppColors.inkSubtle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.fast,
            child: const AppIcon(LucideIcons.check, color: AppColors.primary),
          ),
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
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppMotion.fast,
      curve: AppMotion.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface2 : AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.hairline,
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
                Text(
                  title,
                  style: AppType.titleApp.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: AppType.bodyApp.copyWith(color: AppColors.inkSubtle),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.fast,
            child: const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: AppIcon(LucideIcons.check, color: AppColors.primary),
            ),
          ),
        ],
      ),
    ),
  );
}
