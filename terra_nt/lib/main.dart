import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_launch.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

/// Terra NT — Northern Territory road-trip route planner.
///
/// Task-00 scaffold, Task-01's theme, Task-06's app-launch routing and
/// Task-23's Firebase initialisation (phase 2, `docs/PRD.md` D12).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
