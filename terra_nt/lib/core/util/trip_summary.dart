import '../../data/models/onboarding_answers.dart';
import '../../data/seed/onboarding_options.dart';

/// The trip being planned, in the words the user picked, for Loading (D18):
/// `7 days · Full NT · 4x4` and, when both ends are known, `Darwin to Uluru`.
/// A part the user has not answered is left out rather than shown as a key.
List<String> tripSummaryLines(OnboardingAnswers answers) {
  final facts = [
    answers.days == 1 ? '1 day' : '${answers.days} days',
    if (answers.region != null) labelFor(regionOptions, answers.region!),
    if (answers.vehicle != null) labelFor(vehicleOptions, answers.vehicle!),
  ];
  final start = answers.startLocation?.trim() ?? '';
  final end = answers.endLocation?.trim() ?? '';
  return [
    facts.join(' · '),
    if (start.isNotEmpty && end.isNotEmpty) '$start to $end',
  ];
}
