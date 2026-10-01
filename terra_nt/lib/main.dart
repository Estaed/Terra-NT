import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_launch.dart';
import 'app/crash_reporting.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'shared/map/tile_cache.dart';

/// Terra NT — Northern Territory road-trip route planner.
///
/// Task-00 scaffold, Task-01's theme, Task-06's app-launch routing,
/// Task-23's Firebase initialisation (phase 2, `docs/PRD.md` D12) and
/// Task-29's Crashlytics wiring (`docs/PRD.md` D13).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeTileCache();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  installCrashReporting(
    recordFlutterFatalError: FirebaseCrashlytics.instance.recordFlutterFatalError,
    recordFatalError: (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
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
