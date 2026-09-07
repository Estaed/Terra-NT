import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_launch.dart';
import 'core/theme/app_theme.dart';

/// Terra NT — Northern Territory road-trip route planner.
///
/// Task-00 scaffold, Task-01's theme and Task-06's app-launch routing.
void main() {
  runApp(const ProviderScope(child: TerraNtApp()));
}

class TerraNtApp extends StatelessWidget {
  const TerraNtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terra NT',
      theme: AppTheme.dark,
      home: const AppLaunch(),
    );
  }
}
