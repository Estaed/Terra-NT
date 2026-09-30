import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:terra_nt/app/routes.dart';
import 'package:terra_nt/app/screen_routes.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/seed/onboarding_options.dart';
import 'package:terra_nt/data/repositories/itinerary_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/auth/welcome_screen.dart';
import 'package:terra_nt/features/loading/loading_screen.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/features/onboarding/steps/onboarding_steps.dart';
import 'package:terra_nt/shared/map/route_car_backdrop.dart';

/// A representative phone viewport. Every dimension here is a logical pixel.
const _viewport = Size(360, 640);

/// Representative Android system-UI insets: a status bar and a gesture bar.
const _topInset = 24.0;
const _bottomInset = 48.0;

/// A representative soft-keyboard height.
const _keyboardInset = 280.0;

/// Simulates a system back, like a back gesture on Android. This mirrors the
/// helper the framework uses in its own `PopScope` tests: it sends the platform
/// channel message the engine sends when it receives a system back.
Future<void> _simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/navigation',
        const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'method': 'popRoute',
        }),
        (ByteData? _) {},
      );
}

/// Puts the test view on [_viewport] with system-UI insets applied.
///
/// When [keyboard] is non-zero the bottom padding collapses to zero, because a
/// visible IME covers the gesture bar — that is what the engine reports.
void _useMobileViewport(WidgetTester tester, {double keyboard = 0}) {
  final view = tester.view;
  view.devicePixelRatio = 1;
  view.physicalSize = _viewport;
  view.viewPadding = const FakeViewPadding(
    top: _topInset,
    bottom: _bottomInset,
  );
  view.padding = FakeViewPadding(
    top: _topInset,
    bottom: keyboard > 0 ? 0 : _bottomInset,
  );
  view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(view.reset);
}

/// The region of the viewport that system UI does not cover.
Rect _safeRegion({double keyboard = 0}) => Rect.fromLTRB(
  0,
  _topInset,
  _viewport.width,
  _viewport.height - (keyboard > 0 ? keyboard : _bottomInset),
);

/// Fails when [finder] cannot be brought fully inside the usable region.
///
/// Scrolling first is deliberate: a screen is allowed to place an action below
/// the fold as long as the action can be reached. What is not allowed is an
/// action that stays underneath the status or navigation bar.
Future<void> _expectReachable(
  WidgetTester tester,
  Finder finder, {
  double keyboard = 0,
}) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();

  final rect = tester.getRect(finder);
  final safe = _safeRegion(keyboard: keyboard);
  expect(
    rect.top,
    greaterThanOrEqualTo(safe.top),
    reason: '$finder is behind the top system inset',
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(safe.bottom),
    reason: '$finder is behind the bottom system inset',
  );
}

Future<PreferencesStore> _mockStore() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return PreferencesStore(preferences: () async => preferences);
}

class _CountingSavedRoutesNotifier extends SavedRoutesNotifier {
  var upsertCount = 0;

  @override
  List<SavedRoute> build() => const [];

  @override
  Future<void> upsert(SavedRoute route) {
    upsertCount++;
    return super.upsert(route);
  }
}

class _FakeItineraryRepository implements ItineraryRepository {
  const _FakeItineraryRepository();

  static const itinerary = Itinerary(
    title: 'A generated trip',
    stops: [
      Stop(
        name: 'One',
        subtitle: 'First',
        lat: 0,
        lng: 0,
        hours: 'Always open',
        duration: '1 day',
        aiNote: 'First stop',
        tags: [],
        detailedPlan: [],
      ),
    ],
  );

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) async => itinerary;
}

/// Counts every route the app settles on, so a duplicate navigation is visible.
class _NavigationLog extends NavigatorObserver {
  final List<String?> names = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    names.add(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) names.add(newRoute.settings.name);
  }
}

