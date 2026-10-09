import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/tab_shell.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/map/tile_warmup.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/journey_scene.dart';

/// The first-run choice between route generation and free exploration.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key, this.onCreateRoute, this.onSkip});

  /// Allows the app shell owner to supply its route transition.
  final VoidCallback? onCreateRoute;

  /// Allows the app shell owner to supply its route transition.
  final VoidCallback? onSkip;

  Future<void> _createRoute(BuildContext context, WidgetRef ref) async {
    ref.read(onboardingNotifierProvider.notifier).reset();
    final callback = onCreateRoute;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context)
        .pushReplacement(placeholderRoute(AppRoute.onboarding));
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionNotifierProvider.notifier).setOnboardingDone(true);
    if (!context.mounted) return;
    final callback = onSkip;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'explore'),
        builder: (_) => const AppShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: const ValueKey('screen-welcome'),
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Invisible, non-interactive, and laid out under everything else: it
          // exists only so Explore's tiles are already in flutter_map's cache
          // by the time this screen is left.
          TileWarmup(
            key: const ValueKey('welcome-tile-warmup'),
            pois: ref.watch(poiProvider),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JourneyScene(),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome to Terra NT',
                            style: AppType.cardTitle.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "Answer a few quick questions and we'll build a route across the Territory for you — or skip straight to exploring on your own.",
                            style: AppType.bodySm.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            key: const ValueKey('welcome-create-route'),
                            fullWidth: true,
                            onPressed: () => _createRoute(context, ref),
                            child: Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text('Create My Route'),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            key: const ValueKey('welcome-skip'),
                            fullWidth: true,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => _skip(context, ref),
                            child: Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text('Skip for Now'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
