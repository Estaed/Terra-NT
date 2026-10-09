import 'package:flutter/material.dart';

/// The app's complete set of destinations. Feature tasks replace the placeholder
/// body associated with their destination; they do not add routing.
enum AppRoute {
  login('Login'),
  welcome('Welcome'),
  onboarding('Onboarding'),
  loading('Loading'),
  explore('Explore'),
  result('Result'),
  saved('Saved Routes'),
  profile('Profile'),
  stopDetail('Stop detail'),
  account('Account'),
  language('Language');

  const AppRoute(this.label);

  final String label;
}

/// The intentionally minimal body for an unimplemented screen.
class AppPlaceholderScreen extends StatelessWidget {
  const AppPlaceholderScreen({super.key, required this.route});

  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('screen-${route.name}'),
      body: Center(child: Text(route.label)),
    );
  }
}

Route<void> placeholderRoute(AppRoute route) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: route.name),
    builder: (_) => AppPlaceholderScreen(route: route),
  );
}
