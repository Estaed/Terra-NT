import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/tab_shell.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/repositories/notifiers.dart';
import '../../shared/map/route_car_backdrop.dart';
import '../../shared/widgets/app_button.dart';

const _welcomeScrimAlpha = 0.42;
const _welcomeCardSidePadding = 28.0;
const _welcomeCardVerticalPadding = 24.0;

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
    Navigator.of(context).pushReplacement(placeholderRoute(AppRoute.onboarding));
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
          const Positioned.fill(child: RouteCarBackdrop.ambient()),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: AppColors.canvas.withValues(alpha: _welcomeScrimAlpha),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _welcomeCardSidePadding,
                    vertical: _welcomeCardVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.hairlineStrong,
                      width: AppElevation.hairlineWidth,
                    ),
                    boxShadow: AppElevation.shadowOverlay,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome to Terra NT',
                        style: AppType.cardTitle.copyWith(
                          color: AppColors.ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Answer a few quick questions and we'll build a route across the Territory for you — or skip straight to exploring on your own.",
                        style: AppType.bodySm.copyWith(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        key: const ValueKey('welcome-create-route'),
                        fullWidth: true,
                        onPressed: () => _createRoute(context, ref),
                        child: const Text('Create My Route'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        key: const ValueKey('welcome-skip'),
                        fullWidth: true,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _skip(context, ref),
                        child: const Text('Skip for Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
