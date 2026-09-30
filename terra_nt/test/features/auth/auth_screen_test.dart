import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/theme/spacing.dart';
import 'package:terra_nt/data/models/auth_failure.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';
import 'package:terra_nt/shared/widgets/journey_scene.dart';

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
  AuthRepository? authRepository,
}) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      // The real provider is Firebase, which needs an initialised app; the
      // seam's in-memory implementation is what the screen is tested against.
      authRepositoryProvider.overrideWithValue(
        authRepository ?? InMemoryAuthRepository(),
      ),
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

Future<ProviderContainer> _pumpWelcome(
  WidgetTester tester, {
  double textScale = 1,
  WelcomeScreen screen = const WelcomeScreen(),
}) async {
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
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
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

  testWidgets('the Google button is the inverse variant with the G logo', (
    tester,
  ) async {
    await _pumpLogin(tester);

    expect(_buttonAt(tester, 'login-google').variant, AppButtonVariant.inverse);

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('login-google')),
        matching: find.byType(Image),
      ),
    );
    final assetImage = image.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/google_g.png');
  });

  testWidgets('login anchors its form and centres its header at 393x852', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(393, 852);
    view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
    view.padding = const FakeViewPadding(top: 24, bottom: 34);
    addTearDown(view.reset);

    await _pumpLogin(tester);
    // Measured where the entrance leaves everything, not mid-rise.
    await tester.pump(const Duration(seconds: 1));

    final forgotPasswordLink = tester.getRect(
      find.byKey(const ValueKey('login-forgot-password')),
    );
    expect(
      forgotPasswordLink.bottom,
      852 - 34 - AppMetrics.loginBottomPadding,
    );

    // The header block opens with the brand mark and starts right under the
    // status bar: its own padding is the only space above it.
    final mark = tester.getRect(
      find.byKey(const ValueKey('login-brand-mark')),
    );
    final subtitle = tester.getRect(
      find.text('Discover the Northern Territory.'),
    );
    final email = tester.getRect(
      find.byKey(const ValueKey('login-email-input')),
    );
    final headerTopSpace = mark.top - 24;
    final headerBottomSpace = email.top - subtitle.bottom;
    expect(headerTopSpace, closeTo(headerBottomSpace, 1));
    expect(headerBottomSpace, greaterThanOrEqualTo(AppSpacing.lg));
    expect(tester.takeException(), isNull);
  });

  testWidgets('login shows the brand mark above its title', (tester) async {
    await _pumpLogin(tester);

    final markFinder = find.byKey(const ValueKey('login-brand-mark'));
    expect(markFinder, findsOneWidget);
    final mark = tester.widget<Image>(markFinder);
    expect(
      (mark.image as AssetImage).assetName,
      'assets/images/brand_mark.png',
    );
    expect(
      tester.getRect(markFinder).bottom,
      lessThan(tester.getRect(find.text('Terra NT')).top),
    );
  });

  testWidgets('login content arrives in order rather than appearing', (
    tester,
  ) async {
    await _pumpLogin(tester);

    double opacityOf(Finder finder) => tester
        .widget<Opacity>(
          find.ancestor(of: finder, matching: find.byType(Opacity)).first,
        )
        .opacity;
    final title = find.text('Terra NT');
    final footer = find.byKey(const ValueKey('login-forgot-password'));

    expect(opacityOf(title), lessThan(1));
    expect(opacityOf(footer), lessThan(1));

    // The title block leads; the footer is still waiting on its stagger.
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacityOf(title), greaterThan(opacityOf(footer)));

    await tester.pump(const Duration(seconds: 1));
    expect(opacityOf(title), 1);
    expect(opacityOf(footer), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login scrolls without overflow above a 400px keyboard', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(360, 640);
    view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    view.padding = const FakeViewPadding(top: 24);
    view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(view.reset);

    await _pumpLogin(tester);

    final scrollView = find.byType(SingleChildScrollView);
    await tester.drag(scrollView, const Offset(0, -80));
    await tester.pump();
    final position = tester
        .state<ScrollableState>(
          find
              .descendant(of: scrollView, matching: find.byType(Scrollable))
              .first,
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
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
    expect(find.byType(JourneyScene), findsOneWidget);
    expect(
      tester.getRect(find.byType(JourneyScene)).bottom,
      lessThan(tester.getRect(find.text('Welcome to Terra NT')).top),
    );
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets('the welcome message arrives rather than appears', (
    tester,
  ) async {
    await _pumpWelcome(tester);

    double cardOpacity() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.text('Welcome to Terra NT'),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(cardOpacity(), lessThan(1));

    await tester.pump(const Duration(seconds: 1));
    expect(cardOpacity(), 1);
    // Mid-entrance or not, the actions answer taps.
    expect(
      find.byKey(const ValueKey('welcome-create-route')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final height in [640.0, 400.0]) {
    testWidgets('welcome actions are reachable at 360x$height and 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(360, height);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.reset);
      var created = 0;
      var skipped = 0;
      final container = await _pumpWelcome(
        tester,
        textScale: 2,
        screen: WelcomeScreen(
          onCreateRoute: () => created++,
          onSkip: () => skipped++,
        ),
      );
      await tester.pumpAndSettle();
      for (final key in ['welcome-create-route', 'welcome-skip']) {
        final action = find.byKey(ValueKey(key));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(height - 34));
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(created, 1);
      expect(skipped, 1);
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
    });
  }

  testWidgets('the login brand mark folds away while the keyboard is up', (
    tester,
  ) async {
    final view = tester.view;
    view.devicePixelRatio = 1;
    view.physicalSize = const Size(411, 914);
    addTearDown(view.reset);
    await _pumpLogin(tester);
    await tester.pump(const Duration(seconds: 1));

    final title = find.text('Terra NT');
    final titleTop = tester.getRect(title).top;

    view.viewInsets = const FakeViewPadding(bottom: 383);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Folded: the title is the first thing in the header.
    final mark = find.byKey(const ValueKey('login-brand-mark'));
    final clip = find.ancestor(of: mark, matching: find.byType(ClipRect)).first;
    expect(tester.getSize(clip).height, 0);
    expect(tester.getRect(title).top, lessThan(titleTop));
    expect(tester.takeException(), isNull);
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

  group('sign-in failures', () {
    Future<void> submitValidCredentials(WidgetTester tester) async {
      await tester.enterText(_emailField(), 'traveller@example.com');
      await tester.enterText(_passwordField(), 'secret');
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      await tester.pump();
    }

    Future<void> pumpWithFailure(
      WidgetTester tester,
      AuthFailure failure,
    ) async {
      await _pumpLogin(
        tester,
        authRepository: InMemoryAuthRepository()..nextFailure = failure,
      );
    }

    testWidgets('invalid credentials land under the password field', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.invalidCredential);

      await submitValidCredentials(tester);

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('a network failure lands under the password field', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.network);

      await submitValidCredentials(tester);

      expect(
        find.text('No connection. Check your signal and try again.'),
        findsOneWidget,
      );
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('an invalid email from the provider lands under the email', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.invalidEmail);

      await submitValidCredentials(tester);

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Email or password is incorrect.'), findsNothing);
    });

    testWidgets('too many attempts and unknown have their own copy', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.tooManyRequests);
      await submitValidCredentials(tester);
      expect(find.text('Too many attempts. Try again later.'), findsOneWidget);

      await pumpWithFailure(tester, AuthFailure.unknown);
      await submitValidCredentials(tester);
      expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    });

    testWidgets('a Google failure reports itself in the password slot', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.unknown);

      await tester.tap(find.byKey(const ValueKey('login-google')));
      await tester.pump();
      await tester.pump();

      expect(
        find.text("Google sign-in didn't work. Try again."),
        findsOneWidget,
      );
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('a cancelled Google sheet leaves the form untouched', (
      tester,
    ) async {
      await pumpWithFailure(tester, AuthFailure.cancelled);

      await tester.tap(find.byKey(const ValueKey('login-google')));
      await tester.pump();
      await tester.pump();

      expect(find.text("Google sign-in didn't work. Try again."), findsNothing);
      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(find.text('Enter your password.'), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('submit is disabled in flight and enabled again on failure', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pumpLogin(tester, authRepository: _GatedAuthRepository(gate));

      await tester.enterText(_emailField(), 'traveller@example.com');
      await tester.enterText(_passwordField(), 'secret');
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();

      expect(_buttonAt(tester, 'login-submit').onPressed, isNull);
      expect(_buttonAt(tester, 'login-google').onPressed, isNull);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(_buttonAt(tester, 'login-submit').onPressed, isNotNull);
    });
  });

  group('forgot password', () {
    // The link closes the form, below the brand mark and every action; on the
    // default 800x600 test view it sits under the fold, as on a short phone.
    Future<void> tapForgotPassword(WidgetTester tester) async {
      final link = find.byKey(const ValueKey('login-forgot-password'));
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link);
    }

    testWidgets('an empty email shows the reset copy and sends nothing', (
      tester,
    ) async {
      final repository = InMemoryAuthRepository();
      await _pumpLogin(tester, authRepository: repository);

      await tapForgotPassword(tester);
      await tester.pump();

      expect(
        find.text('Enter your email to reset your password.'),
        findsOneWidget,
      );
      expect(repository.lastResetEmail, isNull);
    });

    testWidgets('a valid email sends the reset mail and shows the caption', (
      tester,
    ) async {
      final repository = InMemoryAuthRepository();
      await _pumpLogin(tester, authRepository: repository);

      await tester.enterText(_emailField(), 'traveller@example.com');
      await tapForgotPassword(tester);
      await tester.pump();
      await tester.pump();

      expect(repository.lastResetEmail, 'traveller@example.com');
      expect(
        find.text('Check your email for a reset link.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('login-forgot-password')),
        findsNothing,
      );
    });

    testWidgets('a network failure shows the network copy under the password', (
      tester,
    ) async {
      await _pumpLogin(
        tester,
        authRepository: InMemoryAuthRepository()
          ..nextFailure = AuthFailure.network,
      );

      await tester.enterText(_emailField(), 'traveller@example.com');
      await tapForgotPassword(tester);
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No connection. Check your signal and try again.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('login-forgot-password')),
        findsOneWidget,
      );
    });
  });
}

AppButton _buttonAt(WidgetTester tester, String key) =>
    tester.widget<AppButton>(find.byKey(ValueKey(key)));

/// Holds a sign-in open until the test releases it, then fails it. Nothing else
/// lets a widget test observe the in-flight state.
class _GatedAuthRepository extends InMemoryAuthRepository {
  _GatedAuthRepository(this._gate);

  final Completer<void> _gate;

  @override
  Future<Session> signInWithEmail(String email, String password) async {
    await _gate.future;
    throw const AuthException(AuthFailure.invalidCredential);
  }
}
