import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/app/routes.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/core/theme/motion.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/auth_repository.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/data/seed/seed_data.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/features/itinerary/widgets/result_stop_list.dart';
import 'package:terra_nt/features/profile/account/account_screen.dart';
import 'package:terra_nt/features/profile/language/language_screen.dart';
import 'package:terra_nt/features/profile/profile_screen.dart';
import 'package:terra_nt/features/saved/saved_routes_screen.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';
import 'package:terra_nt/shared/widgets/placeholder_tile.dart';

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final Session session;

  @override
  Session build() => session;
}

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required bool onboardingDone,
    bool reduceMotion = false,
    int initialTab = 0,
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionNotifierProvider.overrideWith(
            () => _FixedSessionNotifier(
              Session(email: null, onboardingDone: onboardingDone),
            ),
          ),
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
        ],
        child: MaterialApp(
          key: ValueKey('test-app-$onboardingDone'),
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: AppShell(
            key: ValueKey('app-shell-$onboardingDone'),
            initialTab: initialTab,
          ),
        ),
      ),
    );
  }

  AppShellState shell(WidgetTester tester) {
    return tester.state<AppShellState>(find.byType(AppShell));
  }

  List<String> recordSystemPops(WidgetTester tester) {
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
    return popped;
  }

  testWidgets('Back from a saved route returns to Saved Routes, then Explore', (
    tester,
  ) async {
    final popped = recordSystemPops(tester);
    await pumpShell(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-2')));
    await tester.pumpAndSettle();
    final savedState = tester.state(find.byType(SavedRoutesScreen));

    await tester.tap(find.byKey(const ValueKey('saved-route-full-nt')));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SavedRoutesScreen), findsOneWidget);
    expect(tester.state(find.byType(SavedRoutesScreen)), same(savedState));
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

  testWidgets(
    'empty Plan opens the Saved tab and a saved route can be chosen',
    (tester) async {
      await pumpShell(tester, onboardingDone: true, initialTab: 1);
      await tester.pumpAndSettle();
      expect(find.text('No route yet'), findsOneWidget);
      final action = find.byKey(
        const ValueKey('result-empty-open-saved-routes'),
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(SavedRoutesScreen), findsOneWidget);
      expect(find.text('No route yet'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('saved-route-full-nt')));
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('result-map')), findsOneWidget);
      expect(find.text('No route yet'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile Back retraces tab visits, including repeated tabs', (
    tester,
  ) async {
    final popped = recordSystemPops(tester);
    await pumpShell(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    for (final index in [2, 1, 2, 3, 3]) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-tab-$index')));
      await tester.pumpAndSettle();
    }

    for (final screen in [
      SavedRoutesScreen,
      ResultScreen,
      SavedRoutesScreen,
      ExploreScreen,
    ]) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
      expect(popped, isEmpty);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, ['SystemNavigator.pop']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting Explore starts a fresh tab journey', (tester) async {
    final popped = recordSystemPops(tester);
    await pumpShell(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    for (final index in [2, 1, 0]) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-tab-$index')));
      await tester.pumpAndSettle();
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(popped, ['SystemNavigator.pop']);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-3')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, ['SystemNavigator.pop', 'SystemNavigator.pop']);
  });

  testWidgets('Back from an initial Result tab falls back to Explore', (
    tester,
  ) async {
    final popped = recordSystemPops(tester);
    await pumpShell(tester, onboardingDone: true, initialTab: 1);
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(popped, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, ['SystemNavigator.pop']);
  });

  testWidgets('Stop detail Back pops Result before returning to Saved Routes', (
    tester,
  ) async {
    final popped = recordSystemPops(tester);
    await pumpShell(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saved-route-full-nt')));
    await tester.pumpAndSettle();
    shell(tester).showStopDetail();
    await tester.pumpAndSettle();
    expect(find.byType(StopDetailScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byType(SavedRoutesScreen), findsNothing);
    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
    expect(popped, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SavedRoutesScreen), findsOneWidget);
    expect(popped, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back pops retained Language and Account before tab history', (
    tester,
  ) async {
    final popped = recordSystemPops(tester);
    await pumpShell(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    shell(tester).showAccount();
    await tester.pumpAndSettle();
    final accountState = tester.state(find.byType(AccountScreen));
    shell(tester).showLanguage();
    await tester.pumpAndSettle();
    shell(tester).selectTab(2);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(popped, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(tester.state(find.byType(AccountScreen)), same(accountState));
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(popped, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back restores the previous tab with its scroll position', (
    tester,
  ) async {
    final popped = recordSystemPops(tester);
    tester.view.physicalSize = const Size(360, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpShell(tester, onboardingDone: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-3')));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(ProfileScreen),
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(scrollable);
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pumpAndSettle();
    final offset = scrollState.position.pixels;
    expect(offset, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-2')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(tester.state<ScrollableState>(scrollable), same(scrollState));
    expect(scrollState.position.pixels, offset);
    expect(popped, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all placeholder destinations render', (tester) async {
    for (final route in AppRoute.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AppPlaceholderScreen(route: route),
        ),
      );
      expect(find.byKey(ValueKey('screen-${route.name}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('bottom nav appears only on the four tab roots', (tester) async {
    await pumpShell(tester, onboardingDone: true);
    await tester.pump();

    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
    for (final index in [0, 1, 2, 3]) {
      shell(tester).selectTab(index);
      await tester.pump();
      expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
    }

    shell(tester).showStopDetail();
    await tester.pumpAndSettle();
    expect(find.byType(StopDetailScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    shell(tester).showAccount();
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    shell(tester).showLanguage();
    await tester.pumpAndSettle();
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets('removes the tab body bottom inset only while nav is visible', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 640);
    view.devicePixelRatio = 1;
    view.padding = const FakeViewPadding(top: 24, bottom: 48);
    view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(view.reset);

    await pumpShell(tester, onboardingDone: true);
    await tester.pump();
    expect(
      MediaQuery.paddingOf(tester.element(find.byType(ExploreScreen))).bottom,
      0,
    );

    shell(tester).showAccount();
    await tester.pumpAndSettle();
    expect(
      MediaQuery.paddingOf(tester.element(find.byType(AccountScreen))).bottom,
      48,
    );
  });

  testWidgets('places the Explore card 16px above the tab body bottom', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 640);
    view.devicePixelRatio = 1;
    view.padding = const FakeViewPadding(top: 24, bottom: 48);
    view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(view.reset);

    await pumpShell(tester, onboardingDone: true);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExploreScreen)),
    );
    container.read(exploreNotifierProvider.notifier).selectPoi('darwin-wf');
    await tester.pump();

    final card = tester.getRect(find.byKey(const ValueKey('explore-poi-card')));
    final body = tester.getRect(find.byKey(const ValueKey('explore-screen')));
    expect(
      body.bottom - card.bottom +
          card.height *
              tester.widget<SlideTransition>(
                find.ancestor(
                  of: find.byKey(const ValueKey('explore-poi-card')),
                  matching: find.byType(SlideTransition),
                ).first,
              ).position.value.dy,
      16,
      reason: 'the resting inset excludes the temporary entrance slide',
    );
  });

  testWidgets(
    'a preloaded tab fades on activation without rebuilding its Navigator',
    (tester) async {
      await pumpShell(tester, onboardingDone: true);
      await tester.pumpAndSettle();
      final navigatorBefore = tester.state<NavigatorState>(
        find
            .descendant(
              of: find.byType(AppShell),
              matching: find.byType(Navigator, skipOffstage: false),
              skipOffstage: false,
            )
            .at(1),
      );
      shell(tester).selectTab(1);
      await tester.pump();
      double opacity() => tester
          .widget<FadeTransition>(find.byKey(const ValueKey('tab-activation')))
          .opacity
          .value;
      expect(opacity(), lessThan(1));
      await tester.pump(AppMotion.base ~/ 2);
      expect(opacity(), greaterThan(0));
      expect(opacity(), lessThan(1));
      await tester.pumpAndSettle();
      expect(opacity(), 1);
      expect(
        tester.state<NavigatorState>(
          find
              .descendant(
                of: find.byType(AppShell),
                matching: find.byType(Navigator, skipOffstage: false),
                skipOffstage: false,
              )
              .at(1),
        ),
        same(navigatorBefore),
      );
      shell(tester).selectTab(1);
      await tester.pump();
      expect(
        opacity(),
        1,
        reason: 're-tapping the active tab is not an arrival',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('reduced motion shows a newly selected tab immediately', (
    tester,
  ) async {
    await pumpShell(tester, onboardingDone: true, reduceMotion: true);
    await tester.pumpAndSettle();
    shell(tester).selectTab(1);
    await tester.pump();
    expect(
      tester
          .widget<FadeTransition>(find.byKey(const ValueKey('tab-activation')))
          .opacity
          .value,
      1,
    );
  });

  testWidgets('Plan AI opens Login before onboarding and Result afterwards', (
    tester,
  ) async {
    await pumpShell(tester, onboardingDone: false);
    await tester.pump();
    shell(tester).selectTab(0);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpShell(tester, onboardingDone: true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-1')));
    await tester.pump();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
  });

  testWidgets('stop detail is refused before onboarding is done', (
    tester,
  ) async {
    // showStopDetail() carries its own guard, separate from the tab-tap guard in
    // _selectTab. Without this test that branch is never exercised, so inverting it
    // leaves every other test green.
    await pumpShell(tester, onboardingDone: false);
    await tester.pump();

    shell(tester).showStopDetail();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoginScreen), findsOneWidget);
    // skipOffstage: false is the whole point. IndexedStack keeps every tab in the
    // tree, so a stopDetail pushed onto the inactive Plan AI stack is merely
    // offstage -- the default finder would report findsNothing and the assertion
    // would pass while the guard was broken.
    expect(find.byType(StopDetailScreen, skipOffstage: false), findsNothing);
  });

  testWidgets('Result row opens Stop detail through the Plan AI stack', (
    tester,
  ) async {
    await pumpShell(tester, onboardingDone: true);
    await tester.pump();
    shell(tester).selectTab(1);
    await tester.pump();
    ProviderScope.containerOf(tester.element(find.byType(ResultScreen)))
        .read(itineraryNotifierProvider.notifier)
        .openSavedRoute(seedSavedRoutes[0]);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('result-sheet-handle')),
      const Offset(0, -600),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('result-stop-row-0')));

    await tester.tap(find.byKey(const ValueKey('result-stop-row-0')));
    await tester.pumpAndSettle();

    expect(find.byType(StopDetailScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets(
    'the picture flies out and back through the retained Plan AI Navigator',
    (tester) async {
      tester.view.physicalSize = const Size(411, 914);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpShell(tester, onboardingDone: true, initialTab: 2);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('saved-route-full-nt')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('result-sheet-handle')),
        const Offset(0, -600),
        touchSlopY: 0,
      );
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('result-stop-row-0'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      final source = find.descendant(
        of: row,
        matching: find.byType(StopPicture),
      );
      final image = tester.widget<StopPicture>(source).image;
      final picture = find.byWidgetPredicate(
        (widget) => widget is PlaceholderTile && widget.image == image,
      );
      final cardRect = tester.getRect(picture);
      final haptics = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await tester.tap(row);
      await tester.pump();
      await tester.pump(AppMotion.fast);
      expect(picture, findsOneWidget, reason: 'one picture travels in the overlay');
      final outboundRect = tester.getRect(picture);
      expect(outboundRect.height, greaterThan(cardRect.height));
      expect(
        find.descendant(of: find.byType(StopDetailScreen), matching: picture),
        findsNothing,
        reason: 'the picture is in the tab overlay during the flight',
      );
      await tester.pumpAndSettle();
      final detailRect = tester.getRect(picture);
      expect(outboundRect.height, lessThan(detailRect.height));
      expect(
        find.descendant(of: find.byType(StopDetailScreen), matching: picture),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('stop-detail-back-button')));
      await tester.pump();
      await tester.pump(AppMotion.fast);
      expect(
        tester.getRect(picture).height,
        inExclusiveRange(cardRect.height, detailRect.height),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(picture), cardRect);
      expect(find.byType(ResultScreen), findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stop-detail-skip')));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResultScreen)),
      );
      expect(container.read(itineraryNotifierProvider).skipped, {0});
      expect(haptics, hasLength(1), reason: 'the retained list must not buzz too');
      expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the tab Navigator skips the picture flight with reduced motion',
    (tester) async {
      await pumpShell(
        tester,
        onboardingDone: true,
        reduceMotion: true,
        initialTab: 2,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('saved-route-full-nt')));
      await tester.pumpAndSettle();
      shell(tester).showStopDetail();
      await tester.pump();
      await tester.pump(AppMotion.fast);
      final detailPicture = find.descendant(
        of: find.byType(StopDetailScreen),
        matching: find.byType(PlaceholderTile),
      );
      expect(detailPicture, findsOneWidget);
      final mode = find.descendant(
        of: find.byType(StopDetailScreen),
        matching: find.byType(HeroMode),
      );
      expect(tester.widget<HeroMode>(mode).enabled, isFalse);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stop-detail-back-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving the shell mid-flight disposes the Hero controllers', (
    tester,
  ) async {
    await pumpShell(tester, onboardingDone: true, initialTab: 2);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saved-route-full-nt')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('result-sheet-handle')),
      const Offset(0, -600),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('result-stop-row-0'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pump();
    await tester.pump(AppMotion.fast);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'Plan AI and Profile retain their detail stacks across tab changes',
    (tester) async {
      await pumpShell(tester, onboardingDone: true);
      await tester.pump();

      shell(tester).showStopDetail();
      await tester.pumpAndSettle();
      shell(tester).selectTab(3);
      await tester.pump();
      expect(find.byType(ProfileScreen), findsOneWidget);
      shell(tester).selectTab(1);
      await tester.pump();
      expect(find.byType(StopDetailScreen), findsOneWidget);

      shell(tester).showAccount();
      await tester.pumpAndSettle();
      shell(tester).selectTab(0);
      await tester.pump();
      expect(find.byType(ExploreScreen), findsOneWidget);
      shell(tester).selectTab(3);
      await tester.pump();
      expect(find.byType(AccountScreen), findsOneWidget);
    },
  );

  testWidgets('system Back closes the Explore keyboard before leaving', (
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
    // Inside the shell, not standalone: Explore's own PopScope sits on the
    // tab's nested route, which the root Navigator never consults.
    await pumpShell(tester, onboardingDone: true);
    await tester.pump();

    final field = find.byKey(const ValueKey('explore-search-field'));
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isFalse);
    expect(popped, isEmpty);

    // With nothing left to handle, Back is Android's.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(popped, ['SystemNavigator.pop']);
  });

  testWidgets('bottom nav has four readable tabs at 360px and 2x text', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpShell(tester, onboardingDone: true, textScale: 2);
    await tester.pump();

    for (final label in ['Explore', 'Plan AI', 'Saved Routes', 'Profile']) {
      expect(
        find.byKey(
          ValueKey(
            'bottom-nav-label-${['Explore', 'Plan AI', 'Saved Routes', 'Profile'].indexOf(label)}',
          ),
        ),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('bottom-nav-tab-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-tab-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-tab-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-tab-3')), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-nav')),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('bottom-nav'))).height,
      greaterThan(64),
    );
    for (var index = 0; index < 4; index++) {
      final tab = find.byKey(ValueKey('bottom-nav-tab-$index'));
      expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
      final label = find.byKey(ValueKey('bottom-nav-label-$index'));
      expect(MediaQuery.textScalerOf(tester.element(label)).scale(12), 24);
    }

    expect(
      tester
          .widget<AppIcon>(find.byKey(const ValueKey('bottom-nav-icon-0')))
          .color,
      AppColors.ink,
    );
    final activeLabel = tester.widget<Text>(
      find.byKey(const ValueKey('bottom-nav-label-0')),
    );
    expect(activeLabel.style!.color, AppColors.ink);
    for (final index in [1, 2, 3]) {
      expect(
        tester
            .widget<AppIcon>(find.byKey(ValueKey('bottom-nav-icon-$index')))
            .color,
        AppColors.inkTertiary,
      );
      final label = tester.widget<Text>(
        find.byKey(ValueKey('bottom-nav-label-$index')),
      );
      expect(label.style!.color, AppColors.inkSubtle);
    }
    expect(tester.takeException(), isNull);
  });
}
