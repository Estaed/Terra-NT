import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/notifiers.dart';
import 'routes.dart';
import 'tab_shell.dart';

/// Selects the persisted launch destination without introducing another key.
class AppLaunch extends ConsumerWidget {
  const AppLaunch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    if (session.onboardingDone) {
      return const AppShell();
    }
    return const AppPlaceholderScreen(route: AppRoute.onboarding);
  }
}
