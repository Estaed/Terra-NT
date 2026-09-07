import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/notifiers.dart';
import 'routes.dart';
import 'widgets/bottom_nav.dart';

/// Stateful four-tab shell. Each tab owns a Navigator so an inactive tab retains
/// its stack in the [IndexedStack].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static AppShellState of(BuildContext context) {
    return context.findAncestorStateOfType<AppShellState>()!;
  }

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    BottomNav.tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final List<_TabNavigatorObserver> _observers;
  final List<int> _stackDepths = List.filled(BottomNav.tabCount, 1);
  var _selectedTab = 0;
  var _planAiDetailOpen = false;
  var _profileDetailOpen = false;

  @override
  void initState() {
    super.initState();
    _observers = List.generate(
      BottomNav.tabCount,
      (index) => _TabNavigatorObserver(
        onDepthChanged: (depth) {
          if (mounted && _stackDepths[index] != depth) {
            setState(() => _stackDepths[index] = depth);
          }
        },
      ),
    );
  }

  /// Lets feature bodies push the detail route without learning about tab keys.
  void showStopDetail() {
    if (!ref.read(sessionNotifierProvider).onboardingDone) {
      _openLogin();
      return;
    }
    _selectTab(BottomNav.planAiIndex);
    setState(() => _planAiDetailOpen = true);
    _navigatorKeys[BottomNav.planAiIndex].currentState!.push(
      placeholderRoute(AppRoute.stopDetail),
    );
  }

  /// Lets Profile own its destination body while the shell retains its stack.
  void showAccount() {
    _selectTab(BottomNav.profileIndex);
    setState(() => _profileDetailOpen = true);
    _navigatorKeys[BottomNav.profileIndex].currentState!.push(
      placeholderRoute(AppRoute.account),
    );
  }

  void showLanguage() {
    _selectTab(BottomNav.profileIndex);
    setState(() => _profileDetailOpen = true);
    _navigatorKeys[BottomNav.profileIndex].currentState!.push(
      placeholderRoute(AppRoute.language),
    );
  }

  /// Exposed for route owners and tests; ordinary users only select it by tapping.
  void selectTab(int index) {
    _selectTab(index);
  }

  void _selectTab(int index) {
    if (index == BottomNav.planAiIndex &&
        !ref.read(sessionNotifierProvider).onboardingDone) {
      _openLogin();
      return;
    }
    setState(() => _selectedTab = index);
  }

  void _openLogin() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(placeholderRoute(AppRoute.login));
  }

  bool get _showsBottomNav {
    if (_selectedTab == BottomNav.planAiIndex) {
      return !_planAiDetailOpen || _stackDepths[BottomNav.planAiIndex] <= 1;
    }
    if (_selectedTab == BottomNav.profileIndex) {
      return !_profileDetailOpen || _stackDepths[BottomNav.profileIndex] <= 1;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: List.generate(BottomNav.tabCount, _buildTabNavigator),
            ),
          ),
          if (_showsBottomNav)
            BottomNav(selectedIndex: _selectedTab, onSelected: _selectTab),
        ],
      ),
    );
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      observers: [_observers[index]],
      onGenerateRoute: (settings) => _routeForTab(index, settings),
    );
  }

  Route<void> _routeForTab(int index, RouteSettings settings) {
    final route = switch (index) {
      0 => AppRoute.explore,
      1 =>
        settings.name == AppRoute.stopDetail.name
            ? AppRoute.stopDetail
            : AppRoute.result,
      2 => AppRoute.saved,
      3 =>
        settings.name == AppRoute.account.name
            ? AppRoute.account
            : settings.name == AppRoute.language.name
            ? AppRoute.language
            : AppRoute.profile,
      _ => throw StateError('Unknown tab index: $index'),
    };
    return placeholderRoute(route);
  }
}

class _TabNavigatorObserver extends NavigatorObserver {
  _TabNavigatorObserver({required this.onDepthChanged});

  final ValueChanged<int> onDepthChanged;
  var _depth = 0;

  void _updateDepth(int nextDepth) {
    _depth = nextDepth;
    onDepthChanged(_depth);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateDepth(_depth + 1);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateDepth(_depth - 1);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateDepth(_depth - 1);
  }
}
