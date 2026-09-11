import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/auth/create_account_screen.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';

Future<PreferencesStore> _mockStore() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

Future<ProviderContainer> _pumpLogin(WidgetTester tester) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [preferencesStoreProvider.overrideWithValue(store)],
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
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
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

class _CountingAuthRepository implements AuthRepository {
  var createAccountCalls = 0;
  var signInWithEmailCalls = 0;

  @override
  Future<Session> createAccount(String email, String password) async {
    createAccountCalls++;
    return Session(email: email, onboardingDone: false);
  }

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    signInWithEmailCalls++;
    return Session(email: email, onboardingDone: false);
  }

  @override
  Future<Session> signInWithGoogle() async =>
      const Session(email: 'explorer@example.com', onboardingDone: false);

  @override
  Future<void> signOut() async {}
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

  testWidgets('valid submit creates and persists the typed session once', (
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

    final persisted = await container
        .read(preferencesStoreProvider)
        .readSession();
    expect(persisted.email, 'traveller@example.com');
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys(),
      unorderedEquals([
        PreferencesStore.sessionKey,
        PreferencesStore.onboardingDoneKey,
      ]),
    );
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
    'create account mirrors email sign-in without persisting a fourth key',
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
      final stored = await preferences.readSession();
      expect(stored.email, isNull);
      expect(stored.onboardingDone, isFalse);
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
      final persisted = await store.readSession();
      expect(persisted.email, 'traveller@example.com');
      expect(persisted.onboardingDone, isTrue);
    },
  );
}
