import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/auth/create_account_screen.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';

Future<PreferencesStore> _mockStore() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

Future<ProviderContainer> _pumpLogin(WidgetTester tester) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
    ),
  );
  return container;
}

Future<ProviderContainer> _pumpCreateAccount(
  WidgetTester tester, {
  double textScale = 1,
  AuthRepository? authRepository,
}) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      authRepositoryProvider.overrideWithValue(
        authRepository ?? InMemoryAuthRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const CreateAccountScreen(),
      ),
    ),
  );
  return container;
}

Finder _input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

Finder get _emailInput => _input('create-account-email-input');
Finder get _passwordInput => _input('create-account-password-input');
Finder get _confirmationInput => _input('create-account-confirmation-input');

Future<void> _completeNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _CountingAuthRepository extends InMemoryAuthRepository {
  var createAccountCalls = 0;
  var signInWithEmailCalls = 0;
  String? _email;

  @override
  Future<String?> currentEmail() async => _email;

  @override
  Future<Session> createAccount(String email, String password) async {
    createAccountCalls++;
    _email = email;
    return Session(email: email, onboardingDone: false);
  }

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    signInWithEmailCalls++;
    _email = email;
    return Session(email: email, onboardingDone: false);
  }

  @override
  Future<Session> signInWithGoogle() async =>
      const Session(email: 'explorer@example.com', onboardingDone: false);

  @override
  Future<void> signOut() async {
    _email = null;
  }

  @override
  Future<void> deleteAccount() async {
    _email = null;
  }
}

/// Holds create-account open until the test releases it, then fails it.
class _GatedAuthRepository extends InMemoryAuthRepository {
  _GatedAuthRepository(this._gate);

  final Completer<void> _gate;

  @override
  Future<Session> createAccount(String email, String password) async {
    await _gate.future;
    throw const AuthException(AuthFailure.emailAlreadyInUse);
  }
}

