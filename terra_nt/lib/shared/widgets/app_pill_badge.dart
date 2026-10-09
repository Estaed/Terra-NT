import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/typography.dart';

/// The "NT-specific" badge (L279, 296, 311, 328, 345) and the "Skipped" marker
/// (L463) — same geometry, different ink, so one widget with a colour parameter.
class AppPillBadge extends StatelessWidget {
  const AppPillBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.padBadgeX,
        vertical: AppMetrics.padBadgeY,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline, width: AppElevation.hairlineWidth),
      ),
      child: Text(
        label,
        style: AppType.captionApp.copyWith(color: color ?? AppColors.inkTertiary),
      ),
    );
  }
}
