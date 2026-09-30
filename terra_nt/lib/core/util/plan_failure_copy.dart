import '../../data/models/plan_failure.dart';

/// What the failure state's primary button does (`docs/PRD.md` §3.4).
enum PlanFailureAction { tryAgain, changeAnswers, signIn }

/// The failure cue is independent of whether an offline route is available.
enum PlanFailureVisual { noSignal, alert, signIn }

/// The copy and buttons Loading shows for one [PlanFailure].
class PlanFailureCopy {
  const PlanFailureCopy({
    required this.title,
    required this.body,
    required this.primary,
    required this.showBack,
    required this.visual,
    this.showOffline = false,
  });

  final String title;
  final String body;
  final PlanFailureAction primary;
  final bool showBack;
  final bool showOffline;
  final PlanFailureVisual visual;
}

const _tryAgain = PlanFailureCopy(
  title: "Couldn't reach the planner.",
  body:
      'Try again when you have signal, or use an offline suggestion '
      'from places on this device.',
  primary: PlanFailureAction.tryAgain,
  showBack: true,
  showOffline: true,
  visual: PlanFailureVisual.noSignal,
);

/// Names the reason supplied by the planning seam without exposing log details.
/// [PlanFailure.cancelled] never reaches the screen; it maps to the try-again
/// row so the switch stays total.
PlanFailureCopy copyForFailure(PlanFailure failure) {
  switch (failure) {
    case PlanFailure.network:
    case PlanFailure.cancelled:
      return _tryAgain;
    case PlanFailure.timeout:
      return const PlanFailureCopy(
        title: 'The planner took too long.',
        body: 'Try again, or use an offline suggestion from this device.',
        primary: PlanFailureAction.tryAgain,
        showBack: true,
        showOffline: true,
        visual: PlanFailureVisual.alert,
      );
    case PlanFailure.serverError:
      return const PlanFailureCopy(
        title: 'The planner had a server error.',
        body:
            'Try again shortly, or use an offline suggestion from this device.',
        primary: PlanFailureAction.tryAgain,
        showBack: true,
        showOffline: true,
        visual: PlanFailureVisual.alert,
      );
    case PlanFailure.rateLimited:
      return const PlanFailureCopy(
        title: 'The planner has too many requests.',
        body: 'Wait a moment and try again, or use an offline suggestion.',
        primary: PlanFailureAction.tryAgain,
        showBack: true,
        showOffline: true,
        visual: PlanFailureVisual.alert,
      );
    case PlanFailure.invalidResponse:
      return const PlanFailureCopy(
        title: 'The planner returned an unusable trip.',
        body: 'Try again, or use an offline suggestion from this device.',
        primary: PlanFailureAction.tryAgain,
        showBack: true,
        showOffline: true,
        visual: PlanFailureVisual.alert,
      );
    case PlanFailure.cannotPlan:
      return const PlanFailureCopy(
        title: "We couldn't plan this trip.",
        body: 'Try a different region, vehicle or trip length.',
        primary: PlanFailureAction.changeAnswers,
        showBack: false,
        visual: PlanFailureVisual.alert,
      );
    case PlanFailure.unauthorised:
      return const PlanFailureCopy(
        title: 'Your session has expired.',
        body: 'Sign in again to plan a trip.',
        primary: PlanFailureAction.signIn,
        showBack: false,
        visual: PlanFailureVisual.signIn,
      );
  }
}
