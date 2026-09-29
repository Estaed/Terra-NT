import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../shared/widgets/entrance.dart';

/// Shown in place of the map and sheet when Plan AI has no route for this
/// session yet -- the Saved Routes empty-state pattern, reused verbatim.
///
/// Its four parts enter in turn whenever the tab is shown (`docs/PRD.md` D18).
class ResultEmptyState extends StatelessWidget {
  const ResultEmptyState({super.key, required this.onPlanMyRoute});

  final VoidCallback onPlanMyRoute;

  @override
  Widget build(BuildContext context) {
    // The tab shell keeps every tab built; keying on whether this one is shown
    // replays the entrance when the user arrives instead of while it is hidden.
    final shown = Visibility.of(context);
    return ColoredBox(
      color: AppColors.canvas,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppMetrics.savedRoutesEmptyPadX,
        ),
        child: Center(
          child: Column(
            key: ValueKey('result-empty-shown-$shown'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Entrance(
                child: AppIcon(
                  LucideIcons.sparkles,
                  key: ValueKey('result-empty-sparkles'),
                  size: AppMetrics.iconHuge,
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppMetrics.gapRowAvatar),
              Entrance(
                index: 1,
                child: Text(
                  'No route yet',
                  textAlign: TextAlign.center,
                  style: AppType.cardTitle.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(height: AppMetrics.gapRowAvatar),
              Entrance(
                index: 2,
                child: Text(
                  "Answer a few questions and we'll plan a route across the "
                  'Territory.',
                  textAlign: TextAlign.center,
                  style: AppType.bodySm.copyWith(color: AppColors.inkSubtle),
                ),
              ),
              const SizedBox(height: AppMetrics.gapRowAvatar),
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
            ],
          ),
        ),
      ),
    );
  }
}
