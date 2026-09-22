import 'package:firebase_auth/firebase_auth.dart';

import '../../core/util/auth_failure_mapping.dart';
import '../models/auth_failure.dart';
import '../models/session.dart';
import 'auth_repository.dart';

/// The phase-2 implementation of the auth seam (`docs/PRD.md` D12).
///
/// Deliberately thin and deliberately not unit-tested: a `FirebaseAuth` needs an
/// initialised Firebase app, and `CLAUDE.md` -> Blueprint -> Stack (2026-09-22)
/// rules out a Firebase test double. The instance arrives through the
/// constructor so this class is at least constructible; `InMemoryAuthRepository`
/// carries the seam's behaviour tests and Task-25's device tour exercises this
/// one. This file and `notifiers.dart`'s default are the only places
/// `package:firebase_auth` appears.
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Firebase persists the signed-in user on the device, so this answers
  /// offline and without awaiting anything.
  @override
  Future<String?> currentEmail() async => _auth.currentUser?.email;

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Session(
        email: credential.user?.email ?? email,
        onboardingDone: false,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  /// Task-25 writes the real Google credential exchange. Until then the Login
  /// button reports a failure rather than doing nothing.
  @override
  Future<Session> signInWithGoogle() async {
    throw const AuthException(AuthFailure.unknown);
  }

  @override
  Future<Session> createAccount(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Session(
        email: credential.user?.email ?? email,
        onboardingDone: false,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }
}
