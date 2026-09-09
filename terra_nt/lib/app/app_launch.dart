import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/colors.dart';
import '../data/models/session.dart';
import '../data/repositories/notifiers.dart';
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
        if (snapshot.requireData.onboardingDone) {
          return const AppShell();
        }
        return Navigator(
          onGenerateRoute: (_) => rootScreenRoute(AppRoute.onboarding),
        );
      },
    );
  }
}
