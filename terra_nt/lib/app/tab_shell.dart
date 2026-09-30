import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/notifiers.dart';
import '../core/theme/motion.dart';
import '../features/explore/explore_screen.dart';
import '../features/itinerary/result_screen.dart';
import '../features/itinerary/stop_detail/stop_detail_screen.dart';
import '../features/profile/account/account_screen.dart';
import '../features/profile/language/language_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/saved/saved_routes_screen.dart';
import 'routes.dart';
import 'screen_routes.dart';
import 'widgets/bottom_nav.dart';

/// Stateful four-tab shell. Each tab owns a Navigator so an inactive tab retains
/// its stack in the [IndexedStack].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  final int initialTab;

  static AppShellState of(BuildContext context) {
    return context.findAncestorStateOfType<AppShellState>()!;
  }

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tabEntrance;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    BottomNav.tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final List<_TabNavigatorObserver> _observers;
  final List<HeroController> _heroControllers = List.generate(
    BottomNav.tabCount,
    (_) => HeroController(
      createRectTween: (begin, end) =>
          MaterialRectArcTween(begin: begin, end: end),
    ),
  );
  final List<int> _stackDepths = List.filled(BottomNav.tabCount, 1);
  final List<int> _tabHistory = [];
  late var _selectedTab = widget.initialTab;
  var _planAiDetailOpen = false;
  var _profileDetailOpen = false;

  @override
  void initState() {
    super.initState();
    _tabEntrance = AnimationController(
      vsync: this,
      duration: AppMotion.base,
      value: 1,
    );
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
  void showStopDetail({int originalIndex = 0}) {
    if (!ref.read(sessionNotifierProvider).onboardingDone) {
      _openLogin();
      return;
    }
    _selectTab(BottomNav.planAiIndex);
    setState(() => _planAiDetailOpen = true);
    final itinerary = ref.read(itineraryNotifierProvider).itinerary;
    _navigatorKeys[BottomNav.planAiIndex].currentState!.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: AppRoute.stopDetail.name),
        builder: (_) => StopDetailScreen(
          stop: itinerary.stops[originalIndex],
          originalIndex: originalIndex,
        ),
      ),
    );
  }

  /// Lets Profile own its destination body while the shell retains its stack.
  void showAccount() {
    _selectTab(BottomNav.profileIndex);
    setState(() => _profileDetailOpen = true);
    _navigatorKeys[BottomNav.profileIndex].currentState!.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: AppRoute.account.name),
        builder: (_) => const AccountScreen(),
      ),
    );
  }

  void showLanguage() {
    _selectTab(BottomNav.profileIndex);
    setState(() => _profileDetailOpen = true);
    _navigatorKeys[BottomNav.profileIndex].currentState!.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: AppRoute.language.name),
        builder: (_) => const LanguageScreen(),
      ),
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
    if (index == _selectedTab) return;
    // Explore is the journey's root. Back consumes visits without recording a
    // new one, while explicitly selecting Explore starts a fresh journey.
    if (index == 0) {
      _tabHistory.clear();
    } else {
      _tabHistory.add(_selectedTab);
    }
    _activateTab(index);
  }

  void _activateTab(int index) {
    setState(() => _selectedTab = index);
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabEntrance.value = 1;
    } else {
      _tabEntrance.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tabEntrance.dispose();
    for (final controller in _heroControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(rootScreenRoute(AppRoute.login));
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

  /// Routes the platform Back gesture into the visible tab's own Navigator.
  ///
  /// Without this the root Navigator handles it, so Back from Stop detail,
  /// Account or Language would leave the shell instead of returning to the tab
  /// root, and an inactive tab's stack would decide the outcome.
  ///
  /// `maybePop`, not `pop`: a tab route that guards its own Back — Explore
  /// closing the keyboard is the one that exists today — registers a
  /// [PopScope] the root Navigator never sees, and `pop` walks straight past
  /// it. At a tab root, retrace tab visits, falling back to Explore when the
  /// shell opened directly on another tab. Back at Explore belongs to Android.
  Future<void> _handleSystemBack(bool didPop) async {
    if (didPop) return;
    final tab = _selectedTab;
    final navigator = _navigatorKeys[tab].currentState;
    if (navigator != null && await navigator.maybePop()) return;
    if (!mounted || _selectedTab != tab) return;
    if (tab != 0) {
      _activateTab(_tabHistory.isEmpty ? 0 : _tabHistory.removeLast());
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
      child: Scaffold(
        // The tab Navigators stay mounted; their first-build entrances have
        // already played while hidden. Animate activation without replacing
        // that subtree, so detail stacks and scroll positions survive.
        body: FadeTransition(
          key: const ValueKey('tab-activation'),
          opacity: _tabEntrance.drive(CurveTween(curve: AppMotion.easeOut)),
          child: IndexedStack(
            index: _selectedTab,
            children: List.generate(BottomNav.tabCount, _buildTabNavigator),
          ),
        ),
        bottomNavigationBar: _showsBottomNav
            ? BottomNav(selectedIndex: _selectedTab, onSelected: _selectTab)
            : null,
      ),
    );
  }

  Widget _buildTabNavigator(int index) {
    // Each retained stack owns its flights; the root Navigator's controller
    // cannot observe pushes between Result and Stop detail inside a tab.
    return HeroControllerScope(
      controller: _heroControllers[index],
      child: Navigator(
        key: _navigatorKeys[index],
        observers: [_observers[index]],
        onGenerateRoute: (settings) => _routeForTab(index, settings),
      ),
    );
  }

  Route<void> _routeForTab(int index, RouteSettings settings) {
    final route = switch (index) {
      0 => const ExploreScreen(),
      1 => ResultScreen(
        onOpenSavedRoutes: () => selectTab(2),
        onOpenStop: (originalIndex) =>
            showStopDetail(originalIndex: originalIndex),
      ),
      2 => SavedRoutesScreen(
        onOpenRoute: (_) => selectTab(BottomNav.planAiIndex),
        onPlanAi: () => selectTab(BottomNav.planAiIndex),
      ),
      3 => ProfileScreen(
        onShowAccount: showAccount,
        onShowLanguage: showLanguage,
      ),
      _ => throw StateError('Unknown tab index: $index'),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => route);
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
