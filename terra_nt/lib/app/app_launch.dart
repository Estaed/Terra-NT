import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/colors.dart';
import '../data/models/session.dart';
import '../data/repositories/notifiers.dart';
import '../features/auth/login_screen.dart';
import 'routes.dart';
import 'screen_routes.dart';
import 'tab_shell.dart';

/// Selects the persisted launch destination without introducing another key.
class AppLaunch extends ConsumerStatefulWidget {
  const AppLaunch({super.key});

  @override
  ConsumerState<AppLaunch> createState() => _AppLaunchState();
}

class _AppLaunchState extends ConsumerState<AppLaunch> {
  late final Future<Session> _initialSession = _loadInitialSession();
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// The platform Back gesture reaches the root navigator, which holds only
  /// this widget, so without forwarding it the pre-onboarding stack never sees
  /// it and Android closes the app instead. Falling through to
  /// [SystemNavigator.pop] keeps that exit for the stack's own first route.
  Future<void> _handleSystemBack(bool didPop) async {
    if (didPop) return;
    final navigator = _navigatorKey.currentState;
    if (navigator != null && await navigator.maybePop()) return;
    await SystemNavigator.pop();
  }

  Future<Session> _loadInitialSession() async {
    await ref.read(sessionNotifierProvider.notifier).load();
    return ref.read(sessionNotifierProvider);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Session>(
      future: _initialSession,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: AppColors.canvas);
        }
        final session = snapshot.requireData;
        if (session.email == null) {
          // Reuses the same LoginScreen route and the app's single root
          // Navigator that Profile's Log Out already lands on -- no separate
          // pre-login stack. Welcome becomes the root even when Create Account
          // sits on top of Login (PRD V7).
          return LoginScreen(
            onAuthenticated: () => Navigator.of(context).pushAndRemoveUntil(
              rootScreenRoute(AppRoute.welcome),
              (route) => false,
            ),
          );
        }
        if (session.onboardingDone) {
          return const AppShell();
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (_) => rootScreenRoute(AppRoute.onboarding),
          ),
        );
      },
    );
  }
}
