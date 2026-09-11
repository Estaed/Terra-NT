import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/itinerary_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/features/loading/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedSessionNotifier extends SessionNotifier {
  @override
  Session build() => const Session(email: null, onboardingDone: false);
}

class _FixedSavedRoutesNotifier extends SavedRoutesNotifier {
  _FixedSavedRoutesNotifier(this.initialRoutes);

  final List<SavedRoute> initialRoutes;

  @override
  List<SavedRoute> build() => List<SavedRoute>.from(initialRoutes);
}

class _FakeItineraryRepository implements ItineraryRepository {
  _FakeItineraryRepository(this.itinerary);

  final Itinerary itinerary;

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) async => itinerary;

  @override
  Future<Itinerary> itineraryForSavedRoute(String routeId) async => itinerary;
}

class _RouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      pushed.add(newRoute);
    }
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  PreferencesStore preferencesStore() {
    return PreferencesStore(
      preferences: () async => SharedPreferences.getInstance(),
    );
  }

  const itinerary = Itinerary(
    title: 'A different trip',
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
      Stop(
        name: 'Two',
        subtitle: 'Second',
        lat: 1,
        lng: 1,
        hours: 'Always open',
        duration: '1 day',
        aiNote: 'Second stop',
        tags: [],
        detailedPlan: [],
      ),
      Stop(
        name: 'Three',
        subtitle: 'Third',
        lat: 2,
        lng: 2,
        hours: 'Always open',
        duration: '1 day',
        aiNote: 'Third stop',
        tags: [],
        detailedPlan: [],
      ),
      Stop(
        name: 'Four',
        subtitle: 'Fourth',
        lat: 3,
        lng: 3,
        hours: 'Always open',
        duration: '1 day',
        aiNote: 'Fourth stop',
        tags: [],
        detailedPlan: [],
      ),
    ],
  );

  Future<void> pumpLoading(
    WidgetTester tester, {
    VoidCallback? onComplete,
    OnboardingAnswers answers = const OnboardingAnswers(days: 11),
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(preferencesStore()),
          itineraryRepositoryProvider.overrideWithValue(
            _FakeItineraryRepository(itinerary),
          ),
          sessionNotifierProvider.overrideWith(_FixedSessionNotifier.new),
          savedRoutesNotifierProvider.overrideWith(
            () => _FixedSavedRoutesNotifier(const []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: LoadingScreen(answers: answers, onComplete: onComplete),
        ),
      ),
    );
  }

  testWidgets('rotates all five messages and completes at seven seconds', (
    tester,
  ) async {
    var completed = false;
    await pumpLoading(tester, onComplete: () => completed = true);
    await tester.pump();

    const messages = [
      'Analyzing NT preferences...',
      'Consulting outback AI...',
      'Mapping stops across the Territory...',
      'Calculating drive times...',
      'Routing...',
    ];
    expect(find.text(messages[0]), findsOneWidget);
    for (var index = 1; index < messages.length; index++) {
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text(messages[index]), findsOneWidget);
    }
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 1399));
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completed, isTrue);
  });

  testWidgets(
    'persists the generated route with dynamic title, meta and flag',
    (tester) async {
      var completed = false;
      await pumpLoading(tester, onComplete: () => completed = true);
      await tester.pump(const Duration(milliseconds: 7000));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoadingScreen)),
      );
      expect(completed, isTrue);
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      final routes = container.read(savedRoutesNotifierProvider);
      expect(routes, hasLength(1));
      expect(routes.first.id, 'generated-trip');
      expect(routes.first.title, itinerary.title);
      expect(routes.first.meta, '11 days · 4 stops');
      expect(routes.first.dateLabel, 'Generated just now');
    },
  );

  testWidgets('dispose cancels completion and message timers', (tester) async {
    var completed = false;
    await pumpLoading(tester, onComplete: () => completed = true);
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 7000));
    expect(completed, isFalse);
  });

  testWidgets('paints the canvas token and drives a looping car', (
    tester,
  ) async {
    await pumpLoading(tester);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.canvas);
    expect(
      find.byKey(const ValueKey('onboarding-progress-car')),
      findsOneWidget,
    );

    final before = tester.getTopLeft(
      find.byKey(const ValueKey('onboarding-progress-car')),
    );
    await tester.pump(AppMotion.loadingProgressDriveLoop ~/ 3);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('onboarding-progress-car'))),
      isNot(before),
    );
  });

  testWidgets('an early exit leaves no ticker behind', (tester) async {
    await pumpLoading(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('keeps the longest message within a 360px viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLoading(tester);
    await tester.pump(const Duration(milliseconds: 2800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('default completion navigates to Result', (tester) async {
    final observer = _RouteObserver();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(preferencesStore()),
          itineraryRepositoryProvider.overrideWithValue(
            _FakeItineraryRepository(itinerary),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          navigatorObservers: [observer],
          home: const LoadingScreen(answers: OnboardingAnswers(days: 5)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 7000));
    await tester.pump();
    expect(observer.pushed.last.settings.name, 'result');
  });
}
