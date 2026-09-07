import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final Session session;

  @override
  Session build() => session;
}

Future<PreferencesStore> _mockStore() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

Future<ProviderContainer> _pumpLogin(
  WidgetTester tester, {
  Session session = const Session(email: null, onboardingDone: false),
}) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      sessionNotifierProvider.overrideWith(
        () => _FixedSessionNotifier(session),
      ),
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

Future<ProviderContainer> _pumpWelcome(WidgetTester tester) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [preferencesStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.dark, home: const WelcomeScreen()),
    ),
  );
  return container;
}

Future<void> _completeNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _emailField() => find.descendant(
  of: find.byKey(const ValueKey('login-email-input')),
  matching: find.byType(TextField),
);

Finder _passwordField() => find.descendant(
  of: find.byKey(const ValueKey('login-password-input')),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('login renders exact copy without bottom navigation', (
    tester,
  ) async {
    await _pumpLogin(tester);

    expect(find.text('Terra NT'), findsOneWidget);
    expect(find.text('Discover the Northern Territory.'), findsOneWidget);
    expect(find.text('Start Exploring'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets('invalid submit shows both errors and focuses email', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(tester.widget<TextField>(_emailField()).focusNode!.hasFocus, isTrue);
  });

  testWidgets(
    'email error clears independently and empty password is focused',
    (tester) async {
      await _pumpLogin(tester);

      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      await tester.enterText(_emailField(), 'traveller@example.com');
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(find.text('Enter your password.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      expect(
        tester.widget<TextField>(_passwordField()).focusNode!.hasFocus,
        isTrue,
      );
    },
  );

  testWidgets('email sign-in stores the typed email and shows welcome', (
    tester,
  ) async {
    final container = await _pumpLogin(tester);
    await tester.enterText(_emailField(), 'traveller@example.com');
    await tester.enterText(_passwordField(), 'secret');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await _completeNavigation(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      container.read(sessionNotifierProvider).email,
      'traveller@example.com',
    );
  });

  testWidgets('google sign-in stores the mock identity and shows welcome', (
    tester,
  ) async {
    final container = await _pumpLogin(tester);
    await tester.tap(find.byKey(const ValueKey('login-google')));
    await _completeNavigation(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(
      container.read(sessionNotifierProvider).email,
      'explorer@example.com',
    );
  });

  testWidgets('welcome copy and actions fit without bottom navigation', (
    tester,
  ) async {
    await _pumpWelcome(tester);

    expect(find.text('Welcome to Terra NT'), findsOneWidget);
    expect(
      find.text(
        "Answer a few quick questions and we'll build a route across the Territory for you — or skip straight to exploring on your own.",
      ),
      findsOneWidget,
    );
    expect(find.text('Create My Route'), findsOneWidget);
    expect(find.text('Skip for Now'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets('create route resets onboarding step and opens onboarding', (
    tester,
  ) async {
    final container = await _pumpWelcome(tester);
    container.read(onboardingNotifierProvider.notifier).setStep(2);

    await tester.tap(find.byKey(const ValueKey('welcome-create-route')));
    await _completeNavigation(tester);

    expect(find.byKey(const ValueKey('screen-onboarding')), findsOneWidget);
    expect(container.read(onboardingNotifierProvider).currentStep, 0);
  });

  testWidgets('skip marks onboarding done without creating a saved route', (
    tester,
  ) async {
    final container = await _pumpWelcome(tester);
    final before = List.of(container.read(savedRoutesNotifierProvider));

    await tester.tap(find.byKey(const ValueKey('welcome-skip')));
    await _completeNavigation(tester);

    expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
    expect(container.read(savedRoutesNotifierProvider), before);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('both screens fit at 360px without layout exceptions', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await _pumpLogin(tester);
    expect(tester.takeException(), isNull);
    await _pumpWelcome(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ambient backdrop is disposed when login is popped', (
    tester,
  ) async {
    await _pumpLogin(tester);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seeded routes remain unchanged when skip is selected', (
    tester,
  ) async {
    final container = await _pumpWelcome(tester);
    expect(container.read(savedRoutesNotifierProvider), seedSavedRoutes);
    await tester.tap(find.byKey(const ValueKey('welcome-skip')));
    await _completeNavigation(tester);
    expect(container.read(savedRoutesNotifierProvider), seedSavedRoutes);
  });
}
