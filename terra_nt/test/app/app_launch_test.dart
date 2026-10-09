import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/app/app_launch.dart';
import 'package:terra_nt/app/routes.dart';
import 'package:terra_nt/app/screen_routes.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/loading/loading_screen.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';

void main() {
  /// The signed-in email now comes from the auth seam, not a preferences key:
  /// Firebase persists its own user, so a cold start is seeded by giving the
  /// in-memory repository a successful sign-in. `email: null` seeds nobody
  /// signed in, which is the contract's Login row.
  Future<void> pumpLaunch(
    WidgetTester tester, {
    required bool onboardingDone,
    String? email,
  }) async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.onboardingDoneKey: onboardingDone,
    });
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesStore(preferences: () async => preferences);
    final authRepository = InMemoryAuthRepository();
    if (email != null) {
      await authRepository.signInWithEmail(email, 'seeded');
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const AppLaunch()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('nobody signed in lands on Login regardless of onboarding', (
    tester,
  ) async {
    await pumpLaunch(tester, onboardingDone: false);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets(
    'nobody signed in lands on Login even when onboarding was already done',
    (tester) async {
      await pumpLaunch(tester, onboardingDone: true);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    },
  );

  testWidgets('signed in but not onboarded opens onboarding', (
    tester,
  ) async {
    await pumpLaunch(
      tester,
      onboardingDone: false,
      email: 'explorer@example.com',
    );

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('returning user opens Explore from persisted onboarding state', (
    tester,
  ) async {
    await pumpLaunch(
      tester,
      onboardingDone: true,
      email: 'returning@example.com',
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
  });

  testWidgets('returning user Back retraces tabs before leaving the app', (
    tester,
  ) async {
    final popped = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') popped.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpLaunch(
      tester,
      onboardingDone: true,
      email: 'returning@example.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-3')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(popped, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(popped, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, ['SystemNavigator.pop']);
    expect(tester.takeException(), isNull);
  });

  Future<void> signUpToWelcome(WidgetTester tester) async {
    await pumpLaunch(tester, onboardingDone: false);

    await tester.tap(find.byKey(const ValueKey('login-sign-up')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    Finder input(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(
      input('create-account-email-input'),
      'new@example.com',
    );
    await tester.enterText(input('create-account-password-input'), 'secret1');
    await tester.enterText(
      input('create-account-confirmation-input'),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('create-account-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WelcomeScreen), findsOneWidget);
  }

  testWidgets('a new account reaches the real onboarding from Welcome', (
    tester,
  ) async {
    await signUpToWelcome(tester);

    await tester.tap(find.byKey(const ValueKey('welcome-create-route')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AppPlaceholderScreen), findsNothing);
  });

  testWidgets('system Back on Welcome after sign-up leaves the app, not to Login', (
    tester,
  ) async {
    final popped = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') popped.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await signUpToWelcome(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(popped, ['SystemNavigator.pop']);
  });

  testWidgets('system Back on Login at cold start stays on Login', (
    tester,
  ) async {
    final popped = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') popped.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpLaunch(tester, onboardingDone: false);

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Scaffold), findsWidgets);
  });

  testWidgets('system Back reaches the pre-onboarding stack', (tester) async {
    await pumpLaunch(
      tester,
      onboardingDone: false,
      email: 'explorer@example.com',
    );

    // The platform gesture, not the on-screen control: it arrives at the root
    // navigator, which holds AppLaunch and nothing else.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('system Back at the stack root leaves the app to Android', (
    tester,
  ) async {
    final popped = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') popped.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpLaunch(
      tester,
      onboardingDone: false,
      email: 'explorer@example.com',
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(popped, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(popped, ['SystemNavigator.pop']);
  });

  testWidgets('loading completion opens Result without AppLaunch taking over', (
    tester,
  ) async {
    final popped = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') popped.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpLaunch(
      tester,
      onboardingDone: false,
      email: 'explorer@example.com',
    );

    final onboardingContext = tester.element(find.byType(OnboardingScreen));
    Navigator.of(onboardingContext)
        .pushReplacement(rootScreenRoute(AppRoute.loading));
    await tester.pump();
    expect(find.byType(LoadingScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 7000));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);

    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(popped, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, ['SystemNavigator.pop']);
    expect(tester.takeException(), isNull);
  });
}
