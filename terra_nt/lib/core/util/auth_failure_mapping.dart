import '../../data/models/auth_failure.dart';

/// Maps a Firebase Authentication error code onto the seam's own failure enum.
///
/// The table is fixed by `tasks/Task-24.md`; an unrecognised code is
/// [AuthFailure.unknown] rather than a thrown error, because a provider is free
/// to add codes and the screens already have copy for the unknown case.
AuthFailure failureForCode(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
    case 'user-disabled':
    case 'INVALID_LOGIN_CREDENTIALS':
      return AuthFailure.invalidCredential;
    case 'email-already-in-use':
      return AuthFailure.emailAlreadyInUse;
    case 'weak-password':
      return AuthFailure.weakPassword;
    case 'invalid-email':
      return AuthFailure.invalidEmail;
    case 'network-request-failed':
      return AuthFailure.network;
    case 'too-many-requests':
      return AuthFailure.tooManyRequests;
    case 'requires-recent-login':
      return AuthFailure.requiresRecentLogin;
    default:
      return AuthFailure.unknown;
  }
}
