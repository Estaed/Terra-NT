import '../models/session.dart';

abstract interface class AuthRepository {
  Future<Session> signInWithEmail(String email, String password);
  Future<Session> signInWithGoogle();
  Future<void> signOut();
}

class InMemoryAuthRepository implements AuthRepository {
  Session _session = const Session(email: null, onboardingDone: false);

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    _session = Session(email: email, onboardingDone: _session.onboardingDone);
    return _session;
  }

  @override
  Future<Session> signInWithGoogle() {
    return signInWithEmail('explorer@example.com', 'mock-google-password');
  }

  @override
  Future<void> signOut() async {
    _session = Session(email: null, onboardingDone: _session.onboardingDone);
  }
}
