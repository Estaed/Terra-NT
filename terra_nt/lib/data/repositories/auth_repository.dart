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

  /// Firebase's stable user id, or null when signed out. Offline-safe.
  Future<String?> currentUid();

  /// A fresh ID token for the planning endpoint, or null when signed out.
  /// May touch the network to refresh; throws AuthException(network) if it cannot.
  Future<String?> idToken();

  Future<Session> signInWithEmail(String email, String password);

  Future<Session> signInWithGoogle();

  Future<Session> createAccount(String email, String password);

  Future<void> signOut();

  /// Deletes the signed-in account. Throws `AuthException(requiresRecentLogin)`
  /// when the provider refuses; the caller decides what to show.
  Future<void> deleteAccount();

  /// Sends the reset mail. Resolves normally when no account exists for the
  /// email — the screen must not learn which emails are registered.
  Future<void> sendPasswordReset(String email);

  Future<void> sendEmailVerification();

  /// Cached flag; best-effort reload behind it, never throws for a network miss.
  Future<bool> isEmailVerified();
}

/// The implementation every test uses, and the one the seam's behaviour is
/// specified against. [nextFailure] is how a test scripts a failure without a
/// Firebase double.
class InMemoryAuthRepository implements AuthRepository {
  /// When set, the next call that can fail throws it once and clears it.
  AuthFailure? nextFailure;

  /// The email the last [sendPasswordReset] was asked for.
  String? lastResetEmail;

  /// How many times [sendEmailVerification] succeeded.
  int verificationEmailsSent = 0;

  /// What [isEmailVerified] answers.
  bool emailVerified = false;

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
  Future<String?> currentUid() async => _uidFor(_email);

  @override
  Future<String?> idToken() async => _email == null ? null : 'test-token';

  static String? _uidFor(String? email) => email == null ? null : 'uid-$email';

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    _failIfScripted();
    _email = email;
    return Session(email: email, onboardingDone: false, uid: _uidFor(email));
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

  @override
  Future<void> sendPasswordReset(String email) async {
    _failIfScripted();
    lastResetEmail = email;
  }

  @override
  Future<void> sendEmailVerification() async {
    _failIfScripted();
    verificationEmailsSent++;
  }

  @override
  Future<bool> isEmailVerified() async => emailVerified;
}
