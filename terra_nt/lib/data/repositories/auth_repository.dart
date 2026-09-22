import '../models/auth_failure.dart';
import '../models/session.dart';

/// One of the two seams (`CLAUDE.md` -> Blueprint -> Architecture).
///
/// Every method may throw [AuthException] and nothing else: a provider's own
/// exception type never escapes an implementation.
abstract interface class AuthRepository {
  /// The signed-in email the provider persisted on this device, or null. Never
  /// touches the network; must answer offline at cold start.
  Future<String?> currentEmail();

  Future<Session> signInWithEmail(String email, String password);

  Future<Session> signInWithGoogle();

  Future<Session> createAccount(String email, String password);

  Future<void> signOut();

  /// Deletes the signed-in account. Throws `AuthException(requiresRecentLogin)`
  /// when the provider refuses; the caller decides what to show.
  Future<void> deleteAccount();
}

/// The implementation every test uses, and the one the seam's behaviour is
/// specified against. [nextFailure] is how a test scripts a failure without a
/// Firebase double.
class InMemoryAuthRepository implements AuthRepository {
  /// When set, the next call that can fail throws it once and clears it.
  AuthFailure? nextFailure;

  String? _email;

  void _failIfScripted() {
    final failure = nextFailure;
    if (failure == null) return;
    nextFailure = null;
    throw AuthException(failure);
  }

  @override
  Future<String?> currentEmail() async => _email;

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    _failIfScripted();
    _email = email;
    return Session(email: email, onboardingDone: false);
  }

  @override
  Future<Session> signInWithGoogle() {
    return signInWithEmail('explorer@example.com', 'mock-google-password');
  }

  @override
  Future<Session> createAccount(String email, String password) {
    return signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() async {
    _failIfScripted();
    _email = null;
  }

  @override
  Future<void> deleteAccount() async {
    _failIfScripted();
    _email = null;
  }
}
