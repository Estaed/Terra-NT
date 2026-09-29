import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/trip_summary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';

void main() {
  test('full answers read as labels, not keys', () {
    const answers = OnboardingAnswers(
      days: 7,
      region: 'full_nt',
      vehicle: 'four_wd',
      startLocation: ' Darwin ',
      endLocation: 'Uluru',
    );
    expect(tripSummaryLines(answers), ['7 days · Full NT · 4x4', 'Darwin to Uluru']);
  });

  test('one day is singular and unanswered parts are left out', () {
    const answers = OnboardingAnswers(days: 1, startLocation: 'Darwin');
    expect(tripSummaryLines(answers), ['1 day']);
  });
}
