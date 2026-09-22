import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/profile/account/account_screen.dart';

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final Session session;

  @override
  Session build() => session;
}

/// Scripts [isEmailVerified] with a caller-supplied future so a widget test
/// can observe the pending state before it resolves, or throws.
class _ScriptedVerificationAuthRepository implements AuthRepository {
  _ScriptedVerificationAuthRepository(this.isEmailVerifiedResult);

  final Future<bool> Function() isEmailVerifiedResult;

  @override
  Future<bool> isEmailVerified() => isEmailVerifiedResult();

  @override
  Future<String?> currentEmail() async => null;

  @override
  Future<String?> currentUid() async => null;

  @override
  Future<String?> idToken() async => null;

  @override
  Future<Session> signInWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<Session> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Session> createAccount(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}
}

void main() {
  Future<ProviderContainer> pumpAccount(
    WidgetTester tester, {
    Session session = const Session(
      email: 'traveller@example.com',
      onboardingDone: true,
    ),
    AuthRepository? authRepository,
  }) async {
    final container = ProviderContainer(
      overrides: [
        sessionNotifierProvider.overrideWith(
          () => _FixedSessionNotifier(session),
        ),
        authRepositoryProvider.overrideWithValue(
          authRepository ?? InMemoryAuthRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const AccountScreen()),
      ),
    );
    return container;
  }

  testWidgets('renders account identity and session email', (tester) async {
    await pumpAccount(tester);

    expect(find.text('NT Explorer'), findsOneWidget);
    expect(find.text('traveller@example.com'), findsOneWidget);
  });

  testWidgets('uses the fallback email when the session email is empty', (
    tester,
  ) async {
    await pumpAccount(
      tester,
      session: const Session(email: '', onboardingDone: true),
    );

    expect(find.text('explorer@example.com'), findsOneWidget);
  });

  testWidgets('is read-only and has no text field or save button', (
    tester,
  ) async {
    await pumpAccount(tester);

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('back button returns to Profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionNotifierProvider.overrideWith(
            () => _FixedSessionNotifier(
              const Session(
                email: 'traveller@example.com',
                onboardingDone: true,
              ),
            ),
          ),
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => settings.name == '/account'
                  ? const AccountScreen()
                  : const Scaffold(body: Text('Profile')),
              settings: settings,
            ),
            initialRoute: '/',
          ),
        ),
      ),
    );
    Navigator.of(tester.element(find.text('Profile'))).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-screen')), findsNothing);
  });

  testWidgets('fits at 360px without a layout exception', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpAccount(tester);
    expect(tester.takeException(), isNull);
  });

  group('email verification', () {
    testWidgets(
      'not verified shows the row and resend, then the caption after tap',
      (tester) async {
        final repository = InMemoryAuthRepository()..emailVerified = false;
        await pumpAccount(tester, authRepository: repository);
        await tester.pump();

        expect(find.text('Email verification'), findsOneWidget);
        expect(find.text('Not verified'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('account-resend-verification')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('account-resend-verification')),
        );
        await tester.pump();
        await tester.pump();

        expect(repository.verificationEmailsSent, 1);
        expect(find.text('Verification email sent.'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('account-resend-verification')),
          findsNothing,
        );
      },
    );

    testWidgets('verified shows the row with no resend button', (
      tester,
    ) async {
      final repository = InMemoryAuthRepository()..emailVerified = true;
      await pumpAccount(tester, authRepository: repository);
      await tester.pump();

      expect(find.text('Verified'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-resend-verification')),
        findsNothing,
      );
    });

    testWidgets('a network failure shows the network copy and keeps the button', (
      tester,
    ) async {
      final repository = InMemoryAuthRepository()
        ..emailVerified = false
        ..nextFailure = AuthFailure.network;
      await pumpAccount(tester, authRepository: repository);
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('account-resend-verification')),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No connection. Check your signal and try again.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-resend-verification')),
        findsOneWidget,
      );
      expect(find.text('Resend email'), findsOneWidget);
      expect(repository.verificationEmailsSent, 0);
    });

    testWidgets(
      'shows Checking... while pending, then the resolved value',
      (tester) async {
        final completer = Completer<bool>();
        final repository = _ScriptedVerificationAuthRepository(
          () => completer.future,
        );
        await pumpAccount(tester, authRepository: repository);
        await tester.pump();

        expect(find.text('Checking…'), findsOneWidget);
        expect(find.text('Not verified'), findsNothing);

        completer.complete(false);
        await tester.pump();
        await tester.pump();

        expect(find.text('Checking…'), findsNothing);
        expect(find.text('Not verified'), findsOneWidget);
      },
    );

    testWidgets('the value line is empty when the read throws AuthException', (
      tester,
    ) async {
      final repository = _ScriptedVerificationAuthRepository(
        () => throw AuthException(AuthFailure.network),
      );
      await pumpAccount(tester, authRepository: repository);
      await tester.pump();
      await tester.pump();

      expect(find.text('Checking…'), findsNothing);
      expect(find.text('Not verified'), findsNothing);
      expect(find.text('Verified'), findsNothing);
    });
  });
}
