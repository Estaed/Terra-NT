import 'package:flutter/widgets.dart';

import '../../core/theme/metrics.dart';

/// Thin wrapper over [Icon] for the prototype's icon usages.
///
/// `flutter_lucide` ships its icons as a font, so outline-only, 2px round caps and
/// never-filled are inherent to the glyphs — nothing to configure here. `color: null`
/// inherits from the ambient [IconTheme], matching the CSS `currentColor` behaviour
/// the prototype relies on (e.g. `GripVertical` L454, `ArrowRight` L513).
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = AppMetrics.iconMd, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: size, color: color);
  }
}
