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
      expect(copy.title, "Couldn't reach the planner.");
      expect(copy.body, 'Check your signal and try again.');
      expect(copy.primary, PlanFailureAction.tryAgain);
      expect(copy.showBack, isTrue);
    });
  }

  test('cannotPlan asks for different answers with no back', () {
    final copy = copyForFailure(PlanFailure.cannotPlan);
    expect(copy.title, "We couldn't plan this trip.");
    expect(copy.body, 'Try a different region, vehicle or trip length.');
    expect(copy.primary, PlanFailureAction.changeAnswers);
    expect(copy.showBack, isFalse);
  });

  test('unauthorised asks to sign in with no back', () {
    final copy = copyForFailure(PlanFailure.unauthorised);
    expect(copy.title, 'Your session has expired.');
    expect(copy.body, 'Sign in again to plan a trip.');
    expect(copy.primary, PlanFailureAction.signIn);
    expect(copy.showBack, isFalse);
  });

  test('every PlanFailure value is covered', () {
    expect({
      ...tryAgainFailures,
      PlanFailure.cannotPlan,
      PlanFailure.unauthorised,
    }, PlanFailure.values.toSet());
  });
}
