import '../../data/models/onboarding_answers.dart';

const onboardingStepCount = 15;
const lastOnboardingStep = onboardingStepCount - 1;
const _offRoadStep = 9;

bool needsOffRoadConfidence(OnboardingAnswers answers) =>
    answers.vehicle == 'four_wd';

// Until a vehicle is chosen, the total includes all possible questions.
bool _skipOffRoad(OnboardingAnswers answers) =>
    answers.vehicle != null && !needsOffRoadConfidence(answers);

int visibleOnboardingStepCount(OnboardingAnswers answers) =>
    onboardingStepCount - (_skipOffRoad(answers) ? 1 : 0);

int onboardingStepNumber(int step, OnboardingAnswers answers) =>
    step + 1 - (_skipOffRoad(answers) && step > _offRoadStep ? 1 : 0);

int nextOnboardingStep(int step, OnboardingAnswers answers) {
  final next = (step + 1).clamp(0, lastOnboardingStep);
  return next == _offRoadStep && _skipOffRoad(answers) ? next + 1 : next;
}

int previousOnboardingStep(int step, OnboardingAnswers answers) {
  final previous = (step - 1).clamp(0, lastOnboardingStep);
  return previous == _offRoadStep && _skipOffRoad(answers)
      ? previous - 1
      : previous;
}

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
      return _skipOffRoad(answers) || _hasText(answers.offRoadConfidence);
    case 10:
      return true;
    case 11:
      return _hasText(answers.campingPreference);
    case 12:
      return _hasText(answers.wildlifeInterest);
    case 13:
      return answers.offGridComfortable != null;
    case 14:
      return _hasText(answers.startLocation?.trim()) &&
          _hasText(answers.endLocation?.trim());
    default:
      return true;
  }
}

int progressPercent(int step, [OnboardingAnswers? answers]) {
  final current = answers ?? const OnboardingAnswers();
  return ((onboardingStepNumber(step, current) /
              visibleOnboardingStepCount(current)) *
          100)
      .round();
}

bool _hasText(String? value) => value != null && value.isNotEmpty;
