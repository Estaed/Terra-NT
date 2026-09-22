import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/typography.dart';

/// The stop dot on the decorative backdrop route.
///
/// A plain ink dot: the earlier primary dot carried a spread `BoxShadow` ring,
/// which is both a second shadow the design does not allow and a composited
/// layer per marker on a map that repaints as the car moves.
class RouteDotMarker extends StatelessWidget {
  const RouteDotMarker({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('route-dot-marker'),
    width: AppMetrics.mapRouteDotSize,
    height: AppMetrics.mapRouteDotSize,
    decoration: const BoxDecoration(
      color: AppColors.ink,
      shape: BoxShape.circle,
    ),
  );
}

class NumberedPinMarker extends StatelessWidget {
  final int number;

  const NumberedPinMarker({super.key, required this.number});

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('numbered-pin-$number'),
    width: AppMetrics.mapNumberedPinSize,
    height: AppMetrics.mapNumberedPinSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface2,
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.primary,
        width: AppMetrics.mapPinBorderWidth,
      ),
    ),
    child: Text(
      '$number',
      style: AppType.caption.copyWith(
        color: AppColors.ink,
        fontWeight: AppWeights.semibold,
      ),
    ),
  );
}

class PoiPinMarker extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;

  const PoiPinMarker({
    super.key,
    this.selected = false,
    this.onTap,
    required this.accent,
  });

  Color get backgroundColor => selected ? accent : AppColors.surface2;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        key: const ValueKey('poi-pin-marker'),
        width: AppMetrics.mapPoiPinSize,
        height: AppMetrics.mapPoiPinSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: AppMetrics.mapPinBorderWidth),
        ),
        child: selected
            ? null
            : Container(
                key: const ValueKey('poi-pin-marker-dot'),
                width: AppMetrics.tagDotSize,
                height: AppMetrics.tagDotSize,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
      ),
    ),
  );
}
