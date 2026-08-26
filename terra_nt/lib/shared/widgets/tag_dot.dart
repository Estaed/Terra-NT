import 'package:flutter/widgets.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/elevation.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/radius.dart';
import '../../core/theme/typography.dart';

/// A 5px coloured dot plus label, taking its colour as a parameter.
///
/// Imports the theme tokens only, never the pure-Dart utility layer: the tag-to-
/// colour mapping is Task-04's `tagColor()`, and callers resolve it and pass the
/// [Color] down.
class TagDot extends StatelessWidget {
  const TagDot({super.key, required this.color, required this.label, this.bordered = false});

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final dot = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppMetrics.tagDotSize,
          height: AppMetrics.tagDotSize,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
        const SizedBox(width: AppMetrics.gapTagDot),
        Text(label, style: AppType.captionApp.copyWith(color: AppColors.inkSubtle)),
      ],
    );

    if (!bordered) return dot;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.padTagX,
        vertical: AppMetrics.padTagY,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline, width: AppElevation.hairlineWidth),
      ),
      child: dot,
    );
  }
}
