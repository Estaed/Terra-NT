import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/metrics.dart';
import 'package:terra_nt/core/util/sheet_snap.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/features/profile/account/account_screen.dart';
import 'package:terra_nt/features/profile/language/language_screen.dart';
import 'package:terra_nt/features/profile/profile_screen.dart';
import 'package:terra_nt/features/saved/saved_routes_screen.dart';
import 'package:terra_nt/shared/map/map_markers.dart';

/// The narrowest phone the build targets, with representative system insets:
/// a 44px status bar / notch and a 34px gesture bar.
const phoneSize = Size(360, 640);
const topInset = 44.0;
const bottomInset = 34.0;
final safeBottom = phoneSize.height - bottomInset;

class _CompletedSession extends SessionNotifier {
  @override
  Session build() =>
      const Session(email: 'traveller@example.com', onboardingDone: true);
}

/// Refuses every request, so no tile can ever load. Only disposal succeeds.
class _OfflineHttpClient implements HttpClient {
  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw const SocketException('Tile requests are unavailable');
}

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _OfflineHttpClient();
}

void useNarrowPhone(WidgetTester tester) {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(
    top: topInset,
    bottom: bottomInset,
  );
  tester.view.viewPadding = const FakeViewPadding(
    top: topInset,
    bottom: bottomInset,
  );
  addTearDown(tester.view.reset);
}

