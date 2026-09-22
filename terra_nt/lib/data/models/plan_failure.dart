/// Every failure the planning seam is allowed to surface, from
/// `docs/PHASE-3-CONTRACT.md` §1.
enum PlanFailure {
  network,
  timeout,
  cannotPlan,
  rateLimited,
  unauthorised,
  serverError,
  invalidResponse,
  cancelled,
}

/// The only exception type the planning seam throws.
class PlanException implements Exception {
  const PlanException(this.failure, [this.detail]);

  final PlanFailure failure;

  /// For logs; never shown to the user.
  final String? detail;
}
