import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
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
import 'package:terra_nt/features/onboarding/onboarding_screen.dart';
import 'package:terra_nt/shared/map/terra_map.dart';
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

  @override
  Future<Itinerary> itineraryFor(OnboardingAnswers answers) {
    final completer = Completer<Itinerary>();
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
      expect(routes.first.dateLabel, 'Generated just now');
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
    expect(state.itinerary.stops.map((stop) => stop.name), ['Alpha', 'Beta']);
    final saved = container.read(savedRoutesNotifierProvider).first;
    expect(saved.id, 'generated-trip');
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

  testWidgets('paints the canvas token and drives a looping car', (
    tester,
  ) async {
    await pumpLoading(tester, repositoryItinerary: null);
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
      expect(find.text('15/15'), findsOneWidget);

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
      'Check your signal and try again.',
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
}
