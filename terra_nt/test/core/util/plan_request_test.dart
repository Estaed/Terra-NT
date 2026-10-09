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

const _withoutOffRoadAnswer = OnboardingAnswers(
  ageRange: '26_35',
  companions: 'couple',
  focus: ['nature', 'aboriginal_culture'],
  vehicle: 'standard_car',
  budget: 'mid_range',
  accommodation: 'camping',
  activityLevel: 'medium',
  region: 'top_end',
  campingPreference: 'mixed',
  wildlifeInterest: 'interested',
  offGridComfortable: true,
  startLocation: 'Darwin',
  endLocation: 'Uluru',
);

void main() {
  group('buildPlanRequest', () {
    for (final vehicle in ['standard_car', 'campervan', 'guided_tour']) {
      test(
        '$vehicle sends all server keys when off-road confidence is skipped',
        () {
          final body = buildPlanRequest(
            _withoutOffRoadAnswer.copyWith(vehicle: vehicle),
            requestId: 'a' * 32,
          );
          expect(body['schemaVersion'], 1);
          expect(body['requestId'], 'a' * 32);
          final answers = body['answers']! as Map<String, Object?>;
          // ANSWER_KEYS and ENUMS in tools/plan_server/server.py.
          expect(answers, {
            'ageRange': '26_35',
            'days': 7,
            'companions': 'couple',
            'focus': ['nature', 'aboriginal_culture'],
            'vehicle': vehicle,
            'budget': 'mid_range',
            'accommodation': 'camping',
            'activityLevel': 'medium',
            'region': 'top_end',
            'offRoadConfidence': 'low',
            'heat': 3,
            'campingPreference': 'mixed',
            'wildlifeInterest': 'interested',
            'offGridComfortable': true,
            'startLocation': 'Darwin',
            'endLocation': 'Uluru',
          });
          final stale = buildPlanRequest(
            _withoutOffRoadAnswer.copyWith(
              vehicle: vehicle,
              offRoadConfidence: 'high',
            ),
            requestId: 'a' * 32,
          );
          expect(stale, body, reason: 'a previous 4x4 answer must be ignored');
        },
      );
    }

    test('a 4x4 still requires an off-road confidence answer', () {
      expect(
        () => buildPlanRequest(
          _withoutOffRoadAnswer.copyWith(vehicle: 'four_wd'),
          requestId: 'a' * 32,
        ),
        throwsStateError,
      );
    });

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
