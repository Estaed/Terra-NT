/// Every failure the auth seam is allowed to surface.
///
/// A provider's own error vocabulary stops at the seam: `AuthRepository`
/// implementations map their errors onto this enum -- for Firebase that is
/// `core/util/auth_failure_mapping.dart` -- so no caller ever reads a Firebase
/// code string.
enum AuthFailure {
  /// Wrong password, no such account, or a malformed credential.
  invalidCredential,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  network,
  tooManyRequests,

  /// The provider refuses to delete the account until the user signs in again.
  requiresRecentLogin,

  /// The user dismissed a provider sheet.
  cancelled,
  unknown,
}

/// The only exception type that escapes `AuthRepository`.
class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;
}
