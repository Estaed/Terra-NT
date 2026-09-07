import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/typography.dart';
import 'map_visuals.dart';

class RouteDotMarker extends StatelessWidget {
  const RouteDotMarker({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('route-dot-marker'),
    width: AppMetrics.mapRouteDotSize,
    height: AppMetrics.mapRouteDotSize,
    decoration: BoxDecoration(
      color: MapVisuals.routeDotColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: MapVisuals.routeDotRingColor,
          spreadRadius: AppMetrics.mapRouteDotRingWidth,
        ),
      ],
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

  const PoiPinMarker({
    super.key,
    this.selected = false,
    this.onTap,
  });

  Color get backgroundColor => selected ? AppColors.primary : AppColors.surface2;

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
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: AppMetrics.mapPinBorderWidth,
          ),
        ),
      ),
    ),
  );
}
