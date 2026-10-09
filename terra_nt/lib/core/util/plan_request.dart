import 'dart:math';

import '../../data/models/onboarding_answers.dart';
import 'onboarding_rules.dart';

/// Builds the wire body for `POST {PLAN_API_URL}/v1/itinerary`
/// (`docs/PHASE-3-CONTRACT.md` §2). Throws [StateError] when any gated
/// answer is null or `focus` is empty — a request must never leave with a
/// hole in it.
Map<String, Object?> buildPlanRequest(
  OnboardingAnswers answers, {
  required String requestId,
}) {
  final ageRange = _require(answers.ageRange, 'ageRange');
  final companions = _require(answers.companions, 'companions');
  final vehicle = _require(answers.vehicle, 'vehicle');
  final budget = _require(answers.budget, 'budget');
  final accommodation = _require(answers.accommodation, 'accommodation');
  final activityLevel = _require(answers.activityLevel, 'activityLevel');
  final region = _require(answers.region, 'region');
  // The server requires this key even when the 4x4 question is skipped. Low
  // keeps a previous 4x4 answer from enabling off-road travel in another vehicle.
  final offRoadConfidence = needsOffRoadConfidence(answers)
      ? _require(answers.offRoadConfidence, 'offRoadConfidence')
      : 'low';
  final campingPreference = _require(
    answers.campingPreference,
    'campingPreference',
  );
  final wildlifeInterest = _require(
    answers.wildlifeInterest,
    'wildlifeInterest',
  );
  final offGridComfortable = answers.offGridComfortable;
  if (offGridComfortable == null) {
    throw StateError('offGridComfortable is required');
  }
  final startLocation = _require(answers.startLocation, 'startLocation');
  final endLocation = _require(answers.endLocation, 'endLocation');
  if (answers.focus.isEmpty) {
    throw StateError('focus is required');
  }

  return {
    'schemaVersion': 1,
    'requestId': requestId,
    'answers': {
      'ageRange': ageRange,
      'days': answers.days,
      'companions': companions,
      'focus': List<String>.unmodifiable(answers.focus),
      'vehicle': vehicle,
      'budget': budget,
      'accommodation': accommodation,
      'activityLevel': activityLevel,
      'region': region,
      'offRoadConfidence': offRoadConfidence,
      'heat': answers.heat,
      'campingPreference': campingPreference,
      'wildlifeInterest': wildlifeInterest,
      'offGridComfortable': offGridComfortable,
      'startLocation': startLocation.trim(),
      'endLocation': endLocation.trim(),
    },
  };
}

String _require(String? value, String field) {
  if (value == null || value.isEmpty) {
    throw StateError('$field is required');
  }
  return value;
}

const _requestIdChars = '0123456789abcdef';

/// 32 lowercase hex chars from [Random.secure]. Pure Dart, no package.
String newRequestId() {
  final random = Random.secure();
  return List.generate(
    32,
    (_) => _requestIdChars[random.nextInt(_requestIdChars.length)],
  ).join();
}
