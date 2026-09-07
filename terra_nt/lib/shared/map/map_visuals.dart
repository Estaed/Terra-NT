import '../../core/theme/colors.dart';

/// Named visual values for the shared native map surfaces.
class MapVisuals {
  MapVisuals._();

  static const routeDotOpacity = 0.85;
  static const routeDotRingOpacity = 0.18;
  static const backdropRouteOpacity = 0.75;
  static const resultRouteOpacity = 0.85;

  static final routeDotColor = AppColors.primary.withValues(
    alpha: routeDotOpacity,
  );
  static final routeDotRingColor = AppColors.primary.withValues(
    alpha: routeDotRingOpacity,
  );
}
