import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// `GoogleSignIn.instance.initialize()` must run exactly once per process,
  /// before any other call on the singleton. This future is shared so a
  /// second sign-in attempt awaits the same initialisation instead of
  /// re-initialising (undefined behaviour per the package's own docs).
  static Future<void>? _googleInitialisation;

  Future<void> _ensureGoogleInitialised() {
    return _googleInitialisation ??= GoogleSignIn.instance.initialize();
  }

  /// Firebase persists the signed-in user on the device, so this answers
  /// offline and without awaiting anything.
  @override
  Future<String?> currentEmail() async => _auth.currentUser?.email;

  @override
  Future<String?> currentUid() async => _auth.currentUser?.uid;

  @override
  Future<String?> idToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

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
        uid: credential.user?.uid,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  @override
  Future<Session> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await _ensureGoogleInitialised();
    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthException(AuthFailure.unknown);
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final user = (await _auth.signInWithCredential(credential)).user;
      return Session(email: user?.email, onboardingDone: false, uid: user?.uid);
    } on GoogleSignInException catch (e) {
      throw AuthException(failureForGoogleCode(e.code));
    } on FirebaseAuthException catch (e) {
      throw AuthException(failureForCode(e.code));
    }
  }

  @override
  Future<Session> createAccount(String email, String password) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
    try {
      // A missed verification mail must not fail account creation
      // (`docs/PRD.md` §3.10); the user can ask for another one.
      await sendEmailVerification();
    } catch (_) {
      // Swallowed deliberately, see comment above.
    }
    return Session(
      email: credential.user?.email ?? email,
      onboardingDone: false,
      uid: credential.user?.uid,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      // A Google sign-out failure must never block the Firebase sign-out
      // below: the account chooser reappearing next time is a nicety, not
      // something worth leaving the user stuck signed in for.
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Swallowed deliberately, see comment above.
    }
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(AuthFailure.unknown);
    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Must not reveal which emails are registered.
      if (error.code == 'user-not-found') return;
      throw AuthException(failureForCode(error.code));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(AuthFailure.unknown);
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthException(failureForCode(error.code));
    }
  }

  /// The reload is best effort: offline, the cached flag answers.
  @override
  Future<bool> isEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {
      // Swallowed deliberately, see comment above.
    }
    return _auth.currentUser?.emailVerified ?? false;
  }
}
