import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/metrics.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/typography.dart';
import '../widgets/app_icon.dart';

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
  final String? placeName;

  const NumberedPinMarker({super.key, required this.number, this.placeName});

  @override
  Widget build(BuildContext context) => Semantics(
    label: placeName == null ? 'Stop $number' : 'Stop $number: $placeName',
    button: true,
    excludeSemantics: true,
    child: Container(
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
    ),
  );
}

class PoiPinMarker extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;
  final String? tag;
  final String? placeName;

  const PoiPinMarker({
    super.key,
    this.selected = false,
    this.onTap,
    required this.accent,
    this.tag,
    this.placeName,
  });

  Color get backgroundColor => selected ? accent : AppColors.surface2;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: placeName,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? AppMotion.loadingPulseMaxScale : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.slow,
        curve: AppMotion.easeOut,
        child: Container(
          key: const ValueKey('poi-pin-marker'),
          width: AppMetrics.mapPoiPinSize,
          height: AppMetrics.mapPoiPinSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: accent,
              width: AppMetrics.mapPinBorderWidth,
            ),
          ),
          child: tag != null
              ? AppIcon(
                  switch (tag) {
                    'Nature' => LucideIcons.tree_pine,
                    'Culture' => LucideIcons.landmark,
                    'Adventure' => LucideIcons.mountain,
                    'Wildlife' => LucideIcons.paw_print,
                    'Relaxation' => LucideIcons.waves_horizontal,
                    _ => LucideIcons.map_pin,
                  },
                  size: AppMetrics.iconSm,
                  color: selected ? AppColors.surface1 : accent,
                )
              : selected
              ? null
              : Container(
                  key: const ValueKey('poi-pin-marker-dot'),
                  width: AppMetrics.tagDotSize,
                  height: AppMetrics.tagDotSize,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    ),
  );
}
