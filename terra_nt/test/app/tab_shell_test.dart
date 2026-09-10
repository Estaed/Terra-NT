import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/app/routes.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
import 'package:terra_nt/features/auth/login_screen.dart';
import 'package:terra_nt/features/explore/explore_screen.dart';
import 'package:terra_nt/features/itinerary/result_screen.dart';
import 'package:terra_nt/features/itinerary/stop_detail/stop_detail_screen.dart';
import 'package:terra_nt/features/profile/account/account_screen.dart';
import 'package:terra_nt/features/profile/language/language_screen.dart';
import 'package:terra_nt/features/profile/profile_screen.dart';
import 'package:terra_nt/shared/widgets/app_icon.dart';

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this.session);

  final Session session;

  @override
  Session build() => session;
}

void main() {
  Future<void> pumpShell(WidgetTester tester, {required bool onboardingDone}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionNotifierProvider.overrideWith(
            () => _FixedSessionNotifier(
              Session(email: null, onboardingDone: onboardingDone),
            ),
          ),
        ],
        child: MaterialApp(
          key: ValueKey('test-app-$onboardingDone'),
          theme: AppTheme.dark,
          home: AppShell(key: ValueKey('app-shell-$onboardingDone')),
        ),
      ),
    );
  }

  AppShellState shell(WidgetTester tester) {
    return tester.state<AppShellState>(find.byType(AppShell));
  }

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
    await tester.pump();
    expect(find.byType(StopDetailScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    shell(tester).showAccount();
    await tester.pump();
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
    expect(body.bottom - card.bottom, 16);
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

  testWidgets('bottom nav has four correctly coloured tabs at 360px', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(360, 800);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpShell(tester, onboardingDone: true);
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
      expect(label.style!.color, AppColors.inkTertiary);
    }
    expect(tester.takeException(), isNull);
  });
}
