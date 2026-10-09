import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/loading/loading_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/steps/onboarding_steps.dart';
import 'routes.dart';
import 'tab_shell.dart';

Route<void> rootScreenRoute(AppRoute route) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: route.name),
    builder: (context) => switch (route) {
      AppRoute.login => LoginScreen(
        onAuthenticated: () => _replace(context, AppRoute.welcome),
      ),
      AppRoute.welcome => WelcomeScreen(
        onCreateRoute: () => _replace(context, AppRoute.onboarding),
        onSkip: () => _replaceWithShell(context),
      ),
      AppRoute.onboarding => OnboardingScreen(
        stepBuilder: onboardingStepBuilder,
        onExitToWelcome: () => _replace(context, AppRoute.welcome),
        onComplete: () => _replace(context, AppRoute.loading),
      ),
      AppRoute.loading => LoadingScreen(
        onComplete: () => _replaceWithShell(context, initialTab: 1),
      ),
      _ => const AppShell(),
    },
  );
}

/// Leaves the tab shell for a fresh onboarding run ("Plan again").
///
/// The shell sits on the root navigator, so the replacement has to target that
/// navigator rather than the tab's own stack -- otherwise onboarding would be
/// pushed inside the Plan AI tab with the bottom nav still on top of it.
void replaceWithOnboarding(BuildContext context) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).pushReplacement(rootScreenRoute(AppRoute.onboarding));
}

void _replace(BuildContext context, AppRoute route) {
  Navigator.of(context).pushReplacement(rootScreenRoute(route));
}

void _replaceWithShell(BuildContext context, {int initialTab = 0}) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'shell'),
      builder: (_) => AppShell(initialTab: initialTab),
    ),
  );
}
