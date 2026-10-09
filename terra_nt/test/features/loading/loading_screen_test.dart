import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/core/util/plan_failure_copy.dart';
import 'package:terra_nt/data/models/itinerary.dart';
import 'package:terra_nt/data/models/onboarding_answers.dart';
import 'package:terra_nt/data/models/plan_failure.dart';
import 'package:terra_nt/data/models/saved_route.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/models/stop.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/itinerary_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/repositories/preferences_store.dart';
import 'package:terra_nt/data/repositories/remote_itinerary_repository.dart';
import 'package:terra_nt/features/loading/loading_screen.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/saved/saved_routes_screen.dart';
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/shared/map/car_glyph.dart';
import 'package:terra_nt/shared/map/map_markers.dart';
import 'package:terra_nt/shared/map/route_car_backdrop.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
import 'package:terra_nt/shared/widgets/app_button.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/features/onboarding/widgets/progress_drive.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _resultWarmupKey = ValueKey('loading-result-map-warmup');

Finder _resultWarmup() => find.byKey(_resultWarmupKey, skipOffstage: false);

/// The fixtures carry non-Latin1 bytes (·, –); `http.Response`'s default
/// encoding is Latin1, so every body used with [MockClient] goes through utf8.
http.Response _remoteResponse(String body, int statusCode) =>
    http.Response.bytes(
      utf8.encode(body),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

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

/// Every call gets its own [Completer]. With [itinerary] set the future resolves
/// at once; without it the test decides when, and with what.
class _FakeItineraryRepository implements ItineraryRepository {
  _FakeItineraryRepository([this.itinerary]);

  final Itinerary? itinerary;
  final List<Completer<Itinerary>> calls = [];
  final List<OnboardingAnswers> requests = [];

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) {
    final completer = Completer<Itinerary>();
    requests.add(answers);
    calls.add(completer);
    final result = itinerary;
    if (result != null) {
      completer.complete(result);
    }
    return completer.future;
  }
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

  late _FakeItineraryRepository repository;
  late InMemoryAuthRepository auth;
  late _RouteObserver observer;

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  /// Pumps Loading over the in-memory auth seam. With [repositoryItinerary]
  /// null the repository call stays pending until the test resolves it.
  Future<void> pumpLoading(
    WidgetTester tester, {
    VoidCallback? onComplete,
    OnboardingAnswers answers = const OnboardingAnswers(days: 11),
    Itinerary? repositoryItinerary = itinerary,
    double textScale = 1,
  }) async {
    repository = _FakeItineraryRepository(repositoryItinerary);
    auth = InMemoryAuthRepository();
    observer = _RouteObserver();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(preferencesStore()),
          itineraryRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(auth),
          sessionNotifierProvider.overrideWith(_FixedSessionNotifier.new),
          savedRoutesNotifierProvider.overrideWith(
            () => _FixedSavedRoutesNotifier(const []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          navigatorObservers: [observer],
          home: LoadingScreen(answers: answers, onComplete: onComplete),
        ),
      ),
    );
  }

  Future<void> failWith(WidgetTester tester, PlanFailure failure) async {
    repository.calls.last.completeError(PlanException(failure));
    await tester.pump();
  }

  for (final failure in PlanFailure.values) {
    testWidgets('$failure shows its reason and cue at 360px and 2x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
      addTearDown(tester.view.reset);
      await pumpLoading(tester, repositoryItinerary: null, textScale: 2);
      await failWith(tester, failure);
      await tester.pump(const Duration(seconds: 1));

      final copy = copyForFailure(failure);
      expect(find.text(copy.title), findsOneWidget);
      expect(find.text(copy.body), findsOneWidget);
      final scene = find.byKey(const ValueKey('loading-no-signal-scene'));
      final cue = find.byKey(const ValueKey('loading-failure-icon'));
      if (failure == PlanFailure.network || failure == PlanFailure.cancelled) {
        expect(scene, findsOneWidget);
        expect(
          (tester.widget<Image>(scene).image as AssetImage).assetName,
          LoadingScreen.noSignalAsset,
        );
        expect(cue, findsNothing);
      } else {
        expect(scene, findsNothing);
        expect(cue, findsOneWidget);
        expect(
          tester.widget<AppIcon>(cue).icon,
          failure == PlanFailure.unauthorised
              ? LucideIcons.log_in
              : LucideIcons.circle_alert,
        );
      }
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('loading-brand-mark')), findsNothing);
      expect(find.byKey(const ValueKey('loading-halo')), findsNothing);
      final lastAction = find.byKey(
        ValueKey(
          copy.showBack ? 'loading-failure-back' : 'loading-failure-primary',
        ),
      );
      await tester.ensureVisible(lastAction);
      await tester.pump();
      expect(tester.getRect(lastAction).bottom, lessThanOrEqualTo(640 - 48));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  for (final resolved in [false, true]) {
    testWidgets('loading resolved=$resolved fits at 360px and 2x text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
      addTearDown(tester.view.reset);
      await pumpLoading(
        tester,
        repositoryItinerary: resolved ? itinerary : null,
        textScale: 2,
        onComplete: () {},
      );
      for (var index = 0; index < 5; index++) {
        await tester.pump(AppMotion.loadingMessageInterval);
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets(
    'loading draws the chosen Top End trip and the underlay matches',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);
      await pumpLoading(
        tester,
        repositoryItinerary: null,
        answers: const OnboardingAnswers(
          region: 'top_end',
          startLocation: 'Darwin',
          endLocation: 'Katherine',
        ),
      );
      final coordinates = tester
          .widget<RouteCarBackdrop>(find.byType(RouteCarBackdrop))
          .coordinates;
      expect(coordinates.first, [-12.4634, 130.8456]);
      expect(coordinates.last, [-14.3103, 132.4204]);
      expect(coordinates.every((point) => point.first > -15), isTrue);
      final underlay = tester.widget<TerraMap>(
        find.byKey(const ValueKey('loading-backdrop-underlay')),
      );
      final bounds = LatLngBounds.fromPoints([
        for (final point in coordinates) LatLng(point.first, point.last),
      ]);
      expect(underlay.bounds!.southWest, bounds.southWest);
      expect(underlay.bounds!.northEast, bounds.northEast);
    },
  );

  testWidgets('offline action opens Result and persists that same suggestion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLoading(
      tester,
      repositoryItinerary: null,
      answers: const OnboardingAnswers(
        days: 4,
        region: 'top_end',
        startLocation: 'Darwin',
        endLocation: 'Katherine',
      ),
    );
    final container = containerOf(tester);
    final preview = tester
        .widget<RouteCarBackdrop>(find.byType(RouteCarBackdrop))
        .coordinates;
    await failWith(tester, PlanFailure.network);
    await tester.pump(AppMotion.slow);
    await tester.tap(find.byKey(const ValueKey('loading-failure-offline')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(observer.pushed.last.settings.name, 'result');
    expect(repository.calls, hasLength(1));
    expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
    final active = container.read(itineraryNotifierProvider).itinerary;
    final saved = container.read(savedRoutesNotifierProvider).single;
    expect(active.title, 'Offline suggestion: Darwin to Katherine');
    expect(active.days, 4);
    expect(active.stops.map((stop) => [stop.lat, stop.lng]).toList(), preview);
    expect(saved.id, 'generated-trip');
    expect(saved.title, active.title);
    expect(saved.dateLabel, 'Offline suggestion');
    expect(saved.days, active.days);
    expect(saved.stops, active.stops);
    final store = container.read(preferencesStoreProvider);
    final persisted = (await store.readSavedRoutes()).single;
    expect(persisted.title, saved.title);
    expect(persisted.dateLabel, saved.dateLabel);
    expect(persisted.stops.first.name, 'Darwin');
    expect(persisted.stops.last.name, 'Katherine');
    expect(persisted.stops.last.driveNext, isNull);
    expect(await store.readOnboardingDone(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry keeps the submitted answers when onboarding changes', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      repositoryItinerary: null,
      answers: const OnboardingAnswers(
        region: 'top_end',
        startLocation: 'Darwin',
        endLocation: 'Katherine',
      ),
    );
    await failWith(tester, PlanFailure.timeout);
    containerOf(tester)
        .read(onboardingNotifierProvider.notifier)
        .setAnswers(
          const OnboardingAnswers(
            region: 'red_centre',
            startLocation: 'Alice Springs',
            endLocation: 'Uluru',
          ),
        );
    await tester.tap(find.byKey(const ValueKey('loading-failure-primary')));
    await tester.pump();
    expect(repository.requests.last, same(repository.requests.first));
    expect(repository.requests.last.region, 'top_end');
  });

  testWidgets(
    'failure actions remain reachable at narrow width with large text and insets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpLoading(tester, repositoryItinerary: null);
      await failWith(tester, PlanFailure.network);
      await tester.pump(AppMotion.slow);
      for (final key in const [
        ValueKey('loading-failure-primary'),
        ValueKey('loading-failure-offline'),
        ValueKey('loading-failure-back'),
      ]) {
        await tester.ensureVisible(find.byKey(key));
        expect(find.byKey(key).hitTestable(), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('loading-failure-back')));
      // Loading's enlarged actions were exercised above. The onboarding
      // screen reached by Back has separate layout ownership.
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pump();
      expect(observer.pushed.last.settings.name, 'onboarding');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rotates all five messages and holds the last until the response',
    (tester) async {
      var completed = false;
      await pumpLoading(
        tester,
        onComplete: () => completed = true,
        repositoryItinerary: null,
      );
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
      await tester.pump(const Duration(milliseconds: 20000));
      expect(find.text(messages.last), findsOneWidget);
      expect(completed, isFalse);

      repository.calls.single.complete(itinerary);
      await tester.pump();
      expect(completed, isTrue);
    },
  );

  testWidgets(
    'completes and navigates no earlier than the minimum display time',
    (tester) async {
      var completed = false;
      await pumpLoading(tester, onComplete: () => completed = true);
      await tester.pump();
      expect(completed, isFalse);
      await tester.pump(AppMotion.loadingCompletionDelay);
      expect(completed, isTrue);
    },
  );

  testWidgets(
    'persists the generated route with dynamic title, meta and flag',
    (tester) async {
      var completed = false;
      await pumpLoading(tester, onComplete: () => completed = true);
      await tester.pump(AppMotion.loadingCompletionDelay);

      final container = containerOf(tester);
      expect(completed, isTrue);
      expect(container.read(sessionNotifierProvider).onboardingDone, isTrue);
      final routes = container.read(savedRoutesNotifierProvider);
      expect(routes, hasLength(1));
      expect(routes.first.id, 'generated-trip');
      expect(routes.first.title, itinerary.title);
      expect(routes.first.meta, '11 days · 4 stops');
      expect(routes.first.dateLabel, 'Your latest plan');
      expect(routes.first.days, 11);
    },
  );

  testWidgets(
    'generated header, saved row and reopened header keep the planned days',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpLoading(
        tester,
        onComplete: () {
          Navigator.of(tester.element(find.byType(LoadingScreen)))
              .pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
              );
        },
      );
      await tester.pump(AppMotion.loadingCompletionDelay);
      await tester.pumpAndSettle();
      final container = containerOf(tester);
      expect(find.text('11 days · 4 stops'), findsOneWidget);
      container
          .read(onboardingNotifierProvider.notifier)
          .setAnswers(const OnboardingAnswers(days: 3));
      await tester.pump();
      expect(find.text('11 days · 4 stops'), findsOneWidget);
      Navigator.of(tester.element(find.byType(ResultScreen))).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => SavedRoutesScreen(
            onOpenRoute: (_) => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('11 days · 4 stops'), findsOneWidget);
      expect(find.text('Your latest plan'), findsOneWidget);
      await tester.pump(const Duration(days: 30));
      expect(find.text('Your latest plan'), findsOneWidget);
      await tester.tap(find.text('A different trip'));
      await tester.pumpAndSettle();
      expect(find.text('11 days · 4 stops'), findsOneWidget);
      expect(container.read(itineraryNotifierProvider).itinerary.days, 11);
      expect(container.read(onboardingNotifierProvider).answers.days, 3);
    },
  );

  testWidgets('hands the fetched itinerary to the itinerary notifier', (
    tester,
  ) async {
    const generated = Itinerary(
      title: 'Two stops from the seam',
      stops: [
        Stop(
          name: 'Alpha',
          subtitle: 'First',
          lat: -12.4634,
          lng: 130.8456,
          hours: 'Always open',
          duration: '1 day',
          aiNote: 'First stop',
          tags: [],
          detailedPlan: [],
        ),
        Stop(
          name: 'Beta',
          subtitle: 'Second',
          lat: -13.1830,
          lng: 130.6805,
          hours: 'Always open',
          duration: '1 day',
          aiNote: 'Second stop',
          tags: [],
          detailedPlan: [],
        ),
      ],
    );
    await pumpLoading(
      tester,
      onComplete: () {},
      repositoryItinerary: generated,
    );
    await tester.pump(AppMotion.loadingCompletionDelay);

    final container = containerOf(tester);
    final state = container.read(itineraryNotifierProvider);
    expect(state.itinerary.title, 'Two stops from the seam');
    expect(state.itinerary.days, 11);
    expect(state.itinerary.stops.map((stop) => stop.name), ['Alpha', 'Beta']);
    final saved = container.read(savedRoutesNotifierProvider).first;
    expect(saved.id, 'generated-trip');
    expect(saved.days, state.itinerary.days);
    expect(saved.stops.map((stop) => stop.name), ['Alpha', 'Beta']);
  });

  testWidgets('a response after dispose changes nothing', (tester) async {
    var completed = false;
    await pumpLoading(
      tester,
      onComplete: () => completed = true,
      repositoryItinerary: null,
    );
    await tester.pump(const Duration(milliseconds: 3000));
    final container = containerOf(tester);
    final routesBefore = container.read(savedRoutesNotifierProvider);
    await tester.pumpWidget(const SizedBox.shrink());
    repository.calls.single.complete(itinerary);
    await tester.pump(const Duration(milliseconds: 7000));
    expect(completed, isFalse);
    expect(routesBefore, isEmpty);
  });

  testWidgets('paints the canvas token with one progress cue in the panel', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.canvas);
    final panel = find.byKey(const ValueKey('loading-panel'));
    expect(
      find.descendant(
        of: panel,
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.byType(ProgressDrive), findsNothing);
    expect(find.byKey(const ValueKey('loading-halo')), findsNothing);
    expect(find.byKey(const ValueKey('loading-brand-mark')), findsNothing);
    expect(find.byType(RouteCarBackdrop), findsOneWidget);
    expect(find.byType(CarGlyph), findsOneWidget);
  });

  testWidgets('an early exit leaves no ticker behind', (tester) async {
    await pumpLoading(tester, repositoryItinerary: null);
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

    await pumpLoading(tester, repositoryItinerary: null);
    await tester.pump(const Duration(milliseconds: 2800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('default completion navigates to Result', (tester) async {
    await pumpLoading(tester);
    await tester.pump(AppMotion.loadingCompletionDelay);
    expect(observer.pushed.last.settings.name, 'result');
  });

  testWidgets(
    'Cancel before the response saves nothing and returns to onboarding',
    (tester) async {
      var completed = false;
      await pumpLoading(
        tester,
        onComplete: () => completed = true,
        repositoryItinerary: null,
      );
      final container = containerOf(tester);
      container.read(onboardingNotifierProvider.notifier).setStep(14);
      await tester.pump(const Duration(milliseconds: 1400));

      await tester.tap(find.byKey(const ValueKey('loading-cancel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(observer.pushed.last.settings.name, 'onboarding');
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(LoadingScreen), findsNothing);
      expect(find.text('Step 15 of 15'), findsOneWidget);

      repository.calls.single.complete(itinerary);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isFalse);
      expect(container.read(savedRoutesNotifierProvider), isEmpty);
      expect(container.read(sessionNotifierProvider).onboardingDone, isFalse);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets('network shows the try-again copy with Back and no Cancel', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
    expect(find.byKey(const ValueKey('loading-cancel')), findsOneWidget);

    await failWith(tester, PlanFailure.network);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('loading-failure-title')))
          .data,
      "Couldn't reach the planner.",
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('loading-failure-body')))
          .data,
      'Try again when you have signal, or use an offline suggestion '
      'from places on this device.',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('loading-failure-primary')),
        matching: find.text('Try again'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('loading-failure-back')),
        matching: find.text('Back'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('loading-cancel')), findsNothing);
    expect(find.text('Use an offline route'), findsOneWidget);
    expect(find.byKey(const ValueKey('loading-brand-mark')), findsNothing);
    final scene = tester.widget<Image>(
      find.byKey(const ValueKey('loading-no-signal-scene')),
    );
    expect((scene.image as AssetImage).assetName, LoadingScreen.noSignalAsset);
    expect(find.byKey(const ValueKey('loading-status')), findsNothing);
    expect(find.byKey(const ValueKey('loading-progress-shell')), findsNothing);
  });

  testWidgets('Back from a failure returns to onboarding', (tester) async {
    await pumpLoading(tester, repositoryItinerary: null);
    await failWith(tester, PlanFailure.timeout);

    await tester.tap(find.byKey(const ValueKey('loading-failure-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(observer.pushed.last.settings.name, 'onboarding');
  });

  testWidgets('cannotPlan offers Change answers and no Back', (tester) async {
    await pumpLoading(tester, repositoryItinerary: null);
    await failWith(tester, PlanFailure.cannotPlan);

    expect(find.text("We couldn't plan this trip."), findsOneWidget);
    expect(
      find.text('Try a different region, vehicle or trip length.'),
      findsOneWidget,
    );
    expect(find.text('Change answers'), findsOneWidget);
    expect(find.byKey(const ValueKey('loading-failure-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('loading-failure-primary')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(observer.pushed.last.settings.name, 'onboarding');
  });

  testWidgets('unauthorised signs the session out and lands on Login', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
    final container = containerOf(tester);
    await container
        .read(sessionNotifierProvider.notifier)
        .signInWithEmail('traveller@example.com', 'password');
    expect(container.read(sessionNotifierProvider).email, isNotNull);

    await failWith(tester, PlanFailure.unauthorised);
    expect(find.text('Your session has expired.'), findsOneWidget);
    expect(find.text('Sign in again to plan a trip.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byKey(const ValueKey('loading-failure-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('loading-failure-primary')));
    await tester.pump();
    await tester.pump();
    expect(container.read(sessionNotifierProvider).email, isNull);
    expect(await auth.currentEmail(), isNull);
    expect(observer.pushed.last.settings.name, 'login');
  });

  testWidgets('Try again calls the repository again and returns to in flight', (
    tester,
  ) async {
    var completed = false;
    await pumpLoading(
      tester,
      onComplete: () => completed = true,
      repositoryItinerary: null,
    );
    await tester.pump(const Duration(milliseconds: 2800));
    await failWith(tester, PlanFailure.serverError);
    expect(repository.calls, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('loading-failure-primary')));
    await tester.pump();
    expect(repository.calls, hasLength(2));
    expect(repository.requests.last, same(repository.requests.first));
    expect(find.byKey(const ValueKey('loading-failure-title')), findsNothing);
    expect(find.text('Analyzing NT preferences...'), findsOneWidget);
    expect(find.byKey(const ValueKey('loading-cancel')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.text('Consulting outback AI...'), findsOneWidget);

    repository.calls.last.complete(itinerary);
    await tester.pump();
    expect(completed, isFalse);
    await tester.pump(AppMotion.loadingCompletionDelay);
    expect(completed, isTrue);
  });

  testWidgets('a failure leaves no generated route and no flag behind', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
    final container = containerOf(tester);
    await failWith(tester, PlanFailure.invalidResponse);

    expect(
      container.read(savedRoutesNotifierProvider).map((route) => route.id),
      isNot(contains('generated-trip')),
    );
    expect(container.read(sessionNotifierProvider).onboardingDone, isFalse);
  });

  testWidgets(
    'a failed Loading stops its ticker and leaves no timer on dispose',
    (tester) async {
      await pumpLoading(tester, repositoryItinerary: null);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await failWith(tester, PlanFailure.rateLimited);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byKey(const ValueKey('loading-status')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mounts an offstage Result map as soon as the itinerary is in hand, '
    'before the minimum wait ends',
    (tester) async {
      await pumpLoading(tester);
      await tester.pump();

      expect(_resultWarmup(), findsOneWidget);
      final map = tester.widget<TerraMap>(
        find.descendant(
          of: _resultWarmup(),
          matching: find.byType(TerraMap, skipOffstage: false),
          skipOffstage: false,
        ),
      );
      expect(map.interactive, isFalse);
      expect(
        map.bounds,
        LatLngBounds.fromPoints(
          itinerary.stops.map((stop) => LatLng(stop.lat, stop.lng)).toList(),
        ),
      );
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final topInset = MediaQuery.paddingOf(
        tester.element(find.byType(LoadingScreen)),
      ).top;
      expect(
        map.fitPadding,
        TerraMap.resultFitPaddingFor(screenHeight, topInset),
      );

      // Still mounted with time left on V1's 7000ms minimum display delay.
      await tester.pump(const Duration(milliseconds: 3000));
      expect(_resultWarmup(), findsOneWidget);
    },
  );

  testWidgets('mounts no offstage Result map after a failure', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
    await failWith(tester, PlanFailure.network);

    expect(_resultWarmup(), findsNothing);
  });

  testWidgets(
    'Try again against the remote repository resends the same requestId',
    (tester) async {
      var callCount = 0;
      final requestIds = <String>[];
      final client = MockClient((request) async {
        callCount++;
        final body = jsonDecode(request.body) as Map<String, Object?>;
        requestIds.add(body['requestId'] as String);
        if (callCount == 1) {
          return _remoteResponse('{"error":{"code":"server_error"}}', 500);
        }
        return _remoteResponse(
          File('test/fixtures/plan/ok.json').readAsStringSync(),
          200,
        );
      });
      final repository = RemoteItineraryRepository(
        client: client,
        baseUrl: Uri.parse('https://plan.example.com'),
        idToken: () async => 'test-token',
      );

      var completed = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesStoreProvider.overrideWithValue(preferencesStore()),
            itineraryRepositoryProvider.overrideWithValue(repository),
            authRepositoryProvider.overrideWithValue(
              InMemoryAuthRepository(),
            ),
            sessionNotifierProvider.overrideWith(_FixedSessionNotifier.new),
            savedRoutesNotifierProvider.overrideWith(
              () => _FixedSavedRoutesNotifier(const []),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: LoadingScreen(
              answers: const OnboardingAnswers(
                ageRange: '26_35',
                days: 7,
                companions: 'couple',
                focus: ['nature', 'aboriginal_culture'],
                vehicle: 'four_wd',
                budget: 'mid_range',
                accommodation: 'camping',
                activityLevel: 'medium',
                region: 'top_end',
                offRoadConfidence: 'medium',
                heat: 3,
                campingPreference: 'mixed',
                wildlifeInterest: 'interested',
                offGridComfortable: true,
                startLocation: 'Darwin',
                endLocation: 'Uluru',
              ),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('loading-failure-primary')),
        findsOneWidget,
      );
      expect(requestIds, hasLength(1));

      await tester.tap(find.byKey(const ValueKey('loading-failure-primary')));
      await tester.pump();
      expect(completed, isFalse);
      await tester.pump(AppMotion.loadingCompletionDelay);

      expect(completed, isTrue);
      expect(requestIds, hasLength(2));
      expect(requestIds[1], requestIds[0]);
    },
  );

  testWidgets(
    'system Back in flight is Cancel: returns to onboarding, saves nothing',
    (tester) async {
      await pumpLoading(tester, repositoryItinerary: null);
      await tester.pump();
      final container = containerOf(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(observer.pushed.last.settings.name, 'onboarding');

      repository.calls.single.complete(itinerary);
      await tester.pump(AppMotion.loadingCompletionDelay);
      expect(
        container.read(savedRoutesNotifierProvider).map((route) => route.id),
        isNot(contains('generated-trip')),
      );
      expect(container.read(sessionNotifierProvider).onboardingDone, isFalse);
    },
  );

  testWidgets('system Back on a failure returns to onboarding', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
    await failWith(tester, PlanFailure.cannotPlan);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(observer.pushed.last.settings.name, 'onboarding');
  });

  group('polish (D18)', () {
    const panelKey = ValueKey('loading-panel');
    const statusKey = ValueKey('loading-status');

    testWidgets('the quiet panel has no brand badge or primary disc', (
      tester,
    ) async {
      await pumpLoading(tester, repositoryItinerary: null);

      expect(find.byKey(const ValueKey('loading-brand-mark')), findsNothing);
      expect(find.byKey(const ValueKey('loading-halo')), findsNothing);
      final primaryDisc = find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle &&
            decoration.color == AppColors.primary;
      });
      expect(
        find.descendant(of: find.byKey(panelKey), matching: primaryDisc),
        findsNothing,
      );
    });

    testWidgets('failure replaces panel progress with the no-signal scene', (
      tester,
    ) async {
      await pumpLoading(tester, repositoryItinerary: null);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await failWith(tester, PlanFailure.network);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('loading-brand-mark')), findsNothing);
      expect(
        find.byKey(const ValueKey('loading-no-signal-scene')),
        findsOneWidget,
      );
    });

    testWidgets('Cancel is the secondary AppButton, not an underlined link', (
      tester,
    ) async {
      await pumpLoading(tester, repositoryItinerary: null);

      expect(
        tester.widget(find.byKey(const ValueKey('loading-cancel'))),
        isA<AppButton>().having(
          (button) => button.variant,
          'variant',
          AppButtonVariant.secondary,
        ),
      );
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('crossfades from one message to the next', (tester) async {
      const first = 'Analyzing NT preferences...';
      const second = 'Consulting outback AI...';
      double opacityOf(String message) => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.text(message),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;

      await pumpLoading(tester, repositoryItinerary: null);
      await tester.pump(AppMotion.loadingMessageInterval);
      await tester.pump(AppMotion.slow ~/ 2);
      expect(opacityOf(first), inExclusiveRange(0, 1));
      expect(opacityOf(second), inExclusiveRange(0, 1));

      await tester.pump(AppMotion.slow);
      expect(find.text(first), findsNothing);
      expect(opacityOf(second), 1);
    });

    testWidgets('a message that wraps does not resize the panel mid-rotation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpLoading(tester, repositoryItinerary: null);
      await tester.pump();
      final statusHeights = <double>{};
      final panelTops = <double>{};
      for (var index = 0; index < 5; index++) {
        statusHeights.add(tester.getSize(find.byKey(statusKey)).height);
        panelTops.add(tester.getTopLeft(find.byKey(panelKey)).dy);
        await tester.pump(AppMotion.loadingMessageInterval);
      }
      expect(statusHeights, hasLength(1));
      expect(panelTops, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps its full layout once the Result map warm-up mounts', (
      tester,
    ) async {
      await pumpLoading(tester);
      await tester.pump();
      expect(_resultWarmup(), findsOneWidget);

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final panel = tester.getRect(find.byKey(panelKey));
      expect(panel.width, screen.width);
      expect(panel.bottom, screen.height);
      expect(tester.getSize(find.byKey(statusKey)).width, greaterThan(0));
    });

    testWidgets('the map drives above the panel and freezes on a failure', (
      tester,
    ) async {
      await pumpLoading(tester, repositoryItinerary: null);
      bool mapTicking() =>
          TickerMode.valuesOf(tester.element(find.byType(RouteCarBackdrop)))
              .enabled;

      expect(find.byType(RouteCarBackdrop), findsOneWidget);
      expect(mapTicking(), isTrue);
      final journey = tester.state<RouteCarBackdropState>(
        find.byType(RouteCarBackdrop),
      );
      final start = journey.currentPosition;
      await tester.pump(RouteCarBackdrop.ambientStartDelay);
      await tester.pump(AppMotion.base);
      expect(journey.currentPosition, isNot(start));
      expect(
        tester.getBottomLeft(find.byKey(const ValueKey('loading-backdrop'))).dy,
        tester.getTopLeft(find.byKey(panelKey)).dy,
      );

      await failWith(tester, PlanFailure.network);
      expect(find.byType(RouteCarBackdrop), findsOneWidget);
      expect(mapTicking(), isFalse);
      final stopped = journey.currentPosition;
      await tester.pump(AppMotion.loadingMessageInterval);
      expect(journey.currentPosition, stopped);
    });

    testWidgets('the route and car stay below the status bar while the map '
        'still runs behind it', (tester) async {
      // The emulator the defect was seen on: 411 dp wide, a tall phone.
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);

      await pumpLoading(tester, repositoryItinerary: null);
      await tester.pump();
      final topInset = MediaQuery.paddingOf(
        tester.element(find.byType(LoadingScreen)),
      ).top;
      expect(topInset, greaterThan(0));

      // The journey's only car stays on the map.
      Finder onMap(Type type) => find.descendant(
        of: find.byType(RouteCarBackdrop),
        matching: find.byType(type),
      );
      final stops = onMap(RouteDotMarker);
      final stopCount = RouteCarBackdrop.routeCoordinates.length;
      expect(stops, findsNWidgets(stopCount));
      final markers = [
        for (var index = 0; index < stopCount; index++) stops.at(index),
        onMap(CarGlyph),
      ];
      for (final marker in markers) {
        expect(tester.getRect(marker).top, greaterThanOrEqualTo(topInset));
      }

      final underlay = find.byKey(const ValueKey('loading-backdrop-underlay'));
      expect(tester.getTopLeft(underlay).dy, 0);
      expect(
        tester.getBottomLeft(underlay).dy,
        tester.getTopLeft(find.byKey(panelKey)).dy,
      );
      expect(
        tester.widget<TerraMap>(underlay).fitPadding,
        TerraMap.backdropFitPadding + EdgeInsets.only(top: topInset),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
