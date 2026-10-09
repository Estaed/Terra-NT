import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInExceptionCode;

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

/// Maps a [GoogleSignInExceptionCode] onto the seam's failure enum.
///
/// The table is fixed by `tasks/Task-25.md`: only a user-dismissed sheet is
/// [AuthFailure.cancelled]; every other code — none of which is a network
/// failure, since Firebase's own exception already carries that — is
/// [AuthFailure.unknown]. The switch is exhaustive over the enum, with no
/// `default`, so a new enum value fails to compile here instead of silently
/// falling through.
AuthFailure failureForGoogleCode(GoogleSignInExceptionCode code) {
  switch (code) {
    case GoogleSignInExceptionCode.canceled:
      return AuthFailure.cancelled;
    case GoogleSignInExceptionCode.unknownError:
    case GoogleSignInExceptionCode.interrupted:
    case GoogleSignInExceptionCode.clientConfigurationError:
    case GoogleSignInExceptionCode.providerConfigurationError:
    case GoogleSignInExceptionCode.uiUnavailable:
    case GoogleSignInExceptionCode.userMismatch:
      return AuthFailure.unknown;
  }
}
