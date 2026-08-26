import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

/// Terra NT — Northern Territory road-trip route planner.
///
/// Task-00 scaffold, plus Task-01's theme. One thing is still deliberately missing
/// and belongs to a later task, so do not add it here:
///   - routing and the tab shell (Task-06 owns `app/`)
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
      home: const Scaffold(
        body: Center(child: Text('Terra NT')),
      ),
    );
  }
}