void main() {
  testWidgets(
    'login opens create account and its sign-in link returns to login',
    (tester) async {
      await _pumpLogin(tester);

      await tester.tap(find.byKey(const ValueKey('login-sign-up')));
      await _completeNavigation(tester);
      expect(find.byType(CreateAccountScreen), findsOneWidget);

      final signInLink = find.byKey(const ValueKey('create-account-sign-in'));
      await tester.ensureVisible(signInLink);
      await tester.tap(signInLink);
      await _completeNavigation(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CreateAccountScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('create account shows the brand mark above its title', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    final markFinder = find.byKey(const ValueKey('create-account-brand-mark'));
    expect(markFinder, findsOneWidget);
    final mark = tester.widget<Image>(markFinder);
    expect(
      (mark.image as AssetImage).assetName,
      'assets/images/brand_mark.png',
    );
    expect(
      tester.getRect(markFinder).bottom,
      lessThan(tester.getRect(find.text('Create account')).top),
    );
  });

  testWidgets('the brand mark folds away while the keyboard is up', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(411, 914);
    addTearDown(view.reset);
    await _pumpCreateAccount(tester);
    await tester.pump(const Duration(seconds: 1));

    // The visible part of the mark is the clip around it.
    double markHeight() => tester
        .getSize(
          find
              .ancestor(
                of: find.byKey(const ValueKey('create-account-brand-mark')),
                matching: find.byType(ClipRect),
              )
              .first,
        )
        .height;
    final open = markHeight();
    expect(open, greaterThan(0));

    view.viewInsets = const FakeViewPadding(bottom: 383);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(markHeight(), 0);
    expect(tester.takeException(), isNull);

    view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(markHeight(), open);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create account renders its exact copy without login-only UI', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    expect(find.text('Create account'), findsOneWidget);
    expect(
      find.text('Start exploring the Northern Territory.'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('login renders its exact sign-up link', (tester) async {
    await _pumpLogin(tester);

    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });

  testWidgets('empty submit shows every error and focuses email', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    await tester.tap(find.byKey(const ValueKey('create-account-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
    expect(find.text('Confirm your password.'), findsOneWidget);
    expect(tester.widget<TextField>(_emailInput).focusNode!.hasFocus, isTrue);
  });

  testWidgets('empty confirmation and mismatch have distinct errors', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    await tester.enterText(_emailInput, 'traveller@example.com');
    await tester.enterText(_passwordInput, 'secret');

    await tester.tap(find.byKey(const ValueKey('create-account-submit')));
    await tester.pump();
    expect(find.text('Confirm your password.'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);

    await tester.enterText(_confirmationInput, 'different');
    await tester.tap(find.byKey(const ValueKey('create-account-submit')));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('errors wait for submit and clear independently after edits', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    await tester.enterText(_emailInput, 'not an email');
    await tester.tap(_passwordInput);
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsNothing);
    expect(find.text('Enter a password.'), findsNothing);
    expect(find.text('Confirm your password.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('create-account-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
    expect(find.text('Confirm your password.'), findsOneWidget);

    await tester.enterText(_emailInput, 'traveller@example.com');
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsNothing);
    expect(find.text('Enter a password.'), findsOneWidget);
    expect(find.text('Confirm your password.'), findsOneWidget);
  });

  testWidgets('valid submit creates the typed session once, storing no key', (
    tester,
  ) async {
    final repository = _CountingAuthRepository();
    final container = await _pumpCreateAccount(
      tester,
      authRepository: repository,
    );
    await tester.enterText(_emailInput, 'traveller@example.com');
    await tester.enterText(_passwordInput, 'secret');
    await tester.enterText(_confirmationInput, 'secret');

    await tester.tap(find.byKey(const ValueKey('create-account-submit')));
    await _completeNavigation(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      container.read(sessionNotifierProvider).email,
      'traveller@example.com',
    );
    expect(repository.createAccountCalls, 1);
    expect(repository.signInWithEmailCalls, 0);

    // The email lives in the auth provider now, not in preferences, so creating
    // an account writes no key at all.
    expect(await repository.currentEmail(), 'traveller@example.com');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), isEmpty);
  });

  testWidgets('create account fits at narrow and keyboard-constrained sizes', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(320, 800);
    addTearDown(view.reset);

    await _pumpCreateAccount(tester, textScale: 1.5);
    expect(tester.takeException(), isNull);

    view.physicalSize = const Size(360, 640);
    view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    view.padding = const FakeViewPadding(top: 24);
    view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pump();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -80));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('popping create account disposes its controllers and backdrop', (
    tester,
  ) async {
    await _pumpLogin(tester);
    await tester.pump(const Duration(milliseconds: 1000));
    final callbacksBeforePush = tester.binding.transientCallbackCount;
    await tester.tap(find.byKey(const ValueKey('login-sign-up')));
    await _completeNavigation(tester);
    await tester.pump(const Duration(milliseconds: 1000));

    final signInLink = find.byKey(const ValueKey('create-account-sign-in'));
    await tester.ensureVisible(signInLink);
    await tester.tap(signInLink);
    await _completeNavigation(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(CreateAccountScreen), findsNothing);
    expect(tester.binding.transientCallbackCount, callbacksBeforePush);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  test(
    'create account mirrors email sign-in without persisting a third key',
    () async {
      final preferences = await _mockStore();
      final repository = InMemoryAuthRepository();

      final created = await repository.createAccount(
        'traveller@example.com',
        'secret',
      );
      final signedIn = await repository.signInWithEmail(
        'traveller@example.com',
        'secret',
      );

      expect(created.email, 'traveller@example.com');
      expect(created.onboardingDone, isFalse);
      expect(signedIn.email, created.email);
      expect(signedIn.onboardingDone, created.onboardingDone);
      expect(await preferences.readOnboardingDone(), isFalse);
      final sharedPreferences = await SharedPreferences.getInstance();
      expect(sharedPreferences.getKeys(), isEmpty);
    },
  );

  test(
    'session notifier preserves onboarding while creating an account',
    () async {
      final store = await _mockStore();
      final repository = _CountingAuthRepository();
      final container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sessionNotifierProvider.notifier);
      await notifier.setOnboardingDone(true);
      await notifier.createAccount('traveller@example.com', 'secret');

      expect(
        container.read(sessionNotifierProvider).email,
        'traveller@example.com',
      );
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      expect(repository.createAccountCalls, 1);
      expect(repository.signInWithEmailCalls, 0);
      expect(await store.readOnboardingDone(), isTrue);
    },
  );

  group('create-account failures', () {
    Future<void> submitValidForm(WidgetTester tester) async {
      await tester.enterText(_emailInput, 'traveller@example.com');
      await tester.enterText(_passwordInput, 'secret');
      await tester.enterText(_confirmationInput, 'secret');
      await tester.tap(find.byKey(const ValueKey('create-account-submit')));
      await tester.pump();
      await tester.pump();
    }

    Future<void> pumpWithFailure(
      WidgetTester tester,
      AuthFailure failure,
    ) async {
      await _pumpCreateAccount(
        tester,
        authRepository: InMemoryAuthRepository()..nextFailure = failure,
      );
    }

    testWidgets('an existing email lands under the email field', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.emailAlreadyInUse);

      await submitValidForm(tester);

      expect(
        find.text('An account already exists for this email.'),
        findsOneWidget,
      );
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('a weak password lands under the password field', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.weakPassword);

      await submitValidForm(tester);

      expect(find.text('Use at least 6 characters.'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('network, rate limit and unknown land on the last field', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.network);
      await submitValidForm(tester);
      expect(
        find.text('No connection. Check your signal and try again.'),
        findsOneWidget,
      );

      await pumpWithFailure(tester, AuthFailure.tooManyRequests);
      await submitValidForm(tester);
      expect(find.text('Too many attempts. Try again later.'), findsOneWidget);

      await pumpWithFailure(tester, AuthFailure.unknown);
      await submitValidForm(tester);
      expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    });

    testWidgets('submit is disabled in flight and enabled again on failure', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pumpCreateAccount(
        tester,
        authRepository: _GatedAuthRepository(gate),
      );
      await tester.enterText(_emailInput, 'traveller@example.com');
      await tester.enterText(_passwordInput, 'secret');
      await tester.enterText(_confirmationInput, 'secret');

      await tester.tap(find.byKey(const ValueKey('create-account-submit')));
      await tester.pump();
      final submit = find.byKey(const ValueKey('create-account-submit'));
      expect(tester.widget<AppButton>(submit).onPressed, isNull);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('An account already exists for this email.'),
        findsOneWidget,
      );
      expect(tester.widget<AppButton>(submit).onPressed, isNotNull);
    });

    testWidgets('the client-side checks still run before the repository', (
      tester,
    ) async {
      final repository = _CountingAuthRepository();
      await _pumpCreateAccount(tester, authRepository: repository);

      await tester.tap(find.byKey(const ValueKey('create-account-submit')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(repository.createAccountCalls, 0);
    });
  });
}