Widget app(Widget home, {double textScale = 1}) {
  return ProviderScope(
    overrides: [
      sessionNotifierProvider.overrideWith(_CompletedSession.new),
      authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Collects everything the framework reports while [body] runs.
///
/// `takeException` only surfaces the first failure and only when the test asks
/// for it; a mobile-readiness pass has to prove nothing was reported at all.
Future<List<FlutterErrorDetails>> recordErrors(
  Future<void> Function() body,
) async {
  final recorded = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = recorded.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return recorded;
}

Finder scrollableIn(Finder ancestor) =>
    find.descendant(of: ancestor, matching: find.byType(Scrollable));

ScrollableState scrollState(WidgetTester tester, Finder scrollable) =>
    tester.state<ScrollableState>(scrollable);

/// Drags [scrollable] and asserts it actually moved, so a screen that has more
/// content than viewport cannot silently become unscrollable.
Future<void> expectScrolls(WidgetTester tester, Finder scrollable) async {
  final position = scrollState(tester, scrollable).position;
  expect(
    position.maxScrollExtent,
    greaterThan(0),
    reason: 'nothing to scroll: the screen would not need a scroll view',
  );
  final before = position.pixels;
  await tester.drag(scrollable, const Offset(0, -80));
  await tester.pump();
  expect(scrollState(tester, scrollable).position.pixels, greaterThan(before));
}

void expectWithinSafeArea(WidgetTester tester, String key) {
  final rect = tester.getRect(find.byKey(ValueKey(key)));
  expect(rect.top, greaterThanOrEqualTo(topInset), reason: '$key under top');
  expect(
    rect.bottom,
    lessThanOrEqualTo(safeBottom),
    reason: '$key under bottom',
  );
}

Future<void> expandSheet(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('result-sheet-handle')),
    const Offset(0, -600),
    touchSlopY: 0,
  );
  await tester.pumpAndSettle();
}

ProviderContainer containerOf(WidgetTester tester, Finder of) =>
    ProviderScope.containerOf(tester.element(of));

/// Result opens onto no route by default (Task-40); give it the seeded route
/// the way the app does, so tests written against the old always-a-route
/// default keep exercising the map and sheet.
void openTestRoute(WidgetTester tester, Finder of) {
  containerOf(
    tester,
    of,
  ).read(itineraryNotifierProvider.notifier).openSavedRoute(seedSavedRoutes[0]);
}

/// The stop list builds lazily, so a row below the fold has no element at all
/// and `ensureVisible` has nothing to scroll to. Scroll the list itself first.
Future<void> revealInStopList(
  WidgetTester tester,
  Finder target,
  String listKey,
) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      80,
      scrollable: find.descendant(
        of: find.byKey(ValueKey(listKey)),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await tester.ensureVisible(target);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('safe area at 360x640', () {
    testWidgets('Result keeps its actions clear of the insets and scrolls', (
      tester,
    ) async {
      useNarrowPhone(tester);
      final errors = await recordErrors(() async {
        await tester.pumpWidget(app(const AppShell(initialTab: 1)));
        await tester.pump();
        openTestRoute(tester, find.byType(ResultScreen));
        await tester.pump();
        await expandSheet(tester);
      });

      expect(errors, isEmpty);
      for (final key in [
        'result-sheet-handle',
        'result-export',
        'result-edit-toggle',
        'bottom-nav-tab-1',
      ]) {
        expectWithinSafeArea(tester, key);
      }
      await expectScrolls(
        tester,
        scrollableIn(find.byKey(const ValueKey('result-sheet-scroll'))),
      );
    });

    testWidgets('Stop detail keeps Back and its footer out of the insets', (
      tester,
    ) async {
      useNarrowPhone(tester);
      final errors = await recordErrors(() async {
        await tester.pumpWidget(app(const AppShell(initialTab: 1)));
        await tester.pump();
        tester.state<AppShellState>(find.byType(AppShell)).showStopDetail();
        await tester.pumpAndSettle();
      });

      expect(errors, isEmpty);
      expect(find.byType(StopDetailScreen), findsOneWidget);
      for (final key in [
        'stop-detail-back-button',
        'stop-detail-skip',
        'stop-detail-navigate',
      ]) {
        expectWithinSafeArea(tester, key);
      }
      await expectScrolls(tester, scrollableIn(find.byType(StopDetailScreen)));
    });

    testWidgets('Saved Routes keeps its header and rows inside the insets', (
      tester,
    ) async {
      useNarrowPhone(tester);
      final errors = await recordErrors(() async {
        await tester.pumpWidget(app(const AppShell(initialTab: 2)));
        await tester.pumpAndSettle();
      });

      expect(errors, isEmpty);
      expect(find.byType(SavedRoutesScreen), findsOneWidget);
      expect(
        tester
            .getRect(
              find.descendant(
                of: find.byType(SavedRoutesScreen),
                matching: find.text('Saved Routes'),
              ),
            )
            .top,
        greaterThanOrEqualTo(topInset),
      );
      expectWithinSafeArea(tester, 'bottom-nav-tab-2');
      expect(
        tester
            .getRect(find.byKey(const ValueKey('saved-route-full-nt')))
            .bottom,
        lessThanOrEqualTo(safeBottom),
      );
    });

    testWidgets('Profile keeps every setting row reachable inside the insets', (
      tester,
    ) async {
      useNarrowPhone(tester);
      final errors = await recordErrors(() async {
        await tester.pumpWidget(app(const AppShell(initialTab: 3)));
        await tester.pumpAndSettle();
      });

      expect(errors, isEmpty);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        tester
            .getRect(
              find.descendant(
                of: find.byType(ProfileScreen),
                matching: find.text('Profile'),
              ),
            )
            .top,
        greaterThanOrEqualTo(topInset),
      );
      for (final finder in [
        find.text('Language'),
        find.text('Log Out'),
        find.byKey(const ValueKey('delete-account-link')),
      ]) {
        await tester.ensureVisible(finder);
        await tester.pump();
        expect(tester.getRect(finder).bottom, lessThanOrEqualTo(safeBottom));
      }
      expectWithinSafeArea(tester, 'bottom-nav-tab-3');
    });
  });

  group('Result sheet below a 700px viewport (V8)', () {
    testWidgets('clamps the top anchor and keeps its content reachable', (
      tester,
    ) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(app(ResultScreen(launcher: (_) async => true)));
      await tester.pump();
      openTestRoute(tester, find.byType(ResultScreen));
      await tester.pump();

      // The screen's own rule: the viewport minus the system insets.
      final usableHeight = phoneSize.height - topInset - bottomInset;
      expect(usableHeight, lessThan(AppMetrics.resultSheetMaxHeight));

      final sheet = find.byKey(const ValueKey('result-sheet'));
      await expandSheet(tester);
      expect(tester.getSize(sheet).height, usableHeight);
      expect(
        tester.getSize(sheet).height,
        nearestSnap(usableHeight + 200, usableHeight: usableHeight),
      );

      // The anchors that still fit are untouched.
      await tester.drag(
        find.byKey(const ValueKey('result-sheet-handle')),
        const Offset(0, 120),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(sheet).height, AppMetrics.resultSheetMidHeight);

      // Content stays reachable at the clamped anchor.
      await expandSheet(tester);
      final lastStop = find.byKey(
        ValueKey('result-stop-row-${seedStops.length - 1}'),
      );
      await revealInStopList(tester, lastStop, 'result-stop-list-view');
      // The taller handle reduces the viewport. Continue to the end so the
      // whole final card, rather than just its top, is above the gesture bar.
      await tester.drag(
        find.byKey(const ValueKey('result-stop-list-view')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(lastStop).bottom, lessThanOrEqualTo(safeBottom));
      expect(tester.takeException(), isNull);
    });
  });

  group('text scale', () {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Result keeps its copy and primary actions at $scale', (
        tester,
      ) async {
        useNarrowPhone(tester);
        late List<FlutterErrorDetails> errors;
        errors = await recordErrors(() async {
          await tester.pumpWidget(
            app(ResultScreen(launcher: (_) async => true), textScale: scale),
          );
          await tester.pump();
          openTestRoute(tester, find.byType(ResultScreen));
          await tester.pump();
          await expandSheet(tester);
        });

        expect(errors, isEmpty);
        expect(find.text('Export to Google Maps'), findsOneWidget);
        expect(find.text('Highlights'), findsOneWidget);
        expect(find.text('Detailed'), findsOneWidget);
        expect(find.text('Edit Route'), findsOneWidget);

        final toggle = find.byKey(const ValueKey('result-edit-toggle'));
        await tester.ensureVisible(toggle);
        await tester.pump();
        await tester.tap(toggle);
        await tester.pump();
        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('Stop detail keeps its copy and footer at $scale', (
        tester,
      ) async {
        useNarrowPhone(tester);
        final errors = await recordErrors(() async {
          await tester.pumpWidget(
            app(
              StopDetailScreen(
                stop: seedStops[1],
                originalIndex: 1,
                launcher: (_) async => true,
              ),
              textScale: scale,
            ),
          );
          await tester.pump();
        });

        expect(errors, isEmpty);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Navigate'), findsOneWidget);
        expect(find.text('Park entry fee'), findsOneWidget);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('stop-detail-navigate')))
              .bottom,
          lessThanOrEqualTo(safeBottom),
        );
      });

      testWidgets('Saved Routes keeps its seeded copy at $scale', (
        tester,
      ) async {
        useNarrowPhone(tester);
        final errors = await recordErrors(() async {
          await tester.pumpWidget(
            app(const SavedRoutesScreen(), textScale: scale),
          );
          await tester.pumpAndSettle();
        });

        expect(errors, isEmpty);
        expect(find.text('Full NT: Darwin to Uluru'), findsOneWidget);
        expect(find.text('8 days · 7 stops'), findsOneWidget);
        expect(find.text('Generated today'), findsOneWidget);
      });

      testWidgets('Profile keeps its rows and delete link at $scale', (
        tester,
      ) async {
        useNarrowPhone(tester);
        final errors = await recordErrors(() async {
          await tester.pumpWidget(app(const ProfileScreen(), textScale: scale));
          await tester.pump();
        });

        expect(errors, isEmpty);
        expect(find.text('Offline Maps'), findsNothing);
        expect(
          find.text('Download maps for areas with no signal'),
          findsNothing,
        );
        expect(find.text('Log Out'), findsOneWidget);

        final link = find.byKey(const ValueKey('delete-account-link'));
        await tester.ensureVisible(link);
        await tester.pump();
        await tester.tap(link);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('delete-account-confirmation')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('system Back', () {
    testWidgets('returns Stop detail, Account and Language to their tab root', (
      tester,
    ) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(app(const AppShell(initialTab: 1)));
      await tester.pump();
      final shell = tester.state<AppShellState>(find.byType(AppShell));

      shell.showStopDetail();
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(StopDetailScreen, skipOffstage: false), findsNothing);
      expect(find.byType(ResultScreen), findsOneWidget);

      shell.showAccount();
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen, skipOffstage: false), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);

      shell.showLanguage();
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(LanguageScreen, skipOffstage: false), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('leaves every other tab stack alone', (tester) async {
      useNarrowPhone(tester);
      final closed = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') closed.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(app(const AppShell(initialTab: 1)));
      await tester.pump();
      final shell = tester.state<AppShellState>(find.byType(AppShell));

      shell.showStopDetail();
      await tester.pumpAndSettle();
      shell.showAccount();
      await tester.pumpAndSettle();

      // Back on Profile pops Profile's stack, not Plan AI's, and does not ask
      // Android to close the app.
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        find.byType(StopDetailScreen, skipOffstage: false),
        findsOneWidget,
      );
      expect(closed, isEmpty);

      // Back at a root tab is the platform's to handle: the shell hands it to
      // Android and no stack loses a route.
      shell.selectTab(0);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, ['SystemNavigator.pop']);
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(
        find.byType(StopDetailScreen, skipOffstage: false),
        findsOneWidget,
      );

      // And the preserved stack is still there when the tab comes back.
      shell.selectTab(1);
      await tester.pump();
      expect(find.byType(StopDetailScreen), findsOneWidget);
    });
  });

  group('hit targets', () {
    testWidgets('edit-mode row actions paint at 26px inside a 48px target', (
      tester,
    ) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(app(ResultScreen(launcher: (_) async => true)));
      await tester.pump();
      openTestRoute(tester, find.byType(ResultScreen));
      await tester.pump();
      await expandSheet(tester);

      final container = containerOf(tester, find.byType(ResultScreen));
      container.read(itineraryNotifierProvider.notifier).reorder(0, 2);
      container.read(itineraryNotifierProvider.notifier).setEditMode(true);
      await tester.pumpAndSettle();

      const target = Size(AppMetrics.minTouchTarget, AppMetrics.minTouchTarget);
      const painted = Size(
        AppMetrics.resultStopActionVisualSize,
        AppMetrics.resultStopActionVisualSize,
      );
      for (final name in ['revert', 'remove']) {
        final action = find.byKey(ValueKey('result-stop-$name-0'));
        await revealInStopList(tester, action, 'result-stop-list-edit');
        expect(tester.getSize(action), target, reason: name);
        expect(
          tester.getSize(find.byKey(ValueKey('result-stop-$name-visual-0'))),
          painted,
          reason: name,
        );
      }
      expect(
        tester.getSize(find.byKey(const ValueKey('result-stop-drag-0'))),
        target,
      );

      // The grown target still triggers the action it wraps.
      await tester.tap(find.byKey(const ValueKey('result-stop-remove-0')));
      await tester.pump();
      expect(
        container.read(itineraryNotifierProvider).order,
        isNot(contains(0)),
      );
    });

    testWidgets('the restore link takes a 48px target at caption size', (
      tester,
    ) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(app(ResultScreen(launcher: (_) async => true)));
      await tester.pump();
      openTestRoute(tester, find.byType(ResultScreen));
      await tester.pump();
      await expandSheet(tester);

      final container = containerOf(tester, find.byType(ResultScreen));
      container.read(itineraryNotifierProvider.notifier).remove(1);
      await tester.pumpAndSettle();

      final link = find.byKey(const ValueKey('result-restore-removed'));
      await tester.ensureVisible(link);
      await tester.pump();
      expect(
        tester.getSize(link).height,
        greaterThanOrEqualTo(AppMetrics.minTouchTarget),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('result-restore-removed-label')))
            .height,
        lessThan(AppMetrics.minTouchTarget),
      );
    });

    testWidgets('Stop detail Back paints at 36px inside a 48px target', (
      tester,
    ) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(
        app(
          StopDetailScreen(
            stop: seedStops[0],
            originalIndex: 0,
            launcher: (_) async => true,
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getSize(find.byKey(const ValueKey('stop-detail-back-button'))),
        const Size(AppMetrics.minTouchTarget, AppMetrics.minTouchTarget),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('stop-detail-back-button-visual')),
        ),
        const Size(
          AppMetrics.stopDetailBackButtonSize,
          AppMetrics.stopDetailBackButtonSize,
        ),
      );
    });

    testWidgets('Profile delete link keeps a 48px target', (tester) async {
      useNarrowPhone(tester);
      await tester.pumpWidget(app(const ProfileScreen()));
      await tester.pump();

      final link = tester.getSize(
        find.byKey(const ValueKey('delete-account-link')),
      );
      expect(link.width, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
      expect(link.height, greaterThanOrEqualTo(AppMetrics.minTouchTarget));
    });
  });

  group('Result with tiles unavailable', () {
    setUp(() {
      final previous = HttpOverrides.current;
      HttpOverrides.global = _OfflineHttpOverrides();
      addTearDown(() => HttpOverrides.global = previous);
    });

    testWidgets('keeps its local map furniture and its edit actions', (
      tester,
    ) async {
      useNarrowPhone(tester);
      final errors = await recordErrors(() async {
        await tester.pumpWidget(app(ResultScreen(launcher: (_) async => true)));
        await tester.pump();
        openTestRoute(tester, find.byType(ResultScreen));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      });

      expect(errors, isEmpty);
      // Everything drawn from local data survives a dead tile server, over the
      // map's own surface1 background. Nothing here retries or caches.
      expect(find.byType(NumberedPinMarker), findsNWidgets(seedStops.length));
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .options
            .backgroundColor,
        AppColors.surface1,
      );

      final container = containerOf(tester, find.byType(ResultScreen));
      final notifier = container.read(itineraryNotifierProvider.notifier);
      await expandSheet(tester);

      notifier.setEditMode(true);
      await tester.pumpAndSettle();
      expect(container.read(itineraryNotifierProvider).editMode, isTrue);

      notifier.reorder(0, 2);
      await tester.pumpAndSettle();
      final reordered = container.read(itineraryNotifierProvider).order;
      expect(reordered.first, isNot(0));

      notifier.remove(reordered.first);
      await tester.pumpAndSettle();
      expect(
        container.read(itineraryNotifierProvider).order.length,
        seedStops.length - 1,
      );

      notifier.revertOne(0);
      await tester.pumpAndSettle();
      expect(container.read(itineraryNotifierProvider).order.first, 0);

      notifier.restoreRemoved();
      await tester.pumpAndSettle();
      expect(
        container.read(itineraryNotifierProvider).order.length,
        seedStops.length,
      );
      expect(find.byType(NumberedPinMarker), findsNWidgets(seedStops.length));
      expect(tester.takeException(), isNull);
    });
  });
}
