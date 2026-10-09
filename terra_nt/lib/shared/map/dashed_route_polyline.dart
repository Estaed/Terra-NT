import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/map_visuals.dart';
import '../../core/theme/metrics.dart';

class DashedRoutePolyline {
  final List<LatLng> points;
  final List<double> dashArray;
  final double opacity;

  const DashedRoutePolyline({
    required this.points,
    required this.dashArray,
    required this.opacity,
  });

  factory DashedRoutePolyline.backdrop({required List<LatLng> points}) =>
      DashedRoutePolyline(
        points: points,
        dashArray: AppMapVisuals.backdropDashPattern,
        opacity: AppMapVisuals.backdropRouteOpacity,
      );

  factory DashedRoutePolyline.result({required List<LatLng> points}) =>
      DashedRoutePolyline(
        points: points,
        dashArray: AppMapVisuals.resultDashPattern,
        opacity: AppMapVisuals.resultRouteOpacity,
      );

  Polyline toPolyline() => Polyline(
    points: points,
    strokeWidth: AppMetrics.mapPolylineWidth,
    color: AppColors.primary.withValues(alpha: opacity),
    pattern: StrokePattern.dashed(segments: dashArray),
    strokeCap: StrokeCap.round,
  );
}
