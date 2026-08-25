import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Terra NT — Northern Territory road-trip route planner.
///
/// Task-00 scaffold only. Two things are deliberately missing and belong to
/// later tasks, so do not add them here:
///   - the theme and design tokens (Task-01 owns `core/theme/`)
///   - routing and the tab shell (Task-06 owns `app/`)
void main() {
  runApp(const ProviderScope(child: TerraNtApp()));
}

class TerraNtApp extends StatelessWidget {
  const TerraNtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Terra NT',
      home: Scaffold(
        body: Center(child: Text('Terra NT')),
      ),
    );
  }
}
