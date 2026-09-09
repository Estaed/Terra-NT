import 'colors.dart';

/// Named visual values measured from the three native map references.
class AppMapVisuals {
  AppMapVisuals._();

  static const routeDotOpacity = 0.85;
  static const routeDotRingOpacity = 0.18;
  static const backdropRouteOpacity = 0.75;
  static const resultRouteOpacity = 0.85;
  static const carShadowOpacity = 0.5;
  static const carShadowBlurOpacity = 0.35;
  static const carWindowOpacity = 0.75;

  static const backdropDashPattern = <double>[1, 7];
  static const resultDashPattern = <double>[1, 6];

  static final routeDotColor = AppColors.primary.withValues(
    alpha: routeDotOpacity,
  );
  static final routeDotRingColor = AppColors.primary.withValues(
    alpha: routeDotRingOpacity,
  );
  static final carShadowColor = AppColors.overlay.withValues(
    alpha: carShadowOpacity,
  );
  static final carShadowBlurColor = AppColors.overlay.withValues(
    alpha: carShadowBlurOpacity,
  );
  static final carWindowColor = AppColors.hairlineStrong.withValues(
    alpha: carWindowOpacity,
  );
}
