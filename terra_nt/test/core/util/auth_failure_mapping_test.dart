import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:terra_nt/core/util/auth_failure_mapping.dart';
import 'package:terra_nt/data/models/auth_failure.dart';

void main() {
  group('failureForCode', () {
    test('maps every credential code the table lists', () {
      for (final code in const [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'user-disabled',
        'INVALID_LOGIN_CREDENTIALS',
      ]) {
        expect(
          failureForCode(code),
          AuthFailure.invalidCredential,
          reason: '$code must map to invalidCredential',
        );
      }
    });

    test('maps each remaining row of the table', () {
      expect(
        failureForCode('email-already-in-use'),
        AuthFailure.emailAlreadyInUse,
      );
      expect(failureForCode('weak-password'), AuthFailure.weakPassword);
      expect(failureForCode('invalid-email'), AuthFailure.invalidEmail);
      expect(failureForCode('network-request-failed'), AuthFailure.network);
      expect(failureForCode('too-many-requests'), AuthFailure.tooManyRequests);
      expect(
        failureForCode('requires-recent-login'),
        AuthFailure.requiresRecentLogin,
      );
    });

    test('falls back to unknown for anything else', () {
      expect(failureForCode('operation-not-allowed'), AuthFailure.unknown);
      expect(failureForCode(''), AuthFailure.unknown);
      expect(failureForCode('WRONG-PASSWORD'), AuthFailure.unknown);
    });

    test(
      'no code maps to cancelled, which only a dismissed sheet produces',
      () {
        for (final code in const [
          'invalid-credential',
          'email-already-in-use',
          'weak-password',
          'invalid-email',
          'network-request-failed',
          'too-many-requests',
          'requires-recent-login',
          'anything-else',
        ]) {
          expect(failureForCode(code), isNot(AuthFailure.cancelled));
        }
      },
    );
  });

  group('failureForGoogleCode', () {
    test('covers every GoogleSignInExceptionCode value', () {
      for (final code in GoogleSignInExceptionCode.values) {
        final expected = code == GoogleSignInExceptionCode.canceled
            ? AuthFailure.cancelled
            : AuthFailure.unknown;
        expect(
          failureForGoogleCode(code),
          expected,
          reason: '$code must map to $expected',
        );
      }
    });
  });
}
