import '../../data/models/onboarding_answers.dart';

/// Returns whether the current onboarding step has enough input to continue.
bool canNext(int step, OnboardingAnswers answers) {
  switch (step) {
    case 0:
      return _hasText(answers.ageRange);
    case 1:
      return true;
    case 2:
      return _hasText(answers.companions);
    case 3:
      return answers.focus.isNotEmpty;
    case 4:
      return _hasText(answers.vehicle);
    case 5:
      return _hasText(answers.budget);
    case 6:
      return _hasText(answers.accommodation);
    case 7:
      return _hasText(answers.activityLevel);
    case 8:
      return _hasText(answers.region);
    case 9:
      return true;
    case 10:
      return _hasText(answers.offRoadConfidence);
    case 11:
      return true;
    case 12:
      return _hasText(answers.campingPreference);
    case 13:
      return _hasText(answers.wildlifeInterest);
    case 14:
      return answers.offGridComfortable != null;
    default:
      return true;
  }
}

int progressPercent(int step) => (((step + 1) / 15) * 100).round();

double mapFraction(int step) => step / 14;

bool _hasText(String? value) => value != null && value.isNotEmpty;
