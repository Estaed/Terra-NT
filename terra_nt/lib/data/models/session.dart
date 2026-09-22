class Session {
  final String? email;
  final bool onboardingDone;

  /// The auth provider's stable user id, or null when signed out.
  final String? uid;

  const Session({
    this.email,
    required this.onboardingDone,
    this.uid,
  });
}