/// Wraps [home] in the app theme, optionally rescaling text.
Widget _harness({
  required ProviderContainer container,
  Widget? home,
  RouteFactory? onGenerateRoute,
  double textScale = 1,
  List<NavigatorObserver> observers = const [],
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.dark,
      navigatorObservers: observers,
      onGenerateRoute: onGenerateRoute,
      home: home,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

Future<ProviderContainer> _container({
  List<Override> overrides = const [],
}) async {
  final store = await _mockStore();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(store),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Drives a full background/resume cycle through every intermediate state, in
/// the order the engine reports them.
Future<void> _backgroundAndResume(WidgetTester tester) async {
  const down = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  const up = [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];
  for (final state in down) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
  for (final state in up) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

Finder _emailField() => find.descendant(
  of: find.byKey(const ValueKey('login-email-input')),
  matching: find.byType(TextField),
);

void main() {
  group('safe area at 360x640', () {
    testWidgets('login keeps both actions clear of the system insets', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const LoginScreen()),
      );

      await _expectReachable(
        tester,
        find.byKey(const ValueKey('login-submit')),
      );
      await _expectReachable(
        tester,
        find.byKey(const ValueKey('login-google')),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('login scrolls rather than clipping its content', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const LoginScreen()),
      );

      // The TextFields carry their own horizontal scrollables, so the vertical
      // one is addressed by its widget type rather than by Scrollable.
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);

      await tester.drag(scrollView, const Offset(0, -80));
      await tester.pump();

      // Depth-first order puts the vertical scrollable ahead of the fields'.
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

    testWidgets('login keeps its backdrop full-bleed on a tall phone', (
      tester,
    ) async {
      // 640 is short enough that the login content nearly fills it, which is
      // what hid this: on a 914px device the backdrop stopped two thirds down
      // and the rest of the screen went flat black.
      final view = tester.view;
      view.devicePixelRatio = 1;
      view.physicalSize = const Size(411, 914);
      addTearDown(view.reset);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const LoginScreen()),
      );

      expect(
        tester.getSize(find.byType(RouteCarBackdrop)),
        tester.getSize(find.byType(Scaffold)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('welcome keeps both actions clear of the system insets', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const WelcomeScreen()),
      );

      await _expectReachable(
        tester,
        find.byKey(const ValueKey('welcome-create-route')),
      );
      await _expectReachable(
        tester,
        find.byKey(const ValueKey('welcome-skip')),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding chrome clears the status bar', (tester) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: const OnboardingScreen(stepBuilder: onboardingStepBuilder),
        ),
      );

      await _expectReachable(
        tester,
        find.byKey(const ValueKey('onboarding-back')),
      );
      await _expectReachable(
        tester,
        find.byKey(const ValueKey('onboarding-progress-shell')),
      );
      await _expectReachable(
        tester,
        find.byKey(const ValueKey('onboarding-next')),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('region cards and manual Next fit 360px with doubled text', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setStep(8);
      await tester.pumpWidget(
        _harness(
          container: container,
          textScale: 2,
          home: const OnboardingScreen(stepBuilder: onboardingStepBuilder),
        ),
      );
      // Entrances and card transitions are finite; the progress car's bob is not.
      await tester.pump(const Duration(seconds: 1));
      final next = find.byKey(const ValueKey('onboarding-next'));
      for (final option in regionOptions) {
        final card = find.byKey(ValueKey('onboarding-region-${option.key}'));
        await _expectReachable(tester, card);
        final cardRect = tester.getRect(card);
        expect(cardRect.left, greaterThanOrEqualTo(0));
        expect(cardRect.right, lessThanOrEqualTo(_viewport.width));
        await tester.tap(card);
        await tester.pump(const Duration(seconds: 1));
        expect(
          container.read(onboardingNotifierProvider).answers.region,
          option.key,
        );
        expect(
          container.read(onboardingNotifierProvider).currentStep,
          8,
          reason: 'a picture selection must still wait for manual Next',
        );

        await _expectReachable(tester, next);
        await tester.tap(next);
        await tester.pump(const Duration(seconds: 1));
        expect(container.read(onboardingNotifierProvider).currentStep, 9);
        await tester.tap(find.byKey(const ValueKey('onboarding-back')));
        await tester.pump(const Duration(seconds: 1));
        expect(container.read(onboardingNotifierProvider).currentStep, 8);
        expect(
          container.read(onboardingNotifierProvider).answers.region,
          option.key,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('loading keeps its indicator and status clear of insets', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container(
        overrides: [
          itineraryRepositoryProvider.overrideWithValue(
            const _FakeItineraryRepository(),
          ),
        ],
      );
      await tester.pumpWidget(
        _harness(
          container: container,
          home: const LoadingScreen(answers: OnboardingAnswers(days: 5)),
        ),
      );
      await tester.pump();

      await _expectReachable(
        tester,
        find.byKey(const ValueKey('loading-status')),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('text scale', () {
    for (final scale in <double>[1, 1.5]) {
      testWidgets('login keeps its copy and actions at scale $scale', (
        tester,
      ) async {
        _useMobileViewport(tester);
        final container = await _container();
        await tester.pumpWidget(
          _harness(
            container: container,
            home: const LoginScreen(),
            textScale: scale,
          ),
        );

        expect(find.text('Terra NT'), findsOneWidget);
        expect(find.text('Discover the Northern Territory.'), findsOneWidget);
        expect(find.text('or'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        await _expectReachable(
          tester,
          find.byKey(const ValueKey('login-submit')),
        );
        expect(find.text('Start Exploring'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('welcome keeps its copy and actions at scale $scale', (
        tester,
      ) async {
        _useMobileViewport(tester);
        final container = await _container();
        await tester.pumpWidget(
          _harness(
            container: container,
            home: const WelcomeScreen(),
            textScale: scale,
          ),
        );

        expect(find.text('Welcome to Terra NT'), findsOneWidget);
        expect(
          find.text(
            "Answer a few quick questions and we'll build a route across the "
            'Territory for you — or skip straight to exploring on your own.',
          ),
          findsOneWidget,
        );
        await _expectReachable(
          tester,
          find.byKey(const ValueKey('welcome-create-route')),
        );
        await _expectReachable(
          tester,
          find.byKey(const ValueKey('welcome-skip')),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('onboarding keeps its question and action at scale $scale', (
        tester,
      ) async {
        _useMobileViewport(tester);
        final container = await _container();
        await tester.pumpWidget(
          _harness(
            container: container,
            home: const OnboardingScreen(stepBuilder: onboardingStepBuilder),
            textScale: scale,
          ),
        );

        expect(find.text('Which age range are you in?'), findsOneWidget);
        expect(find.text('Step 1 of 15'), findsOneWidget);
        await _expectReachable(
          tester,
          find.byKey(const ValueKey('onboarding-next')),
        );
        expect(find.text('Next'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('loading keeps its first status message at scale $scale', (
        tester,
      ) async {
        _useMobileViewport(tester);
        final container = await _container(
          overrides: [
            itineraryRepositoryProvider.overrideWithValue(
              const _FakeItineraryRepository(),
            ),
          ],
        );
        await tester.pumpWidget(
          _harness(
            container: container,
            home: const LoadingScreen(answers: OnboardingAnswers(days: 5)),
            textScale: scale,
          ),
        );
        await tester.pump();

        expect(find.text('Analyzing NT preferences...'), findsOneWidget);
        await _expectReachable(
          tester,
          find.byKey(const ValueKey('loading-status')),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('login keyboard', () {
    testWidgets('focused field and submit stay reachable above the keyboard', (
      tester,
    ) async {
      _useMobileViewport(tester, keyboard: _keyboardInset);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const LoginScreen()),
      );

      await tester.tap(_emailField());
      await tester.pump();

      await _expectReachable(tester, _emailField(), keyboard: _keyboardInset);
      await _expectReachable(
        tester,
        find.byKey(const ValueKey('login-submit')),
        keyboard: _keyboardInset,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the submit action still fires with the keyboard up', (
      tester,
    ) async {
      _useMobileViewport(tester, keyboard: _keyboardInset);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const LoginScreen()),
      );

      final submit = find.byKey(const ValueKey('login-submit'));
      await tester.ensureVisible(submit);
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('system back dismisses the keyboard before leaving login', (
      tester,
    ) async {
      _useMobileViewport(tester, keyboard: _keyboardInset);
      final container = await _container();
      final observer = _NavigationLog();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: const LoginScreen(),
          observers: [observer],
        ),
      );

      await tester.tap(_emailField());
      await tester.pump();
      expect(
        tester.widget<TextField>(_emailField()).focusNode!.hasFocus,
        isTrue,
      );

      await _simulateSystemBack();
      await tester.pump();

      // The first back blurs the field and keeps Login on screen.
      expect(
        tester.widget<TextField>(_emailField()).focusNode!.hasFocus,
        isFalse,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('system back leaves login once the keyboard is gone', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                ),
                child: const Text('open login'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open login'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LoginScreen), findsOneWidget);

      // With no IME covering the screen, Login does not intercept back and the
      // route pops as usual.
      await _simulateSystemBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('open login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('system back', () {
    testWidgets('from onboarding step 0 returns to Welcome (deviation V7)', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(
          container: container,
          onGenerateRoute: (_) => rootScreenRoute(AppRoute.onboarding),
        ),
      );
      await tester.pump();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      await _simulateSystemBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('from a later onboarding step returns to the previous step', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      final key = GlobalKey<OnboardingScreenState>();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: OnboardingScreen(key: key, stepBuilder: onboardingStepBuilder),
        ),
      );

      key.currentState!.updateAnswers(
        const OnboardingAnswers(ageRange: '18–25'),
      );
      key.currentState!.onNext();
      await tester.pump();
      expect(key.currentState!.currentStep, 1);

      await _simulateSystemBack();
      await tester.pump();

      expect(key.currentState!.currentStep, 0);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('lifecycle', () {
    testWidgets('background and resume leave the step and answer untouched', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      final key = GlobalKey<OnboardingScreenState>();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: OnboardingScreen(key: key, stepBuilder: onboardingStepBuilder),
        ),
      );

      key.currentState!.updateAnswers(
        const OnboardingAnswers(ageRange: '18–25'),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(key.currentState!.currentStep, 0);

      await _backgroundAndResume(tester);

      // Nothing is scheduled on a pick any more (V12), so neither the resume nor
      // any amount of settling can move the step on its own.
      expect(key.currentState!.currentStep, 0);
      expect(key.currentState!.answers.ageRange, '18–25');
      await tester.pump(OnboardingMotion.stepSlide);
      expect(key.currentState!.currentStep, 0);

      // Next still advances exactly one step across the lifecycle change.
      key.currentState!.onNext();
      await tester.pump();
      expect(key.currentState!.currentStep, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('background and resume during loading write the route once', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final savedRoutes = _CountingSavedRoutesNotifier();
      final container = await _container(
        overrides: [
          itineraryRepositoryProvider.overrideWithValue(
            const _FakeItineraryRepository(),
          ),
          savedRoutesNotifierProvider.overrideWith(() => savedRoutes),
        ],
      );
      final observer = _NavigationLog();
      var completions = 0;
      await tester.pumpWidget(
        _harness(
          container: container,
          observers: [observer],
          home: LoadingScreen(
            answers: const OnboardingAnswers(days: 5),
            onComplete: () => completions++,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 3000));
      await _backgroundAndResume(tester);
      expect(completions, 0);

      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pump();

      expect(completions, 1);
      expect(savedRoutes.upsertCount, 1);

      // Nothing re-fires after the completion, backgrounded or not.
      await _backgroundAndResume(tester);
      await tester.pump(const Duration(milliseconds: 7000));
      expect(completions, 1);
      expect(savedRoutes.upsertCount, 1);

      final routes = container.read(savedRoutesNotifierProvider);
      expect(routes, hasLength(1));
      expect(routes.single.id, 'generated-trip');
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('background and resume during loading navigate once', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container(
        overrides: [
          itineraryRepositoryProvider.overrideWithValue(
            const _FakeItineraryRepository(),
          ),
        ],
      );
      final observer = _NavigationLog();
      await tester.pumpWidget(
        _harness(
          container: container,
          observers: [observer],
          home: const LoadingScreen(answers: OnboardingAnswers(days: 5)),
        ),
      );

      await tester.pump(const Duration(milliseconds: 3000));
      await _backgroundAndResume(tester);
      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pump();
      await _backgroundAndResume(tester);
      await tester.pump(const Duration(milliseconds: 7000));

      expect(observer.names.where((name) => name == 'result'), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('touch targets', () {
    testWidgets('onboarding back keeps a 36px circle inside a 48px target', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: const OnboardingScreen(stepBuilder: onboardingStepBuilder),
        ),
      );

      // The prototype paints a 36px circle; only the target grows.
      expect(
        tester.getSize(find.byKey(const ValueKey('onboarding-back-circle'))),
        const Size(
          AppMetrics.onboardingBackButtonSize,
          AppMetrics.onboardingBackButtonSize,
        ),
      );

      final target = tester.getSize(
        find.byKey(const ValueKey('onboarding-back')),
      );
      expect(target.width, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
      expect(target.height, greaterThanOrEqualTo(AppMetrics.minTouchTarget));

      // Growing the target must not move the painted circle: it still sits at
      // the prototype's inset, measured from inside the safe area.
      final circle = tester.getTopLeft(
        find.byKey(const ValueKey('onboarding-back-circle')),
      );
      expect(circle.dx, AppMetrics.onboardingChromeSide);
      expect(circle.dy, _topInset + AppMetrics.onboardingChromeTop);
    });

    testWidgets('a tap in the transparent margin still triggers back', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      var exited = false;
      await tester.pumpWidget(
        _harness(
          container: container,
          home: OnboardingScreen(
            stepBuilder: onboardingStepBuilder,
            onExitToWelcome: () => exited = true,
          ),
        ),
      );

      // The top-left corner of the target lies outside the painted circle.
      final target = tester.getRect(
        find.byKey(const ValueKey('onboarding-back')),
      );
      await tester.tapAt(target.topLeft + const Offset(2, 2));
      await tester.pump();

      expect(exited, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every onboarding option row meets the minimum target', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(
          container: container,
          home: const OnboardingScreen(stepBuilder: onboardingStepBuilder),
        ),
      );

      for (final option in const ['18–25', '26–35', '36–50', '50+']) {
        // The chip inside the row carries its own inert GestureDetector, so
        // the target is the nearest ancestor that actually handles a tap.
        final row = find
            .ancestor(
              of: find.text(option),
              matching: find.byWidgetPredicate(
                (widget) => widget is GestureDetector && widget.onTap != null,
              ),
            )
            .first;
        final size = tester.getSize(row);
        expect(
          size.height,
          greaterThanOrEqualTo(AppMetrics.minTouchTarget),
          reason: 'option "$option" is below the minimum target height',
        );
        expect(size.width, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
      }
    });

    testWidgets('the primary action spans at least the minimum target width', (
      tester,
    ) async {
      _useMobileViewport(tester);
      final container = await _container();
      await tester.pumpWidget(
        _harness(container: container, home: const LoginScreen()),
      );

      for (final key in const [
        ValueKey('login-submit'),
        ValueKey('login-google'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
        // Painted height is the design system's own button token; AppButton
        // owns whether that gains a taller transparent target.
        expect(size.height, AppMetrics.buttonHeightLg);
      }
    });
  });
}
