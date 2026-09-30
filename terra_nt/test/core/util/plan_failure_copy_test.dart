import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/util/plan_failure_copy.dart';
import 'package:terra_nt/data/models/plan_failure.dart';

void main() {
  const tryAgainFailures = [
    PlanFailure.network,
    PlanFailure.timeout,
    PlanFailure.serverError,
    PlanFailure.rateLimited,
    PlanFailure.invalidResponse,
    PlanFailure.cancelled,
  ];

  for (final failure in tryAgainFailures) {
    test('$failure maps to the try-again row', () {
      final copy = copyForFailure(failure);
      expect(copy.primary, PlanFailureAction.tryAgain);
      expect(copy.showBack, isTrue);
      expect(copy.showOffline, isTrue);
    });
  }

  test('only connectivity failures suggest waiting for signal', () {
    for (final failure in [PlanFailure.network, PlanFailure.cancelled]) {
      final copy = copyForFailure(failure);
      expect(copy.title, "Couldn't reach the planner.");
      expect(
        copy.body,
        'Try again when you have signal, or use an offline suggestion '
        'from places on this device.',
      );
      expect(copy.visual, PlanFailureVisual.noSignal);
    }
  });

  const reasonTitles = {
    PlanFailure.timeout: 'The planner took too long.',
    PlanFailure.serverError: 'The planner had a server error.',
    PlanFailure.rateLimited: 'The planner has too many requests.',
    PlanFailure.invalidResponse: 'The planner returned an unusable trip.',
  };
  for (final entry in reasonTitles.entries) {
    test('${entry.key} names its reason without blaming signal', () {
      final copy = copyForFailure(entry.key);
      expect(copy.title, entry.value);
      expect(copy.body, contains('offline suggestion'));
      expect(copy.body, isNot(contains('signal')));
      expect(copy.visual, PlanFailureVisual.alert);
    });
  }

  test('cannotPlan asks for different answers with no back', () {
    final copy = copyForFailure(PlanFailure.cannotPlan);
    expect(copy.title, "We couldn't plan this trip.");
    expect(copy.body, 'Try a different region, vehicle or trip length.');
    expect(copy.primary, PlanFailureAction.changeAnswers);
    expect(copy.showBack, isFalse);
    expect(copy.showOffline, isFalse);
    expect(copy.visual, PlanFailureVisual.alert);
  });

  test('unauthorised asks to sign in with no back', () {
    final copy = copyForFailure(PlanFailure.unauthorised);
    expect(copy.title, 'Your session has expired.');
    expect(copy.body, 'Sign in again to plan a trip.');
    expect(copy.primary, PlanFailureAction.signIn);
    expect(copy.showBack, isFalse);
    expect(copy.showOffline, isFalse);
    expect(copy.visual, PlanFailureVisual.signIn);
  });

  test('every PlanFailure value is covered', () {
    expect({
      ...tryAgainFailures,
      PlanFailure.cannotPlan,
      PlanFailure.unauthorised,
    }, PlanFailure.values.toSet());
  });
}
