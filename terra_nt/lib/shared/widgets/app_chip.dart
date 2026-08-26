import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/typography.dart';
import 'app_icon.dart';

/// The selected/unselected colour triple from the prototype's `chipStyle(selected)`
/// (L912-916). Public so later tasks' option cards and segmented controls reuse the
/// exact triple with their own geometry instead of restating it.
class AppChipColors {
  const AppChipColors._(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color border;

  factory AppChipColors.resolve(bool selected) => selected
      ? const AppChipColors._(
          AppColors.surface2,
          AppColors.ink,
          AppColors.hairlineStrong,
        )
      : const AppChipColors._(
          AppColors.surface1,
          AppColors.inkSubtle,
          AppColors.hairline,
        );
}

/// The prototype's pill-form chip: onboarding options, segmented controls and the
/// edit toggle (`docs/PRD.md` §2, gap 3).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppChipColors.resolve(selected);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppMetrics.padChipX,
          vertical: AppMetrics.padChipY,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.border, width: AppElevation.hairlineWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: AppMetrics.iconSm, color: colors.foreground),
              const SizedBox(width: AppMetrics.gapChipIcon),
            ],
            Text(label, style: AppType.buttonApp.copyWith(color: colors.foreground)),
          ],
        ),
      ),
    );
  }
}
