import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/plan_request.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';

const _prototypeLabels = [
  '18–25', '26–35', '36–50', '50+',
  'Solo', 'Couple', 'Family', 'Friends',
  'Nature', 'Aboriginal Culture', 'Adventure', 'Relaxation',
  '4x4', 'Campervan', 'Standard Car', 'Guided Tour',
  'Budget', 'Mid-range', 'Luxury',
  'Camping', 'Motel/Cabin', 'Hotel',
  'Low', 'Medium', 'High',
  'Top End', 'Red Centre', 'Full NT',
  'Camping all the way', 'Bit of both', 'Resort comfort',
  'Not fussed', 'Interested', 'Big draw',
];

const _fullyAnswered = OnboardingAnswers(
  ageRange: '26_35',
  days: 7,
  companions: 'couple',
  focus: ['nature', 'aboriginal_culture'],
  vehicle: 'four_wd',
  budget: 'mid_range',
  accommodation: 'camping',
  activityLevel: 'medium',
  region: 'top_end',
  offRoadConfidence: 'medium',
  heat: 3,
  campingPreference: 'mixed',
  wildlifeInterest: 'interested',
  offGridComfortable: true,
  startLocation: '  Darwin  ',
  endLocation: '  Uluru  ',
);

void main() {
  group('buildPlanRequest', () {
    test('builds the exact map from docs/PHASE-3-CONTRACT.md §2', () {
      final result = buildPlanRequest(_fullyAnswered, requestId: 'r' * 32);
      expect(result, {
        'schemaVersion': 1,
        'requestId': 'r' * 32,
        'answers': {
          'ageRange': '26_35',
          'days': 7,
          'companions': 'couple',
          'focus': ['nature', 'aboriginal_culture'],
          'vehicle': 'four_wd',
          'budget': 'mid_range',
          'accommodation': 'camping',
          'activityLevel': 'medium',
          'region': 'top_end',
          'offRoadConfidence': 'medium',
          'heat': 3,
          'campingPreference': 'mixed',
          'wildlifeInterest': 'interested',
          'offGridComfortable': true,
          'startLocation': 'Darwin',
          'endLocation': 'Uluru',
        },
      });
    });

    test('no prototype label string appears in the encoded body', () {
      final result = buildPlanRequest(_fullyAnswered, requestId: 'r' * 32);
      final encoded = jsonEncode(result);
      for (final label in _prototypeLabels) {
        expect(encoded, isNot(contains(label)), reason: label);
      }
    });

    test('an empty focus throws StateError', () {
      expect(
        () => buildPlanRequest(
          _fullyAnswered.copyWith(focus: []),
          requestId: 'r' * 32,
        ),
        throwsStateError,
      );
    });

    test('a null gated answer throws StateError', () {
      const missingAgeRange = OnboardingAnswers(
        companions: 'couple',
        focus: ['nature'],
        vehicle: 'four_wd',
        budget: 'mid_range',
        accommodation: 'camping',
        activityLevel: 'medium',
        region: 'top_end',
        offRoadConfidence: 'medium',
        campingPreference: 'mixed',
        wildlifeInterest: 'interested',
        offGridComfortable: true,
        startLocation: 'Darwin',
        endLocation: 'Uluru',
      );
      expect(
        () => buildPlanRequest(missingAgeRange, requestId: 'r' * 32),
        throwsStateError,
      );
    });
  });

  group('newRequestId', () {
    test('matches the 32 lowercase hex chars format', () {
      expect(newRequestId(), matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('two calls differ', () {
      expect(newRequestId(), isNot(newRequestId()));
    });
  });
}
