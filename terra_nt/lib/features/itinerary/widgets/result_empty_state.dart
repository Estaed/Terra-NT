import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/journey_scene.dart';

/// Shown in place of the map and sheet when Plan AI has no route for this
/// session yet. A saved trip is a second starting point when one exists.
class ResultEmptyState extends StatelessWidget {
  const ResultEmptyState({
    super.key,
    required this.onPlanMyRoute,
    this.onOpenSavedRoutes,
  });

  final VoidCallback onPlanMyRoute;
  final VoidCallback? onOpenSavedRoutes;

  @override
  Widget build(BuildContext context) {
    // The tab shell keeps every tab built; keying on whether this one is shown
    // replays the entrance when the user arrives instead of while it is hidden.
    final shown = Visibility.of(context);
    return ColoredBox(
      color: AppColors.canvas,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              key: ValueKey('result-empty-shown-$shown'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JourneyScene(),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 1,
                  child: Text(
                    'No route yet',
                    textAlign: TextAlign.center,
                    style: AppType.cardTitle.copyWith(color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Entrance(
                  index: 2,
                  child: Text(
                    "Answer a few questions and we'll plan a route across the "
                    'Territory.',
                    textAlign: TextAlign.center,
                    style: AppType.bodySm.copyWith(color: AppColors.inkMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Entrance(
                  index: 3,
                  child: AppButton(
                    key: const ValueKey('result-empty-plan-my-route'),
                    fullWidth: true,
                    onPressed: onPlanMyRoute,
                    child: const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Plan My Route'),
                      ),
                    ),
                  ),
                ),
                if (onOpenSavedRoutes != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Entrance(
                    index: 4,
                    child: AppButton(
                      key: const ValueKey('result-empty-open-saved-routes'),
                      fullWidth: true,
                      variant: AppButtonVariant.secondary,
                      onPressed: onOpenSavedRoutes,
                      child: const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Open a saved route'),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
