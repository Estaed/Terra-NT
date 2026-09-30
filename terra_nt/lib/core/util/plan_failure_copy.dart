import '../../data/models/plan_failure.dart';

/// What the failure state's primary button does (`docs/PRD.md` §3.4).
enum PlanFailureAction { tryAgain, changeAnswers, signIn }

/// The copy and buttons Loading shows for one [PlanFailure].
class PlanFailureCopy {
  const PlanFailureCopy({
    required this.title,
    required this.body,
    required this.primary,
    required this.showBack,
    this.showOffline = false,
  });

  final String title;
  final String body;
  final PlanFailureAction primary;
  final bool showBack;
  final bool showOffline;
}

const _tryAgain = PlanFailureCopy(
  title: "Couldn't reach the planner.",
  body:
      'Try again when you have signal, or use an offline suggestion '
      'from places on this device.',
  primary: PlanFailureAction.tryAgain,
  showBack: true,
  showOffline: true,
);

/// The failure table from `docs/PRD.md` §3.4, character for character.
/// [PlanFailure.cancelled] never reaches the screen; it maps to the try-again
/// row so the switch stays total.
PlanFailureCopy copyForFailure(PlanFailure failure) {
  switch (failure) {
    case PlanFailure.network:
    case PlanFailure.timeout:
    case PlanFailure.serverError:
    case PlanFailure.rateLimited:
    case PlanFailure.invalidResponse:
    case PlanFailure.cancelled:
      return _tryAgain;
    case PlanFailure.cannotPlan:
      return const PlanFailureCopy(
        title: "We couldn't plan this trip.",
        body: 'Try a different region, vehicle or trip length.',
        primary: PlanFailureAction.changeAnswers,
        showBack: false,
      );
    case PlanFailure.unauthorised:
      return const PlanFailureCopy(
        title: 'Your session has expired.',
        body: 'Sign in again to plan a trip.',
        primary: PlanFailureAction.signIn,
        showBack: false,
      );
  }
}
