import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/metrics.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/plan_entry.dart';

/// One stop's timed plan: a monospaced time column beside its activity.
///
/// Shared by Result's detailed stop row and Stop detail's plan block, which
/// render identical rows; each caller supplies the key it is found by.
class PlanEntryList extends StatelessWidget {
  const PlanEntryList({super.key, required this.entries});

  final List<PlanEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppMetrics.resultStopEditActionGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: AppMetrics.resultStopPlanTimeWidth,
                  child: Text(
                    entry.time,
                    style: AppType.captionApp.copyWith(
                      color: AppColors.inkTertiary,
                      fontFamily: AppFonts.mono,
                    ),
                  ),
                ),
                const SizedBox(width: AppMetrics.resultStopListGap),
                Expanded(
                  child: Text(
                    entry.activity,
                    style: AppType.bodyApp.copyWith(color: AppColors.inkMuted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
