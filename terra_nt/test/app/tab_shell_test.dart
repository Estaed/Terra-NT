import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terra_nt/app/routes.dart';
import 'package:terra_nt/app/tab_shell.dart';
import 'package:terra_nt/core/theme/app_theme.dart';
import 'package:terra_nt/core/theme/colors.dart';
import 'package:terra_nt/data/models/session.dart';
import 'package:terra_nt/data/repositories/notifiers.dart';
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
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-stopDetail')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    shell(tester).showAccount();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    shell(tester).showLanguage();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-language')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);
  });

  testWidgets('Plan AI opens Login before onboarding and Result afterwards', (
    tester,
  ) async {
    await pumpShell(tester, onboardingDone: false);
    await tester.pump();
    shell(tester).selectTab(0);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpShell(tester, onboardingDone: true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-tab-1')));
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-result')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav')), findsOneWidget);
  });

  testWidgets('stop detail is refused before onboarding is done', (tester) async {
    // showStopDetail() carries its own guard, separate from the tab-tap guard in
    // _selectTab. Without this test that branch is never exercised, so inverting it
    // leaves every other test green.
    await pumpShell(tester, onboardingDone: false);
    await tester.pump();

    shell(tester).showStopDetail();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('screen-login')), findsOneWidget);
    // skipOffstage: false is the whole point. IndexedStack keeps every tab in the
    // tree, so a stopDetail pushed onto the inactive Plan AI stack is merely
    // offstage -- the default finder would report findsNothing and the assertion
    // would pass while the guard was broken.
    expect(
      find.byKey(const ValueKey('screen-stopDetail'), skipOffstage: false),
      findsNothing,
    );
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
      expect(find.byKey(const ValueKey('screen-profile')), findsOneWidget);
      shell(tester).selectTab(1);
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-stopDetail')), findsOneWidget);

      shell(tester).showAccount();
      await tester.pumpAndSettle();
      shell(tester).selectTab(0);
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-explore')), findsOneWidget);
      shell(tester).selectTab(3);
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-account')), findsOneWidget);
    },
  );

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
